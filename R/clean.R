library(dplyr)
library(stringr)
library(tidyr)
library(purrr)
library(rlang)
library(readr) # Ensure readr is loaded for parse_number()

options(scipen = 999) # Prevents CDS codes from converting to scientific notation

# ==============================================================================
# 1. UNIVERSAL CDE NORMALIZER
# ==============================================================================
# normalizes core CDE identifiers, safely generates CDS codes, and handles years.
normalize_cde_names <- function(df, data_term = "spring") {
  # --- CASE: BASELINE CLEANING ---
  df_clean <- df |> janitor::clean_names()

  df_renamed <- df_clean |>
    rename(
      cds = any_of(c("cds_code", "cdscode", "county_district_school_code")),
      county_code = any_of(c("countycode", "county_cd")),
      county_name = any_of(c("countyname", "county")),
      district_code = any_of(c("districtcode", "district_cd")),
      district_name = any_of(c("districtname", "district")),
      school_code = any_of(c("schoolcode", "school_cd")),
      school_name = any_of(c("schoolname", "school")),
      academic_year = any_of(c("academicyear")),
      reporting_year = any_of(c(
        "reporting_year",
        "reportingyear",
        "year"
      )),
      student_group = any_of(c("studentgroup", "student_group")),
      total_enrollment = any_of(c("totalenrollment", "total_enrollment")),
      subgroup_total = any_of(c("subgrouptotal", "sub_group_total"))
    )

  # --- CASE: YEAR FORMAT STANDARDIZATION ---

  # 1. Establish a canonical 4-digit reporting_year first
  if (
    "academic_year" %in% names(df_renamed) &&
      !"reporting_year" %in% names(df_renamed)
  ) {
    if (data_term == "spring") {
      df_renamed <- df_renamed |>
        mutate(reporting_year = as.numeric(str_sub(academic_year, 1, 4)) + 1)
    } else {
      df_renamed <- df_renamed |>
        mutate(reporting_year = as.numeric(str_sub(academic_year, 1, 4)))
    }
  } else if ("reporting_year" %in% names(df_renamed)) {
    df_renamed <- df_renamed |>
      mutate(reporting_year = as.numeric(reporting_year))
  } else {
    warning(
      "Neither academic_year nor reporting_year found in data. You may need to add it manually."
    )
  }

  # 2. Forcefully rebuild academic_year from scratch to guarantee "YYYY-YY" format
  if ("reporting_year" %in% names(df_renamed)) {
    if (data_term == "spring") {
      df_renamed <- df_renamed |>
        mutate(
          academic_year = paste0(
            reporting_year - 1,
            "-",
            str_sub(as.character(reporting_year), 3, 4)
          )
        )
    } else {
      df_renamed <- df_renamed |>
        mutate(
          academic_year = paste0(
            reporting_year,
            "-",
            str_sub(as.character(reporting_year + 1), 3, 4)
          )
        )
    }
  }

  # Enforce canonical data types before touching codes
  df_renamed <- df_renamed |>
    mutate(
      across(
        any_of(c(
          "academic_year",
          "cds",
          "county_code",
          "district_code",
          "school_code"
        )),
        as.character
      ),
      # ADDED "test_year" to the numeric coercion list
      across(any_of(c("reporting_year", "test_year")), as.numeric) 
    )

  # --- CASE: BI-DIRECTIONAL CDS HANDLING ---
  # 1. Bottom-Up: Auto-complete missing CDS from sub-codes (e.g., Teacher Data)
  if (
    !"cds" %in% names(df_renamed) &&
      "county_code" %in% names(df_renamed) &&
      "district_code" %in% names(df_renamed)
  ) {
    df_renamed <- df_renamed |>
      mutate(
        cds = paste0(
          str_pad(coalesce(as.character(county_code), "00"), 2, pad = "0"),
          str_pad(coalesce(as.character(district_code), "00000"), 5, pad = "0"),
          str_pad(coalesce(as.character(school_code), "0000000"), 7, pad = "0")
        )
      )
  }

  # 2. Top-Down: Extract missing sub-codes from CDS (e.g., Dashboard Data)
  if ("cds" %in% names(df_renamed)) {
    if (!"county_code" %in% names(df_renamed)) {
      df_renamed$county_code <- NA_character_
    }
    if (!"district_code" %in% names(df_renamed)) {
      df_renamed$district_code <- NA_character_
    }
    if (!"school_code" %in% names(df_renamed)) {
      df_renamed$school_code <- NA_character_
    }

    df_renamed <- df_renamed |>
      mutate(
        county_code = coalesce(county_code, str_sub(cds, 1, 2)),
        district_code = coalesce(district_code, str_sub(cds, 3, 7)),
        school_code = coalesce(school_code, str_sub(cds, 8, 14))
      )
  }

  # --- CASE: ENTITY NAME FORMATTING ---
  name_cols <- intersect(
    names(df_renamed),
    c("county_name", "district_name", "school_name")
  )
  if (length(name_cols) > 0) {
    df_renamed <- df_renamed |>
      mutate(across(all_of(name_cols), smart_title_case))
  }

  # Ensure standalone code columns always retain leading zeros
  # (Ignoring NAs so they don't become the string "NA")
  df_renamed <- df_renamed |>
    mutate(
      county_code = if_else(
        !is.na(county_code),
        str_pad(county_code, 2, "left", "0"),
        NA_character_
      ),
      district_code = if_else(
        !is.na(district_code),
        str_pad(district_code, 5, "left", "0"),
        NA_character_
      ),
      school_code = if_else(
        !is.na(school_code),
        str_pad(school_code, 7, "left", "0"),
        NA_character_
      )
    )

  return(df_renamed)
}


