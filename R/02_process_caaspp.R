# 02_process_caaspp.R
# Extracts, cleans, and pins Solano County & Statewide Aggregate CAASPP data

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
message("Loading Entities...")
entities <- load_zip_from_cache(
  caaspp_entities_url,
  caaspp_entities_txt,
  delim = "^"
) |>
  rename(reporting_year = test_year) |>
  select(-any_of("filler")) |>
  normalize_cde_names()

message("Loading Student Groups...")
caaspp_student_groups <- load_zip_from_cache(
  caaspp_student_groups_url,
  caaspp_student_groups_txt
) |>
  mutate(
    demographic_name = recode_values(
      demographic_id,
      "170" ~ "Ever - EL",
      "251" ~ "AR - TEL (At-Risk of becoming LTEL)",
      "252" ~ "Never - EL",
      default = demographic_name
    )
  ) |>
  # ADD THIS: Force exactly one row per ID to prevent join explosions!
  distinct(demographic_id_num, .keep_all = TRUE)

message("Loading and Aggressively Filtering CAASPP Data...")
# Iterate over the caaspp_files tribble from data-urls.R
solano_raw <- pmap_dfr(caaspp_files, function(year, url, txt_file) {
  file_delim <- if_else(year == 2019, ",", "^")

  load_zip_from_cache(url, txt_file, delim = file_delim) |>
    mutate(reporting_year = as.numeric(year)) |>
    normalize_cde_names() |>

    # THE LIFESAVER: Filter for Solano (48) and State (00, 0) BEFORE combining years
    filter(county_code %in% c("48", "00", "0")) |>

    select(-any_of(c("county_name", "district_name", "school_name")))
})

# 4. Clean and Combine --------------------------------------------------------
message("Merging and Cleaning Data...")

solano_caaspp_clean <- solano_raw |>
  left_join(
    select(entities, -c(reporting_year, academic_year)),
    by = join_by(cds, county_code, district_code, school_code, type_id)
  ) |>
  left_join(
    caaspp_student_groups,
    by = join_by(student_group_id == demographic_id_num)
  ) |>
  mutate(
    across(matches("percentage"), parse_number),
    across(matches("students"), parse_number),
    mean_scale_score = parse_number(mean_scale_score),
    test_id = as_factor(recode_values(test_id, 1 ~ "ELA/Literacy", 2 ~ "Math")),

    # Domain-specific naming rules
    district_name = case_when(
      county_code %in% c("0", "00") ~ "CA State Aggregate",
      county_code == "48" & district_code == "00000" ~ "County Aggregate",
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
  x = solano_caaspp_clean,
  name = "solano_caaspp_clean",
  type = "parquet",
  title = "Solano County & State CAASPP Data",
  description = "Cleaned CAASPP results filtered exclusively for Solano County LEAs and State Aggregates."
)

message("Success! Data updated and pinned.")
