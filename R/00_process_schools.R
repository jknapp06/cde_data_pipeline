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

ca_schools <- vroom(
  temp_txt,
  delim = "\t",
  show_col_types = FALSE
) |>
  # Add the current year so normalize_cde_names doesn't complain,
  # and also to support matching when needed.
  mutate(reporting_year = as.numeric(format(Sys.Date(), "%Y"))) |>
  # Passes through our super-charged normalizer!
  # This now standardizes names, extracts codes from CDS, and title-cases entity names.
  normalize_cde_names()

# 4. Apply SCOE Business Rules (Funding & Grouping) --------------------------
message("Applying SCOE Charter Reporting Rules...")

ca_directory <- ca_schools |>
  mutate(
    # SCOE DISTRICT REPORTING RULES
    scoe_reporting_district = case_when(
      charter == "Y" & funding_type == "Directly funded" ~ school_name,
      TRUE ~ district_name
    ),

    # SCOE SCHOOL REPORTING RULES
    scoe_reporting_school = school_name
  )

# 5. Pin the Master Directory ------------------------------------------------
message("Pinning SCOE Master Directory...")

pin_write(
  board = local_board,
  x = ca_directory,
  name = "ca_schools_directory",
  type = "parquet",
  description = "Master lookup table for CA schools. Includes SCOE charter funding rules and canonical snake_case names."
)

message("School directory successfully pinned! Ready for use.")
