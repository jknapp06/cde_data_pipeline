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

message("Processing CAST Data via purrr::pmap...")

# Iterate over the cast_files tribble row by row
solano_cast <- pmap_dfr(cast_files, function(year, url, txt_file) {
  # Note: If CAST uses a different delimiter for specific years like CAASPP did,
  # you can add the file_delim <- if_else(...) logic here.
  # Otherwise, specify the default CAST delimiter (usually "^" or ",").

  load_zip_from_cache(url, txt_file, delim = "^") |> # Change delim to "," if CAST uses commas
    mutate(reporting_year = as.numeric(year)) |>
    normalize_cde_names() |>

    # THE LIFESAVER: Filter for Solano (48) and State (00, 0) right away
    filter(county_code %in% c("48", "00", "0")) |>

    # Drop historical names to prevent join conflicts
    select(-any_of(c("county_name", "district_name", "school_name")))
}) |> 
  # THE MISSING LINK: Join the student groups after the loop finishes
  left_join(caaspp_student_groups, by = c("student_group_id" = "demographic_id_num")) |>
  
  # THE COALESCE TRICK: Combine the old and new column names
  mutate(
    students_enrolled = coalesce(total_students_enrolled, students_enrolled),
    students_tested = coalesce(total_students_tested, students_tested),
    students_with_scores = coalesce(
      total_students_tested_with_scores,
      students_with_scores
    )
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
# Map over the tibble, passing the url, txt_file, and has_header arguments
elpac_initial_list <- pmap(elpac_initial_files, function(year, url, txt_file, has_header) {
  # Default to TRUE if has_header is somehow missing
  header_flag <- if(is.null(has_header) || is.na(has_header)) TRUE else has_header
  
  load_zip_from_cache(
    url,
    txt_file,
    col_names = header_flag
  )
})

# Name the list elements with the years from the tibble so the 2020 fix works
names(elpac_initial_list) <- elpac_initial_files$year

# Safely fix 2020 headers using 2023 by referencing their names directly
if (
  "2020" %in% names(elpac_initial_list) && "2023" %in% names(elpac_initial_list)
) {
  names(elpac_initial_list[["2020"]]) <- names(elpac_initial_list[["2023"]])
}

solano_elpac_initial <- bind_rows(elpac_initial_list, .id = "reporting_year") |>
  mutate(type_id = coalesce(record_type, type_id)) |>
  normalize_cde_names(data_term = "spring") |>
  left_join(elpac_student_groups, by = "student_group_id") |>
  filter(county_code == "48")


# -- Summative ELPAC --
solano_elpac_summative <- pmap_dfr(elpac_summative_files, function(year, url, txt_file) {
  load_zip_from_cache(url, txt_file) |>
    mutate(reporting_year = as.numeric(year))
}) |>
  mutate(type_id = coalesce(record_type, type_id)) |>
  normalize_cde_names(data_term = "spring") |>
  left_join(elpac_student_groups, by = "student_group_id") |>
  filter(county_code %in% c("48", "00", "0")) |>
  mutate(
    district_name = case_when(
      county_code %in% c("00", "0") ~ "CA State Aggregate",
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
    description = "CAST data for Solano County (2021-2025)"
  )
  pin_write(
    local_board,
    solano_elpac_initial,
    "solano_elpac_initial",
    type = "parquet",
    description = "Initial ELPAC data for Solano County (2019-2025)"
  )
  pin_write(
    local_board,
    solano_elpac_summative,
    "solano_elpac_summative",
    type = "parquet",
    description = "Summative ELPAC data for Solano County & State Aggregates (2019-2025)"
  )

  message("Assessment processing complete!")
}