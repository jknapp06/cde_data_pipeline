# 06_process_discipline.R
# Processes CDE Suspension data, maps demographics, applies SCOE charter
# reporting rules, and pins the resulting dataset.

library(tidyverse)
library(janitor)
library(vroom)
library(pins)
library(here)

# 1. Establish robust project paths and load helpers
source(here("R", "data-urls.R"))
source(here("R", "load-files.R"))
source(here("R", "clean.R"))

# 2. Connect to the local Pins board
local_board <- board_folder(here("data", "pins"))

scoe_schools <- pin_read(local_board, "solano_schools_directory") |>
  select(school_code, scoe_reporting_district, scoe_reporting_school)

# 3. Process Discipline Data -------------------------------------------------
message("Processing Suspension data...")

discipline_data <- map_dfr(suspend_urls, \(url) {
  load_txt_from_cache(url, delim = "\t")
}) |>
  filter(county_name == "Solano") |>
  mutate(
    school_code = as.character(school_code),
    year = parse_number(substr(academic_year, 1, 4)),
    student_group = case_when(
      startsWith(reporting_category, "R") ~ "Race/Ethnicity",
      startsWith(reporting_category, "G") ~ "Gender",
      startsWith(reporting_category, "S") ~ "Student Profiles",
      startsWith(reporting_category, "T") ~ "All Students"
    ),
    demographic_name = case_match(
      reporting_category,
      "RB" ~ "African American",
      "RI" ~ "American Indian or Alaska Native",
      "RA" ~ "Asian",
      "RF" ~ "Filipino",
      "RH" ~ "Hispanic or Latino",
      "RD" ~ "Not Reported",
      "RP" ~ "Pacific Islander",
      "RT" ~ "Two or More Races",
      "RW" ~ "White",
      "GM" ~ "Male",
      "GF" ~ "Female",
      "GX" ~ "Non-Binary Gender (Beginning 2019–20)",
      "GZ" ~ "Missing Gender",
      "SE" ~ "English Learners",
      "SD" ~ "Students with Disabilities",
      "SS" ~ "Socioeconomically Disadvantaged",
      "SM" ~ "Migrant",
      "SF" ~ "Foster",
      "SH" ~ "Homeless",
      "TA" ~ "Total"
    )
  ) |>
  # 4. Apply SCOE Business Rules ---------------------------------------------
  left_join(scoe_schools, by = "school_code") |>
  mutate(
    district_name = coalesce(scoe_reporting_district, district_name),
    school_name = coalesce(scoe_reporting_school, school_name)
  )

# 5. Pin the Result ----------------------------------------------------------
pin_write(
  local_board,
  discipline_data,
  "solano_discipline",
  type = "parquet",
  description = "Longitudinal Suspension Data with demographic mapping and SCOE rules applied."
)

message("Discipline processing complete!")
