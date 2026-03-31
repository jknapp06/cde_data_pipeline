# 08_process_el.R
# Processes all CDE English Learner datasets (LTEL/ELAS, Basic EL, FEP, Reclass), 
# applies SCOE charter reporting rules for Solano, and pins the resulting datasets.

library(tidyverse)
library(janitor)
library(pins)
library(here)

# 1. Establish robust project paths and load helpers
source(here("R", "data-urls.R"))
source(here("R", "load-files.R"))
source(here("R", "clean.R"))

# 2. Connect to the local Pins board
local_board <- board_folder(here("data", "pins"))

scoe_schools <- pin_read(local_board, "solano_schools_directory") |>
  select(school_code, scoe_reporting_district, scoe_reporting_school) |>
  mutate(school_code = as.character(school_code))

# Helper function to apply SCOE rules
apply_scoe_rules <- function(df, scoe_schools_df) {
  df |>
    filter(county_name == "Solano") |>
    left_join(scoe_schools_df, by = "school_code") |>
    mutate(
      district_name = coalesce(scoe_reporting_district, district_name),
      school_name = coalesce(scoe_reporting_school, school_name)
    )
}

# 3. Process English Learner Data --------------------------------------------
message("Processing Comprehensive English Learner data pipelines...")

# -- A. LTEL / ELAS (The dataset driving your RMarkdown tables) --
ca_ltel <- imap_dfr(ltel_urls, \(url, year) {
  load_txt_from_cache(url, delim = "\t") |>
    mutate(reporting_year = year) |>
    normalize_cde_names(data_term = "fall") |>
    mutate(across(
      .cols = any_of(c("eo", "ifep", "el", "rfep", "tbd", "total_enrollment", 
                       "ltel", "ar", "el4", "el03y", "el45y", "el6_y", "total_ee")),
      .fns = ~ suppressWarnings(parse_number(as.character(.x)))
    ))
})
solano_ltel <- apply_scoe_rules(ca_ltel, scoe_schools)


# -- B. Basic EL by Language (Pivoted to match LTEL grade structures) --
ca_el <- imap_dfr(el_urls, \(url, year) {
  load_txt_from_cache(url, delim = "\t") |>
    mutate(reporting_year = year) |> 
    normalize_cde_names(data_term = "fall") |>
    # Pivot the wide GR_* columns into a standard 'grade' column
    pivot_longer(
      cols = matches("^gr_|^un$"),
      names_to = "grade",
      values_to = "students",
      values_drop_na = TRUE
    ) |>
    mutate(
      students = suppressWarnings(parse_number(as.character(students))),
      grade = str_remove(grade, "^gr_"),
      grade = str_to_upper(grade),
      # Add leading zeros to grades 1-9 to match LTEL "01", "02", etc.
      grade = if_else(str_length(grade) == 1, str_pad(grade, 2, pad = "0"), grade)
    )
})
solano_el <- apply_scoe_rules(ca_el, scoe_schools)


# -- C. FEP by Language (Pivoted to match LTEL grade structures) --
ca_fep <- imap_dfr(fep_urls, \(url, year) {
  load_txt_from_cache(url, delim = "\t") |>
    mutate(reporting_year = year) |> 
    normalize_cde_names(data_term = "fall") |>
    pivot_longer(
      cols = matches("^gr_|^un$"),
      names_to = "grade",
      values_to = "students",
      values_drop_na = TRUE
    ) |>
    mutate(
      students = suppressWarnings(parse_number(as.character(students))),
      grade = str_remove(grade, "^gr_"),
      grade = str_to_upper(grade),
      grade = if_else(str_length(grade) == 1, str_pad(grade, 2, pad = "0"), grade)
    )
})
solano_fep <- apply_scoe_rules(ca_fep, scoe_schools)


# -- D. Reclassification Data --
ca_reclass <- imap_dfr(reclass_urls, \(url, year) {
  load_txt_from_cache(url, delim = "\t") |>
    mutate(reporting_year = year) |>
    normalize_cde_names(data_term = "fall") |>
    mutate(across(
      .cols = any_of(c("el", "reclass", "total_enrollment")),
      .fns = ~ suppressWarnings(parse_number(as.character(.x)))
    ))
})
solano_reclass <- apply_scoe_rules(ca_reclass, scoe_schools)


# 4. Pin the Results ---------------------------------------------------------
message("Pinning statewide and Solano datasets...")

# LTEL
pin_write(local_board, ca_ltel, "ca_ltel", type = "parquet", title = "Statewide LTEL Data")
pin_write(local_board, solano_ltel, "solano_ltel", type = "parquet", title = "Solano LTEL Data (SCOE Rules)")

# Basic EL
pin_write(local_board, ca_el, "ca_english_learners", type = "parquet", title = "Statewide EL by Language")
pin_write(local_board, solano_el, "solano_english_learners", type = "parquet", title = "Solano EL by Language (SCOE Rules)")

# FEP
pin_write(local_board, ca_fep, "ca_fep", type = "parquet", title = "Statewide FEP by Language")
pin_write(local_board, solano_fep, "solano_fep", type = "parquet", title = "Solano FEP by Language (SCOE Rules)")

# Reclass
pin_write(local_board, ca_reclass, "ca_reclass", type = "parquet", title = "Statewide Reclass Data")
pin_write(local_board, solano_reclass, "solano_reclass", type = "parquet", title = "Solano Reclass Data (SCOE Rules)")

message("Comprehensive English Learner processing complete!")