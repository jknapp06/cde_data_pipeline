# 03_process_enrollment.R
# Processes Census, Cumulative, Dashboard, and UPC enrollment data,
# applies SCOE charter mapping rules, and pins the results.
# NOTE: Relies on URL vectors loaded from data-urls.R

library(tidyverse)
library(janitor)
library(vroom)
library(stringr)
library(openxlsx)
library(pins)
library(here)

# 1. Establish robust project paths and load helpers
source(here("R", "data-urls.R"))
source(here("R", "load-files.R"))
source(here("R", "clean.R"))

# 2. Connect to the local Pins board
local_board <- board_folder(here("data", "pins"))


# Load SCOE School Directory (Provides the SCOE business rules for charters)
scoe_schools <- pin_read(local_board, "solano_schools_directory") |>
  select(school_code, scoe_reporting_district, scoe_reporting_school) |>
  mutate(school_code = as.character(school_code))

reporting_category_mapping <- c(
  "AR_03" = "Children 0 to 3 years old",
  "AR_0418" = "Students 4 to 18 years old",
  "AR_1922" = "Continuing students 19 to 22 years old",
  "AR_2329" = "Non-traditional adult students 23 to 29 years old",
  "AR_3039" = "Non-traditional adult students 30 to 39 years old",
  "AR_4049" = "Non-traditional adult students 40 to 49 years old",
  "AR_50P" = "Non-traditional adult students 50+ years old",
  "ELAS_ADEL" = "Adult English Learner",
  "ELAS_EL" = "English Learner",
  "ELAS_EO" = "English Only",
  "ELAS_IFEP" = "Initial Fluent English Proficient",
  "ELAS_MISS" = "ELAS Missing",
  "ELAS_RFEP" = "Reclassified Fluent English Proficient",
  "ELAS_TBD" = "ELAS To Be Determined",
  "GN_F" = "Female",
  "GN_M" = "Male",
  "GN_X" = "Non-Binary",
  "GN_Z" = "Gender Missing",
  "RE_A" = "Asian",
  "RE_B" = "African American",
  "RE_D" = "Race/Ethnicity Not Reported",
  "RE_F" = "Filipino",
  "RE_H" = "Hispanic or Latino",
  "RE_I" = "American Indian or Alaska Native",
  "RE_P" = "Pacific Islander",
  "RE_T" = "Two or More Races",
  "RE_W" = "White",
  "SG_EL" = "English Learner",
  "SG_DS" = "Students with Disabilities",
  "SG_SD" = "Socioeconomically Disadvantaged",
  "SG_MG" = "Migrant Youth",
  "SG_FS" = "Foster Youth",
  "SG_HM" = "Homeless Youth",
  "TA" = "Total"
)

# 2. Census Day Enrollment ---------------------------------------------------
message("Processing Census Day Enrollment...")

# Process 2023 & 2024 Data (New CDE Format) using purrr::imap_dfr
census_new <- purrr::imap_dfr(census_urls, \(url, year_val) {
  load_txt_from_cache(url) |>
    mutate(
      county_name = smart_title_case(county_name),
      district_name = smart_title_case(district_name),
      school_name = smart_title_case(school_name),
      reporting_category_long = reporting_category_mapping[reporting_category],
      year = year_val # Assigns the year based on the vector name in data-urls.R
    ) |>
    filter(!is.na(reporting_category_long)) |>
    pivot_longer(
      cols = starts_with("gr_"),
      names_to = "grade",
      values_to = "enrollment",
      values_transform = as.numeric
    ) |>
    mutate(
      grade = str_remove(grade, "gr_") |>
        str_replace_all(c("tk" = "TK", "kn" = "K", "^0+" = ""))
    )
})

