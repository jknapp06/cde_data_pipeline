# 10_process_upc.R
# Processes CDE Unduplicated Pupil Count (UPC) data (LEA and School levels)
# Applies SCOE charter rules and pins the results.

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

# Enforce character type for safe joining downstream
scoe_schools <- pin_read(local_board, "solano_schools_directory") |>
  filter(county_name == "Solano") |>
  select(
    county_code,
    district_code,
    school_code,
    scoe_reporting_district,
    scoe_reporting_school
  ) |>
  mutate(across(c(county_code, district_code, school_code), as.character))

# 3. Process UPC Data (Both LEA and School Levels) ---------------------------
message("Processing UPC data from Sheet 2 (LEA) and Sheet 3 (School)...")

ca_upc_wide <- pmap_dfr(upc_files, function(year, url, ...) {
  # Read sheets purely as data, without forcing aggregate levels yet
  df_lea <- tryCatch(
    {
      load_excel_from_cache(url, sheet = 2, start_row = 2)
    },
    error = function(e) return(NULL)
  )

  df_school <- tryCatch(
    {
      load_excel_from_cache(url, sheet = 3, start_row = 2)
    },
    error = function(e) return(NULL)
  )

  # Stack them together
  df <- bind_rows(df_lea, df_school)

  # If the file failed to load completely, skip
  if (nrow(df) == 0) {
    return(tibble())
  }

  df <- df |>
    mutate(reporting_year = year) |>
    normalize_cde_names()

  # Conditionally filter CALPADS certification if the column exists (2021+)
  cert_col <- names(df)[str_detect(names(df), "calpads_fall_1_cert")]

  if (length(cert_col) > 0) {
    cert_name <- cert_col[1]

    df <- df |>
      filter(.data[[cert_name]] == "Y") |>
      select(-all_of(cert_name))
  }

  df
}) |>
  mutate(
    # Safely and centrally derive aggregate level based on the school code
    aggregate_level = if_else(
      is.na(school_code) | school_code == "0000000",
      "D",
      "S"
    ),

    # Standardize empty school names for LEA-level rows
    school_name = if_else(
      aggregate_level == "D",
      "District Aggregate",
      school_name
    ),

    # Make charter_school perfectly match downstream expectations
    charter_school = case_when(
      aggregate_level == "D" ~ "All",
      str_detect(toupper(charter_school_y_n), "^Y") ~ "Yes",
      .default = "No"
    )
  ) |>
  select(-any_of("charter_school_y_n")) |>
  # CRITICAL: Deduplicate! This removes charters that appear on both Sheet 2 and Sheet 3
  distinct(
    reporting_year,
    county_code,
    district_code,
    school_code,
    .keep_all = TRUE
  )

# 4. Pivot to Long Format ----------------------------------------------------
message("Pivoting program counts...")

ca_upc_long <- ca_upc_wide |>
  pivot_longer(
    cols = any_of(c(
      "total_enrollment",
      "free_reduced_meal_program",
      "free_and_reduced_meal_program",
      "foster",
      "tribal_foster_youth",
      "homeless",
      "migrant_program",
      "direct_certification",
      "unduplicated_frpm_eligible_count",
      "english_learner_el",
      "calpads_unduplicated_pupil_count_upc"
    )),
    names_to = "program",
    values_to = "student_count"
  )

# 5. Apply SCOE Business Rules for Solano Subset -----------------------------
message("Applying SCOE business rules for Solano...")

solano_upc_long <- ca_upc_long |>
  filter(county_name == "Solano") |>
  # Join strictly on the 14-digit composite equivalent
  left_join(
    scoe_schools,
    by = join_by(county_code, district_code, school_code)
  ) |>
  mutate(
    district_name = coalesce(scoe_reporting_district, district_name),
    school_name = coalesce(scoe_reporting_school, school_name)
  ) |>
  select(-scoe_reporting_district, -scoe_reporting_school)

# 6. Pin the Results ---------------------------------------------------------
message("Pinning final datasets...")

pin_write(
  local_board,
  ca_upc_long,
  "ca_upc",
  type = "parquet",
  title = "Statewide UPC Data (LEA and School Levels)"
)
pin_write(
  local_board,
  solano_upc_long,
  "solano_upc",
  type = "parquet",
  title = "Solano UPC Data (SCOE Rules Applied)"
)

message("Success! UPC processing complete.")
