# 05_process_attendance.R
# Processes CDE Chronic Absenteeism data, maps demographics, applies SCOE
# charter reporting rules, and pins the resulting dataset.

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

# Added a quick as.character() coercion to match your normalizer's output types
scoe_schools <- pin_read(local_board, "solano_schools_directory") |>
  select(school_code, scoe_reporting_district, scoe_reporting_school) |>
  mutate(school_code = as.character(school_code))

# 3. Process Attendance Data -------------------------------------------------
message("Processing Chronic Absenteeism data...")

attendance_data <- map_dfr(absent_urls, \(url) {
  load_txt_from_cache(url, delim = "\t") |>
    # Only parse if the column starts with "chronic" AND is text
    mutate(across(
      .cols = starts_with("chronic") & where(is.character),
      .fns = parse_number
    )) |>
    # Standardize names and types BEFORE binding rows to prevent map_dfr schema crashes
    normalize_cde_names(data_term = "spring")
}) |>
  filter(county_name == "Solano") |>
  mutate(
    student_group = case_when(
      startsWith(reporting_category, "R") ~ "Race/Ethnicity",
      startsWith(reporting_category, "GR") ~ "Grade",
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
      "RD" ~ "Did not Report",
      "RP" ~ "Pacific Islander",
      "RT" ~ "Two or More Races",
      "RW" ~ "White",
      "GM" ~ "Male",
      "GF" ~ "Female",
      "GX" ~ "Non-Binary Gender",
      "GZ" ~ "Missing Gender",
      "SE" ~ "English Learners",
      "SD" ~ "Students with Disabilities",
      "SS" ~ "Socioeconomically Disadvantaged",
      "SM" ~ "Migrant",
      "SF" ~ "Foster",
      "SH" ~ "Homeless",
      "GRK" ~ "Kindergarten",
      "GRKN" ~ "Kindergarten",
      "GR13" ~ "Grades 1–3",
      "GR46" ~ "Grades 4–6",
      "GR78" ~ "Grades 7–8",
      "GRK8" ~ "Grades K–8",
      "GR912" ~ "Grades 9–12",
      "GRUG" ~ "Ungraded Elementary and Secondary",
      "TA" ~ "All Students"
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
  attendance_data,
  "solano_attendance",
  type = "parquet",
  description = "Longitudinal Chronic Absenteeism with demographic mapping and SCOE rules applied."
)

message("Attendance processing complete!")
