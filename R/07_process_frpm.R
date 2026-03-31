# 07_process_frpm.R
# Processes CDE Free and Reduced Price Meals (FRPM) data, applies SCOE
# charter reporting rules for Solano, and pins the resulting datasets.

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
  select(school_code, scoe_reporting_district, scoe_reporting_school) |>
  mutate(school_code = as.character(school_code))

# 3. Process FRPM Data -------------------------------------------------------
message("Processing FRPM data...")

# imap_dfr automatically passes the list item (url) and its name (year)
ca_frpm <- imap_dfr(frpm_urls, \(url, year) {
  # Using our caching helper. start_row = 2 replaces rio's skip = 1
  df <- load_excel_from_cache(url, sheet = 2, start_row = 2) |>
    mutate(reporting_year = year) |> # Inject year for the normalizer
    normalize_cde_names(data_term = "fall") # FRPM is Fall Census data

  # Conditionally filter CALPADS certification if the column exists (2021+)
  if ("calpads_fall_1_certification_status" %in% names(df)) {
    df <- df |> filter(calpads_fall_1_certification_status == "Y")
  }

  df |> select(-contains("calpads"))
})

# 4. Apply SCOE Business Rules for Solano Subset -----------------------------
solano_frpm <- ca_frpm |>
  filter(county_name == "Solano") |>
  left_join(scoe_schools, by = "school_code") |>
  mutate(
    district_name = coalesce(scoe_reporting_district, district_name),
    school_name = coalesce(scoe_reporting_school, school_name)
  )

# 5. Pin the Results ---------------------------------------------------------
pin_write(
  local_board,
  ca_frpm,
  "ca_frpm",
  type = "parquet",
  title = "Statewide FRPM Data"
)
pin_write(
  local_board,
  solano_frpm,
  "solano_frpm",
  type = "parquet",
  title = "Solano FRPM Data (SCOE Rules Applied)"
)

message("FRPM processing complete!")
