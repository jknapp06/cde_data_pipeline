# 02_process_caaspp.R
# Extracts, cleans, and pins Solano County CAASPP data

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

# 3. Load & Cache Raw Data ----------------------------------------------------
# This uses the function we added to load-files.R. It will cache the massive
# zips locally and only extract the specific txt file we need into memory.

message("Loading Entities...")
entities25 <- load_zip_from_cache(
  entities_2025_url,
  "sb_ca2025entities_csv.txt"
) |>
  mutate(county_code = parse_double(county_code)) |>
  rename_with(~ str_to_lower(gsub(" ", "_", .x))) |>
  select(-c(filler, test_year))

message("Loading Student Groups...")
caaspp_student_groups <- load_zip_from_cache(
  caaspp_student_groups_url,
  "StudentGroups.txt"
) |>
  rename_with(~ str_to_lower(gsub(" ", "_", .x))) |>
  mutate(
    demographic_name = case_match(
      demographic_id,
      "170" ~ "Ever - EL",
      "251" ~ "AR - TEL (At-Risk of becoming LTEL)",
      "252" ~ "Never - EL",
      .default = demographic_name
    )
  )

message("Loading Solano CAASPP Data...")
solano_caaspp25 <- load_zip_from_cache(
  solano_caaspp_2025_url,
  "sb_ca2025_all_48_csv_v1.txt"
) |>
  mutate(county_name = "Solano")

solano_caaspp24 <- load_zip_from_cache(
  solano_caaspp_2024_url,
  "sb_ca2024_all_48_csv_v1.txt"
) |>
  mutate(county_name = "Solano")

solano_caaspp23 <- load_zip_from_cache(
  solano_caaspp_2023_url,
  "sb_ca2023_all_48_csv_v1.txt"
)

# 4. Clean and Combine --------------------------------------------------------
message("Merging and Cleaning...")

solano_caaspp_add_names <- solano_caaspp23 |>
  clean_names() |>
  left_join(
    entities25,
    by = join_by(county_code, district_code, school_code, type_id)
  )

solano_caaspp_big <- bind_rows(
  solano_caaspp25,
  solano_caaspp24,
  solano_caaspp_add_names
)

solano_caaspp <- solano_caaspp_big |>
  left_join(
    entities25,
    by = join_by(
      county_code,
      district_code,
      school_code,
      county_name,
      district_name,
      school_name,
      type_id
    )
  ) |>
  left_join(
    caaspp_student_groups,
    by = join_by(student_group_id == demographic_id_num)
  ) |>
  mutate(
    across(matches("percentage"), parse_number),
    across(matches("students"), parse_number),
    mean_scale_score = parse_number(mean_scale_score),
    test_id = as_factor(case_match(test_id, 1 ~ "ELA/Literacy", 2 ~ "Math")),
    test_year = as.integer(test_year),
    district_name = case_when(
      county_code == 0 ~ "CA State Aggregate",
      county_code == 48 & district_code == "00000" ~ "County Aggregate",
      .default = district_name
    ),
    school_name = if_else(school_code == "0000000", "Aggregate", school_name),
    students_enrolled = coalesce(total_students_enrolled, students_enrolled),
    students_tested = coalesce(total_students_tested, students_tested),
    students_with_scores = coalesce(
      total_students_tested_with_scores,
      students_with_scores
    )
  )

# 5. Pin to Local Board -------------------------------------------------------
message("Pinning final dataset to the local board...")

pin_write(
  board = local_board,
  x = solano_caaspp,
  name = "solano_caaspp_clean",
  type = "parquet",
  title = "Solano County CAASPP Data",
  description = "Cleaned CAASPP results for Solano County (Includes preview data and student groups)"
)

message("Success! CAASPP data updated and pinned.")
