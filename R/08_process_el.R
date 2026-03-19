# 08_process_el.R
# Processes CDE Long-Term English Learner (LTEL) data, applies SCOE
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

scoe_schools <- pin_read(local_board, "solano_schools_directory") |>
  select(school_code, scoe_reporting_district, scoe_reporting_school) |>
  mutate(school_code = as.character(school_code))

# 3. Process English Learner Data --------------------------------------------
message("Processing English Learner data...")

# Iterate directly over the CDE URLs from data-urls.R (assumed list: el_urls)
ca_english_learners <- imap_dfr(el_urls, \(url, year) {
  load_txt_from_cache(url, delim = "\t") |>
    # Correctly rename the text columns
    rename(any_of(c(
      school_name = "school",
      county_name = "county",
      district_name = "district"
    ))) |>
    mutate(
      year = as.numeric(year),
      # Extract the 7-digit school code from the 14-digit CDS code
      school_code = substr(as.character(cds), 8, 14)
    ) |>
    # Force all the grade/count columns to numeric, protect text/identifiers
    mutate(across(
      .cols = -any_of(c(
        "cds",
        "lc",
        "language",
        "county_name",
        "county_code",
        "district_name",
        "district_code",
        "school_name",
        "school_code"
      )),
      .fns = ~ suppressWarnings(parse_number(as.character(.x)))
    ))
})

# 4. Apply SCOE Business Rules for Solano Subset -----------------------------
solano_english_learners <- ca_english_learners |>
  filter(county_name == "Solano") |>
  left_join(scoe_schools, by = "school_code") |>
  mutate(
    district_name = coalesce(scoe_reporting_district, district_name),
    school_name = coalesce(scoe_reporting_school, school_name)
  )

# 5. Pin the Results ---------------------------------------------------------
pin_write(
  local_board,
  ca_english_learners,
  "ca_english_learners",
  type = "parquet",
  title = "Statewide English Learner Data"
)
pin_write(
  local_board,
  solano_english_learners,
  "solano_english_learners",
  type = "parquet",
  title = "Solano English Learner Data (SCOE Rules Applied)"
)

message("English Learner processing complete!")
