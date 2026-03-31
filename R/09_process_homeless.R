# 09_process_homeless.R
# Extracts, cleans, and pins statewide homeless enrollment data

library(tidyverse)
library(janitor)
library(pins)
library(here)

# 1. Establish robust project paths and load helpers
source(here("R", "data-urls.R"))
source(here("R", "load-files.R"))
source(here("R", "clean.R"))

# Connect to the local Pins board
local_board <- board_folder(here("data", "pins"))

# 2. Load & Clean Raw Homeless Data -------------------------------------------
message("Downloading and cleaning Homeless Enrollment Data...")

homeless_clean <- pmap_dfr(homeless_files, function(academic_year, url) {
  # Direct read since these are unzipped .txt files.
  read_tsv(
    url,
    # FIX 1: Catch literal "NULL" strings, asterisks, and blanks right on import
    na = c("", "NA", "NULL", "null", "*", "N/A", "-"),
    col_types = cols(
      # FIX 2: Read everything as character first so pmap_dfr never fails 
      # due to mismatched column types between different years
      .default = col_character()
    )
  ) |>
    normalize_cde_names()
}) |>
  mutate(
    # Safety check to ensure any variation of the code columns remain character strings
    across(
      any_of(c("county_code", "district_code", "school_code")),
      as.character
    ),
    
    # FIX 3: Force District, County, and State aggregates to use "0000000" for school_code
    # This prevents the join failures downstream in your What-If script
    school_code = if_else(
      aggregate_level %in% c("T", "C", "D") & is.na(school_code), 
      "0000000", 
      school_code
    ),

    # FIX 4: Safely parse all enrollment counts to numeric
    across(
      ends_with("enrollment"), 
      parse_number
    ),

    county_name = if_else(
      aggregate_level == "T",
      "CA State Aggregate",
      county_name
    ),
    district_name = case_when(
      aggregate_level == "T" ~ "CA State Aggregate",
      aggregate_level == "C" ~ "County Aggregate",
      .default = district_name
    ),
    school_name = case_when(
      aggregate_level == "T" ~ "CA State Aggregate",
      aggregate_level == "C" ~ "County Aggregate",
      aggregate_level == "D" ~ "District Aggregate",
      .default = school_name
    ),
    reporting_group = case_when(
      startsWith(reporting_category, "R") ~ "Race/Ethnicity",
      startsWith(reporting_category, "S") ~ "Program",
      startsWith(reporting_category, "GR") ~ "Grade",
      startsWith(reporting_category, "G") ~ "Gender",
      startsWith(reporting_category, "HUY") ~ "Homeless Unaccompanied Youth Status",
      reporting_category == "TA" ~ "Total"
    ),
    reporting_long = case_match(
      reporting_category,
      "RB" ~ "Black/African American",
      "RI" ~ "American Indian or Alaska Native",
      "RA" ~ "Asian",
      "RF" ~ "Filipino",
      "RH" ~ "Hispanic or Latino",
      "RD" ~ "Did not Report",
      "RP" ~ "Pacific Islander",
      "RT" ~ "Two or More Races",
      "RW" ~ "White",
      "SE" ~ "English Learners",
      "SD" ~ "Students with Disabilities",
      "SM" ~ "Migrant",
      "GM" ~ "Male",
      "GF" ~ "Female",
      "GX" ~ "Non-Binary Gender",
      "GZ" ~ "Missing Gender",
      "GRKN" ~ "Kindergarten",
      "GR01" ~ "Grade 1",
      "GR02" ~ "Grade 2",
      "GR03" ~ "Grade 3",
      "GR04" ~ "Grade 4",
      "GR05" ~ "Grade 5",
      "GR06" ~ "Grade 6",
      "GR07" ~ "Grade 7",
      "GR08" ~ "Grade 8",
      "GR09" ~ "Grade 9",
      "GR10" ~ "Grade 10",
      "GR11" ~ "Grade 11",
      "GR12" ~ "Grade 12",
      "HUYN" ~ "Homeless Unaccompanied Youth (No)",
      "HUYY" ~ "Homeless Unaccompanied Youth (Yes)",
      "TA" ~ "Total Students",
      # Add a default just in case the CDE adds a new category next year
      .default = reporting_category 
    )
  )

# 3. Pin to Local Board -------------------------------------------------------
message("Pinning cleaned homeless data...")

pin_write(
  board = local_board,
  x = homeless_clean,
  name = "homeless_enrollment_clean",
  type = "parquet",
  title = "Cleaned Homeless Enrollment Data",
  description = "Statewide homeless enrollment data cleaned and standardized."
)

message("Success! Homeless data downloaded, cleaned, and pinned.")