# Process 2017-2022 Data (Old CDE Multi-Year Format) using purrr::map_dfr
census_older <- purrr::map_dfr(old_census_urls, \(url) {
  load_txt_from_cache(url) |>
    mutate(
      county_name = smart_title_case(county),
      district_name = smart_title_case(district),
      school_name = smart_title_case(school),
      school_code = as.character(cds_code),

      # FIX: Multi-year files use 'academic_year', not 'year'
      year = str_sub(as.character(academic_year), 1, 4),

      # FIX: Multi-year files use 'race_ethnicity', not 'ethnic'
      reporting_category = case_when(
        !is.na(race_ethnicity) & race_ethnicity == 0 ~ "RE_D",
        !is.na(race_ethnicity) & race_ethnicity == 1 ~ "RE_I",
        !is.na(race_ethnicity) & race_ethnicity == 2 ~ "RE_A",
        !is.na(race_ethnicity) & race_ethnicity == 3 ~ "RE_P",
        !is.na(race_ethnicity) & race_ethnicity == 4 ~ "RE_F",
        !is.na(race_ethnicity) & race_ethnicity == 5 ~ "RE_H",
        !is.na(race_ethnicity) & race_ethnicity == 6 ~ "RE_B",
        !is.na(race_ethnicity) & race_ethnicity == 7 ~ "RE_W",
        !is.na(race_ethnicity) & race_ethnicity == 9 ~ "RE_T",
        !is.na(gender) & gender == "F" ~ "GN_F",
        !is.na(gender) & gender == "M" ~ "GN_M",
        !is.na(gender) & gender == "X" ~ "GN_X",
        !is.na(gender) & gender == "Z" ~ "GN_Z",
        TRUE ~ NA_character_
      ),
      reporting_category_long = reporting_category_mapping[reporting_category]
    ) |>
    # FIX: Multi-year files already use 'gr_kn' instead of 'kdgn'
    rename(
      gr_01 = gr_1,
      gr_02 = gr_2,
      gr_03 = gr_3,
      gr_04 = gr_4,
      gr_05 = gr_5,
      gr_06 = gr_6,
      gr_07 = gr_7,
      gr_08 = gr_8,
      gr_09 = gr_9
    ) |>
    pivot_longer(
      cols = starts_with("gr_"),
      names_to = "grade",
      values_to = "enrollment"
    ) |>
    mutate(
      grade = str_remove(grade, "gr_") |>
        str_replace_all(c("kn" = "K", "^0+" = ""))
    ) |>
    filter(enr_type == "C", !is.na(reporting_category_long)) |>
    mutate(enrollment = as.numeric(enrollment))
})

# Combine, Filter, Apply SCOE Rules
census_enrollment <- bind_rows(census_new, census_older) |>
  filter(str_to_title(county_name) == "Solano", enrollment > 0) |>
  left_join(scoe_schools, by = "school_code") |>
  mutate(
    district_name = coalesce(scoe_reporting_district, district_name),
    school_name = coalesce(scoe_reporting_school, school_name),
    year = factor(year, levels = as.character(2017:2024)),
    reporting_category_long = factor(reporting_category_long)
  ) |>
  select(
    county_code,
    county_name,
    district_code,
    district_name,
    school_code,
    school_name,
    year,
    reporting_category_long,
    grade,
    enrollment
  )

# Calculate totals and append
census_totals <- census_enrollment |>
  group_by(
    county_code,
    county_name,
    district_code,
    district_name,
    school_code,
    school_name,
    year,
    reporting_category_long
  ) |>
  summarise(enrollment = sum(enrollment, na.rm = TRUE), .groups = "drop") |>
  mutate(grade = "13") # 13 signifies Total

census_enrollment <- bind_rows(census_enrollment, census_totals) |> distinct()

pin_write(
  local_board,
  census_enrollment,
  "solano_census_enrollment",
  type = "parquet",
  description = "Longitudinal Census Day Enrollment with SCOE charter rules applied"
)

# 3. Cumulative Enrollment ---------------------------------------------------
message("Processing Cumulative Enrollment...")

cumulative_enrollment <- map_dfr(cumulative_urls, load_txt_from_cache) |>
  filter(county_code == "48") |>
  mutate(
    school_code = as.character(school_code),
    student_group_long = case_match(
      reporting_category,
      "RB" ~ "African American",
      "RI" ~ "American Indian or Alaska Native",
      "RA" ~ "Asian",
      "RF" ~ "Filipino",
      "RH" ~ "Hispanic or Latino",
      "RD" ~ "Not Reported",
      "RP" ~ "Pacific Islander",
      "RT" ~ "Two or More Races",
      "RW" ~ "White",
      "GM" ~ "Male",
      "GF" ~ "Female",
      "GX" ~ "Non-Binary Gender",
      "GZ" ~ "Missing Gender",
      "SE" ~ "English Learners",
      "SD" ~ "Students with Disabilities",
      "SS" ~ "Socioeconomically Disadvantaged",
      "SM" ~ "Migrant",
      "SF" ~ "Foster",
      "SH" ~ "Homeless",
      "TA" ~ "Total"
    )
  ) |>
  left_join(scoe_schools, by = "school_code") |>
  mutate(
    district_name = coalesce(scoe_reporting_district, district_name),
    school_name = coalesce(scoe_reporting_school, school_name)
  )

