# 00_process_schools.R
# Downloads the master CDE public schools directory, applies SCOE's specific
# charter funding rules and naming conventions, and pins the lookup table.

library(tidyverse)
library(janitor)
library(vroom)
library(stringr)
library(pins)
library(here)

# 1. Establish robust project paths and load helpers -------------------------
source(here("R", "data-urls.R"))
source(here("R", "load-files.R"))
source(here("R", "clean.R"))

# 2. Connect to the local Pins board -----------------------------------------
local_board <- board_folder(here("data", "pins"))

# 3. Download and Clean CDE Directory ----------------------------------------
message("Downloading the latest CDE Public Schools Directory...")

temp_txt <- tempfile(fileext = ".txt")

# Use our custom helper with the 5-minute timeout and retry logic
safe_download_file(cde_directory_url, temp_txt)

solano_schools <- vroom(
  temp_txt,
  delim = "\t",
  show_col_types = FALSE
) |>
  clean_names() |>
  filter(county == "Solano") |>
  mutate(
    # First, force the 14-digit code to be a character to keep leading zeros
    cds_code = as.character(cds_code),

    # Extract the codes using stringr::str_sub()
    county_code = str_sub(cds_code, 1, 2),
    district_code = str_sub(cds_code, 3, 7),
    school_code = str_sub(cds_code, 8, 14),

    # Apply standard naming rules to the raw CDE names immediately
    district = smart_title_case(district),
    school = smart_title_case(school)
  ) |>
  select(
    # Now this select() will work because the columns exist!
    county_code,
    county,
    district_code,
    district,
    school_code,
    school,
    status_type,
    charter,
    funding_type
  )

# 4. Apply SCOE Business Rules (Funding & Grouping) --------------------------
message("Applying SCOE Charter Reporting Rules...")

scoe_directory <- solano_schools |>
  mutate(
    # SCOE DISTRICT REPORTING RULES
    scoe_reporting_district = case_when(
      charter == "Y" & funding_type == "Directly funded" ~ school,
      TRUE ~ district
    ),

    # SCOE SCHOOL REPORTING RULES
    scoe_reporting_school = school
  )

# 5. Pin the Master Directory ------------------------------------------------
message("Pinning SCOE Master Directory...")

pin_write(
  board = local_board,
  x = scoe_directory,
  name = "solano_schools_directory",
  type = "parquet",
  description = "Master lookup table for Solano schools. Includes SCOE charter funding rules and name casing."
)

message("School directory successfully pinned! Ready for use.")