# ==============================================================================
# 2. SPECIFIC DATA NORMALIZERS
# ==============================================================================

# --- CASE: ASSISTANCE DATA ---
normalize_assistance <- function(raw_list) {
  if (!is.list(raw_list)) {
    stop("Input must be a list of data frames")
  }
  message("Normalizing assistance data from ", length(raw_list), " files")

  process_assistance <- function(df, file_index) {
    if (!is.data.frame(df)) {
      warning("Item ", file_index, " is not a data frame. Skipping.")
      return(NULL)
    }

    df <- df |> janitor::clean_names()
    df_names <- names(df)
    assistance_year <- NA_integer_
    assistance_variable_name <- NA_character_

    year_checks <- list(
      "assistance_status2025" = 2025,
      "assistance_status2024" = 2024,
      "assistance_status2023" = 2023,
      "assistance_status2022" = 2022,
      "assistance_status2019" = 2019,
      "assistance_status2018" = 2018,
      "assistance_status" = 2017
    )

    charter <- any(c("chartername", "charter_name") %in% df_names)

    for (col_name in names(year_checks)) {
      if (col_name %in% df_names) {
        assistance_year <- year_checks[[col_name]]
        assistance_variable_name <- if_else(
          assistance_year == 2017,
          "assistance_status",
          paste0("assistance_status", assistance_year)
        )
        break
      }
    }

    if (is.na(assistance_year)) {
      stop("Could not determine assistance year for file ", file_index)
    }

    tryCatch(
      {
        slim_df <- df |>
          mutate(
            reporting_year = assistance_year,
            assistance_status = if (assistance_variable_name %in% names(df)) {
              .data[[assistance_variable_name]]
            } else {
              NA_character_
            },
            charter_flag = if_else(charter, "Y", NA_character_)
          ) |>
          rename(cds = any_of(c("cds", "cds_code", "cdscode"))) |>
          select(
            cds,
            charter_flag,
            reporting_year,
            assistance_status,
            ends_with("priorities"),
            ends_with("current"),
            ends_with("prior"),
            starts_with("ec")
          )

        current_patterns <- c(
          "a_acurrent",
          "a_icurrent",
          "a_scurrent",
          "e_lcurrent",
          "f_icurrent",
          "fo_scurrent",
          "h_icurrent",
          "ho_mcurrent",
          "se_dcurrent",
          "sw_dcurrent",
          "to_mcurrent",
          "w_hcurrent"
        )
        prior_patterns <- c(
          "a_aprior",
          "a_iprior",
          "a_sprior",
          "e_lprior",
          "f_iprior",
          "fo_sprior",
          "h_iprior",
          "ho_mprior",
          "se_dprior",
          "sw_dprior",
          "to_mprior",
          "w_hprior"
        )

        if ("lte_lcurrent" %in% names(slim_df)) {
          current_patterns <- c(current_patterns, "lte_lcurrent")
        }
        if ("lte_lprior" %in% names(slim_df)) {
          prior_patterns <- c(prior_patterns, "lte_lprior")
        }

        cols_to_pivot <- c(current_patterns, prior_patterns)
        cols_to_pivot <- cols_to_pivot[cols_to_pivot %in% names(slim_df)]

        if (charter) {
          long_df <- slim_df |>
            pivot_longer(
              cols = all_of(cols_to_pivot),
              names_to = c("student_group", "current_prior"),
              names_pattern = "(.+)(current|prior)",
              values_to = "assistance"
            ) |>
            pivot_wider(
              names_from = current_prior,
              values_from = assistance,
              names_prefix = "assistance_"
            )
        } else {
          long_df <- slim_df |>
            pivot_longer(
              cols = ends_with("priorities"),
              names_to = "student_group",
              values_to = "assistance",
              names_pattern = "(.*)priorities"
            )
        }

        processed_df <- long_df |>
          mutate(
            student_group = if_else(
              student_group == "tom",
              "MR",
              str_to_upper(str_remove_all(student_group, "_"))
            )
          )

        if (!"cds" %in% names(processed_df)) {
          warning("File ", file_index, " is missing 'cds' column")
        }

        return(processed_df)
      },
      error = function(e) {
        warning("Error processing file ", file_index, ": ", e$message)
        return(NULL)
      }
    )
  }

  processed_files <- keep(
    map2(raw_list, seq_along(raw_list), process_assistance),
    Negate(is.null)
  )
  if (length(processed_files) == 0) {
    stop("No files could be processed")
  }

  result <- bind_rows(processed_files) |> normalize_cde_names()
  return(result)
}