pin_write(
  local_board,
  cumulative_enrollment,
  "solano_cumulative_enrollment",
  type = "parquet",
  description = "Longitudinal Cumulative Enrollment with SCOE charter rules applied"
)


# 4. Dashboard Enrollment ----------------------------------------------------
message("Processing Dashboard Enrollment...")

dash_enrollment <- map_dfr(dash_urls, \(url) {
  df <- load_txt_from_cache(url)

  # Explicitly map known historical CDE column names to our standard snake_case names.
  # any_of() safely ignores the rename command if the old column name isn't in the file.
  df <- df |>
    rename(any_of(c(
      school_code = "cds",
      school_code = "school",
      r_type = "rtype",
      school_name = "schoolname",
      district_name = "districtname",
      county_name = "countyname",
      student_group = "studentgroup",
      total_enrollment = "totalenrollment",
      subgroup_total = "subgrouptotal",
      subgroup_total = "sub_group_total",
      reporting_year = "reportingyear"
    )))

  return(df)
}) |>
  filter(county_name == "Solano") |>
  mutate(
    school_code = as.character(school_code),
    student_group_long = case_match(
      student_group,
      "ALL" ~ "All students",
      "AA" ~ "Black/African American",
      "AI" ~ "American Indian or Alaska Native",
      "AS" ~ "Asian",
      "FI" ~ "Filipino",
      "HI" ~ "Hispanic",
      "PI" ~ "Pacific Islander",
      "WH" ~ "White",
      "MR" ~ "Multiple Races/Two or more",
      "EL" ~ "English Learner",
      "ELO" ~ "English Learners Only",
      "RFP" ~ "RFEPs Only",
      "EO" ~ "English Only",
      "SBA" ~ "Smarter Balanced Assessment",
      "CAA" ~ "CA Alternative Assessment",
      "SED" ~ "Socioeconomically Disadvantaged",
      "SWD" ~ "Students with Disabilities",
      "FOS" ~ "Foster Youth",
      "HOM" ~ "Homeless Youth"
    ),
    county_name = if_else(r_type == "X", "CA State Aggregate", county_name),
    district_name = if_else(
      r_type == "X",
      "State of California",
      district_name
    ),
    school_name = if_else(
      r_type == "D" & (is.na(school_name) | school_name == "CHECK"),
      "District Aggregate",
      school_name
    )
  ) |>
  left_join(scoe_schools, by = join_by(school_code)) |>
  mutate(
    district_name = coalesce(scoe_reporting_district, district_name),
    school_name = coalesce(scoe_reporting_school, school_name)
  )

pin_write(
  local_board,
  dash_enrollment,
  "solano_dash_enrollment",
  type = "parquet",
  description = "Longitudinal Dashboard Enrollment with SCOE charter rules applied"
)


# 5. Unduplicated Pupil Count (UPC) ------------------------------------------
message("Processing UPC Data...")

upc_enrollment <- map_dfr(upc_urls, \(url) {
  df <- load_excel_from_cache(url, sheet = 2, start_row = 2)

  # Explicitly map known historical CDE column names to standard snake_case names.
  # Add to this dictionary as you encounter older anomalies!
  df <- df |>
    rename(any_of(c(
      school_code = "cds_code",
      school_code = "cds",
      school_code = "school",
      county_name = "county",
      district_name = "district",
      school_name = "schoolname",
      english_learner = "english_learner",
      free_reduced_meal_program = "free_reduced_price_meals"
    )))

  return(df)
}) |>
  filter(str_to_title(county_name) == "Solano") |>
  mutate(
    school_code = as.character(school_code),
    school_name = if_else(
      is.na(school_name) | school_name == "N/A",
      "District Aggregate",
      school_name
    )
  ) |>
  left_join(scoe_schools, by = "school_code") |>
  mutate(
    district_name = coalesce(scoe_reporting_district, district_name),
    school_name = coalesce(scoe_reporting_school, school_name)
  ) |>
  # Using any_of() here prevents crashes if older years are missing newer columns (like tribal_foster_youth)
  pivot_longer(
    cols = any_of(c(
      "total_enrollment",
      "free_reduced_meal_program",
      "foster",
      "tribal_foster_youth",
      "homeless",
      "migrant_program",
      "direct_certification",
      "unduplicated_frpm_eligible_count",
      "english_learner",
      "calpads_unduplicated_pupil_count_upc"
    )),
    names_to = "program",
    values_to = "student_count"
  )

pin_write(
  local_board,
  upc_enrollment,
  "solano_upc_enrollment",
  type = "parquet",
  description = "Longitudinal UPC Enrollment with SCOE charter rules applied"
)

message("All enrollment processing complete!")
