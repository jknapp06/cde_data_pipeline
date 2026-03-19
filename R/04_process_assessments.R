# 04_process_assessments.R
# Downloads, caches, cleans, and pins CAST and ELPAC datasets

library(tidyverse)
library(janitor)
library(pins)
library(here)

# 1. Establish robust project paths and load helpers -----------------------
source(here("R", "data-urls.R"))
source(here("R", "load-files.R"))
source(here("R", "clean.R"))

# Connect to the local Pins board
local_board <- board_folder(here("data", "pins"))

# 2. Process CAST ------------------------------------------------------------
message("Processing CAST Data...")

caaspp_student_groups <- load_zip_from_cache(
  caaspp_student_groups_url,
  "StudentGroups.txt"
) |>
  mutate(
    demographic_name = case_match(
      demographic_id_num,
      170 ~ "Ever - EL",
      251 ~ "AR - TEL (At-Risk of becoming LTEL)",
      252 ~ "Never - EL",
      .default = demographic_name
    )
  )

# Use imap_dfr to map over the list of URLs and their names (years)
solano_cast <- imap_dfr(cast_urls, \(url, year) {
  inner_file <- paste0(
    "cast_ca",
    year,
    "_all_csv_v",
    if_else(year == "2021", "2", "1"),
    ".txt"
  )
  load_zip_from_cache(url, inner_file)
}) |>
  filter(county_code == "48") |>
  left_join(
    caaspp_student_groups,
    by = join_by(student_group_id == demographic_id_num)
  )

# 3. Process ELPAC -----------------------------------------------------------
message("Processing ELPAC Data...")

elpac_student_groups <- load_zip_from_cache(
  elpac_student_groups_url,
  "StudentGroups.txt"
) |>
  mutate(
    student_group_name = case_match(
      as.character(student_group_id),
      "160" ~ "All English learners - (All ELs)",
      "248" ~ "EL - less than 1 year in program",
      "242" ~ "EL - 1 year in program",
      "243" ~ "EL - 2 years in program",
      "244" ~ "EL - 3 years in program",
      "245" ~ "EL - 4 years in program",
      "246" ~ "EL - 5 years in program",
      "247" ~ "EL - 6+ years in program",
      "251" ~ "AR - LTEL (At-Risk of becoming LTEL)",
      .default = student_group_name
    )
  )

# -- Initial ELPAC --
# Using imap (returns a named list based on the names in elpac_initial_urls)
elpac_initial_list <- imap(elpac_initial_urls, \(url, year) {
  inner_file <- paste0("ia_elpac", year, "_all_csv_v1.txt")
  has_header <- if_else(year == "2020", FALSE, TRUE)

  load_zip_from_cache(
    url,
    inner_file,
    col_names = has_header
  )
})

# Safely fix 2020 headers using 2023 by referencing their names directly
if (
  "2020" %in% names(elpac_initial_list) && "2023" %in% names(elpac_initial_list)
) {
  names(elpac_initial_list[["2020"]]) <- names(elpac_initial_list[["2023"]])
}

solano_elpac_initial <- bind_rows(elpac_initial_list) |>
  mutate(type_id = coalesce(record_type, type_id)) |>
  left_join(elpac_student_groups, by = "student_group_id") |>
  filter(county_code == "48")

# -- Summative ELPAC --
solano_elpac_summative <- imap_dfr(elpac_summative_urls, \(url, year) {
  inner_file <- paste0(
    "sa_elpac",
    year,
    "_all_csv_v",
    if_else(year == "2019", "2", "1"),
    ".txt"
  )
  load_zip_from_cache(url, inner_file)
}) |>
  mutate(type_id = coalesce(record_type, type_id)) |>
  left_join(elpac_student_groups, by = "student_group_id") |>
  filter(county_code %in% c("48", "00")) |>
  mutate(
    district_name = case_when(
      county_code == "00" ~ "CA State Aggregate",
      county_code == "48" & district_code == "00000" ~ "County Aggregate",
      .default = district_name
    ),
    school_name = if_else(school_code == "0000000", "Aggregate", school_name)
  )

# 4. Pin to Local Board ------------------------------------------------------
if (exists("local_board")) {
  message("Pinning to local board...")
  pin_write(
    local_board,
    solano_cast,
    "solano_cast",
    type = "parquet",
    description = "CAST data for Solano County (2021-2024)"
  )
  pin_write(
    local_board,
    solano_elpac_initial,
    "solano_elpac_initial",
    type = "parquet",
    description = "Initial ELPAC data for Solano County (2019-2024)"
  )
  pin_write(
    local_board,
    solano_elpac_summative,
    "solano_elpac_summative",
    type = "parquet",
    description = "Summative ELPAC data for Solano County & State Aggregates (2019-2024)"
  )

  message("Assessment processing complete!")
}