# --- CASE: ESSA DATA ---
normalize_essa <- function(raw_list) {
  essa_all <- bind_rows(raw_list) |> normalize_cde_names()
  status_cols <- grep("^assistance_status", names(essa_all), value = TRUE)
  grp_cols <- c(
    "aa",
    "ai",
    "as",
    "el",
    "fi",
    "fos",
    "hi",
    "hom",
    "pi",
    "sed",
    "swd",
    "tom",
    "wh"
  )

  essa_all |>
    rename(
      csi_years = any_of(c("cs_iyears", "csi_years")),
      atsi_years = any_of(c("ats_iyears", "atsi_years"))
    ) |>
    mutate(
      essa_status = coalesce(!!!syms(status_cols)),
      # Silently convert "N/A" to NA, parse the number, and fill with 0
      csi_years = coalesce(parse_number(na_if(csi_years, "N/A")), 0),
      atsi_years = coalesce(parse_number(na_if(atsi_years, "N/A")), 0)
    ) |>
    pivot_longer(
      cols = any_of(grp_cols),
      names_to = "student_group",
      values_to = "atsi_support"
    ) |>
    mutate(
      student_group = if_else(
        student_group == "tom",
        "MR",
        str_to_upper(student_group)
      )
    )
}

# --- CASE: TEACHER ASSIGNMENTS ---
# Reduced to a single call since normalize_cde_names now handles bottom-up CDS construction
normalize_teacher_assignments <- function(df) {
  df |> normalize_cde_names()
}


# ==============================================================================
# 3. HELPER FUNCTIONS & LOOKUPS
# ==============================================================================

# compute_priority4_summary: computes priority 4 CAASPP/ELPI eligibility
compute_priority4_summary <- function(df) {
  filtered_df <- df |> filter(priority == 4, priority_eligible == TRUE)

  filtered_df |>
    mutate(
      color = dplyr::case_when(
        reporting_year == 2022 ~ statuslevel,
        reporting_year == 2024 & indicator == "science" ~ currstatus,
        .default = color
      )
    ) |>
    select(reporting_year, cds, student_group_long, indicator, color) |>
    pivot_wider(names_from = indicator, values_from = color) |>
    mutate(
      caaspp_eligible = (ELA %in% c(1, 2) & Math %in% c(1, 2)) &
        !(is.na(ELA) | is.na(Math)),
      elpi_eligible = ELPI == 1 |
        (student_group_long == "Long-Term English Learner" & ELPI == 2)
    )
}

priority_eligibility_lookup <- tibble::tribble(
  ~assistance , ~priorities   ,
  "A"         , c(4, 5, 6)    ,
  "B"         , c(4, 5)       ,
  "C"         , c(5, 6)       ,
  "D"         , c(4, 6)       ,
  "E"         , c(4, 8)       ,
  "F"         , c(5, 8)       ,
  "G"         , c(6, 8)       ,
  "H"         , c(4, 5, 8)    ,
  "I"         , c(4, 6, 8)    ,
  "J"         , c(5, 6, 8)    ,
  "K"         , c(4, 5, 6, 8)
)

smart_title_case <- function(text) {
  titled <- str_to_title(text)

  lower_words <- c(
    "a",
    "an",
    "and",
    "as",
    "at",
    "but",
    "by",
    "for",
    "from",
    "in",
    "into",
    "near",
    "nor",
    "of",
    "on",
    "onto",
    "or",
    "the",
    "to",
    "with"
  )
  upper_words <- c(
    "coe",
    "rcd",
    "jpa",
    "roi",
    "usd",
    "esd",
    "cusd",
    "vusd",
    "fusd",
    "jfkld",
    "ca",
    "usa",
    "fsusd",
    "bhs",
    "tusd",
    "rti",
    "mtss"
  )

  lower_replacements <- setNames(
    paste0(" ", lower_words, " "),
    paste0("\\s", str_to_title(lower_words), "\\s")
  )
  upper_replacements <- setNames(
    toupper(upper_words),
    paste0("\\b", str_to_title(upper_words), "\\b")
  )

  titled |>
    str_replace_all(lower_replacements) |>
    str_replace_all(upper_replacements) |>
    str_replace_all("'S\\b", "'s")
}
