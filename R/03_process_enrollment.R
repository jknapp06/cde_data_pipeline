# 03_process_enrollment.R
# Processes Census, Cumulative, Dashboard, and UPC enrollment data,
# applies SCOE charter mapping rules, and pins the results.
# NOTE: Relies on tribbles loaded from data-urls.R

library(tidyverse)
library(janitor)
library(vroom)
library(openxlsx)
library(pins)
library(here)

# 1. Establish robust project paths and load helpers
source(here("R", "data-urls.R"))
source(here("R", "load-files.R"))
source(here("R", "clean.R")) # Handles CDE normalizations, CDS building, and year formatting

# 2. Connect to the local Pins board
local_board <- board_folder(here("data", "pins"))

# --- STANDARDIZED COLUMN ORDER ---
standard_id_cols <- c(
  "cds", "county_code", "district_code", "school_code",
  "county_name", "district_name", "school_name",
  "academic_year", "reporting_year", "aggregate_level", "rtype"
)

# Load SCOE School Directory (Provides the SCOE business rules for charters)
scoe_schools <- pin_read(local_board, "solano_schools_directory") |>
  select(county_code, district_code, school_code, scoe_reporting_district, scoe_reporting_school) |>
  mutate(across(ends_with("_code"), as.character)) |>
  distinct(county_code, district_code, school_code, .keep_all = TRUE) 

# --- CANONICAL STUDENT GROUP MAPPING FOR CENSUS & CUMULATIVE ---
reporting_category_mapping <- c(
  "AR_03" = "Children 0 to 3 years old",
  "AR_0418" = "Students 4 to 18 years old",
  "AR_1922" = "Continuing students 19 to 22 years old",
  "AR_2329" = "Non-traditional adult students 23 to 29 years old",
  "AR_3039" = "Non-traditional adult students 30 to 39 years old",
  "AR_4049" = "Non-traditional adult students 40 to 49 years old",
  "AR_50P" = "Non-traditional adult students 50+ years old",
  "ELAS_ADEL" = "Adult English Learner",
  "ELAS_EL" = "English Learner",
  "ELAS_EO" = "English Only Students",
  "ELAS_IFEP" = "Initial Fluent English Proficient",
  "ELAS_MISS" = "ELAS Missing",
  "ELAS_RFEP" = "Reclassified Fluent English Proficient",
  "ELAS_TBD" = "ELAS To Be Determined",
  "GN_F" = "Female",
  "GN_M" = "Male",
  "GN_X" = "Non-Binary",
  "GN_Z" = "Gender Missing",
  "RE_A" = "Asian",
  "RE_B" = "Black/African American",
  "RE_D" = "Race/Ethnicity Not Reported",
  "RE_F" = "Filipino",
  "RE_H" = "Hispanic",
  "RE_I" = "American Indian or Alaska Native",
  "RE_P" = "Pacific Islander",
  "RE_T" = "Multiple Races/Two or more",
  "RE_W" = "White",
  "SG_EL" = "English Learner",
  "SG_DS" = "Students with Disabilities",
  "SG_SD" = "Socioeconomically Disadvantaged",
  "SG_MG" = "Migrant Youth",
  "SG_FS" = "Foster Youth",
  "SG_HM" = "Homeless Youth",
  "TA" = "All Students"
)

# 1. Create the lookup function
reporting_category_lookup <- function(df) {
  df |>
    mutate(
      reporting_group = case_when(
        str_starts(reporting_category, "AR") ~ "Age Range",
        str_starts(reporting_category, "ELAS") ~ "English Language Acquisition Status (ELAS)",
        str_starts(reporting_category, "GN") ~ "Gender",
        str_starts(reporting_category, "RE") ~ "Race/Ethnicity",
        str_starts(reporting_category, "SG") ~ "Student Group",
        str_starts(reporting_category, "TA") ~ "Total"
      ),
      student_group = recode_values(
        reporting_category,
        from = names(reporting_category_mapping),
        to = unname(reporting_category_mapping),
        default = reporting_category 
      )
    )
}

# ==============================================================================
# 2. CENSUS DAY ENROLLMENT 
# ==============================================================================
message("Processing Census Day Enrollment...")

census_raw <- pmap_dfr(census_files, function(year, url) {
  load_txt_from_cache(url) |>
    mutate(academic_year = as.character(year)) |>
    normalize_cde_names(data_term = "fall") |>
    reporting_category_lookup() |> 
    rename(gr_13 = any_of(c("total_enr", "total_enrollment", "enrollment"))) |>
    pivot_longer(
      cols = starts_with("gr_"),
      names_to = "grade",
      values_to = "enrollment",
      values_transform = as.numeric
    ) |>
    mutate(
      grade = str_remove(grade, "^gr_"),
      grade = case_when(
        grade == "tk" ~ "TK",
        grade == "kn" ~ "K",
        .default = str_remove(grade, "^0+") 
      )
    )
})

cde_official_lookup <- census_raw |>
  filter(county_name == "Solano") |>
  # Keep only the total 'ALL' rollup for districts, or allow all for actual schools
  filter(is.na(charter) | toupper(charter) == "ALL" | school_code != "0000000") |>
  select(cds, academic_year, reporting_group, student_group, grade, cde_aggregate = enrollment) |>
  # Group by instead of distinct to catch any remaining duplicates gracefully
  group_by(cds, academic_year, reporting_group, student_group, grade) |>
  summarise(cde_aggregate = sum(cde_aggregate, na.rm = TRUE), .groups = "drop")

census_schools <- census_raw |>
  filter(county_name == "Solano", !is.na(enrollment), school_code != "0000000", school_name != "Nonpublic, Nonsectarian Schools") |> 
  left_join(scoe_schools, by = join_by("county_code", "district_code", "school_code")) |>
  mutate(
    district_name = coalesce(scoe_reporting_district, district_name),
    school_name = coalesce(scoe_reporting_school, school_name),
    academic_year = factor(academic_year),
    student_group = factor(student_group),
    aggregate_level = "S" 
  ) |>
  select(cds, aggregate_level, county_code, county_name, district_code, district_name, school_code, school_name, academic_year, reporting_year, reporting_group, student_group, grade, enrollment)

# Creating entirely new District and County aggregates safely
census_districts <- census_schools |>
  group_by(county_code, county_name, district_code, district_name, academic_year, reporting_year, reporting_group, student_group, grade) |>
  summarise(enrollment = sum(enrollment, na.rm = TRUE), .groups = "drop") |>
  mutate(school_code = "0000000", school_name = "District Aggregate", cds = paste0(county_code, district_code, "0000000"), aggregate_level = "D")

census_county <- census_districts |>
  group_by(county_code, county_name, academic_year, reporting_year, reporting_group, student_group, grade) |>
  summarise(enrollment = sum(enrollment, na.rm = TRUE), .groups = "drop") |>
  mutate(district_code = "00000", district_name = "Solano County Aggregate", school_code = "0000000", school_name = "County Aggregate", cds = paste0(county_code, "000000000000"), aggregate_level = "C")

census_enrollment_final <- bind_rows(census_schools, census_districts, census_county) |> 
  distinct() |>
  left_join(cde_official_lookup, by = c("cds", "academic_year", "reporting_group", "student_group", "grade")) |>
  mutate(cde_aggregate = coalesce(cde_aggregate, enrollment)) |>
  select(any_of(standard_id_cols), everything())

pin_write(local_board, census_enrollment_final, "solano_census_enrollment", type = "parquet", description = "Longitudinal Census Enrollment with SCOE LEA aggregations, NPS excluded, and official CDE aggregates maintained.")

# ==============================================================================
# 3. CUMULATIVE ENROLLMENT
# ==============================================================================
message("Processing Cumulative Enrollment...")

cum_raw <- pmap_dfr(cumulative_files, function(year, url) {
  load_txt_from_cache(url) |>
    mutate(reporting_year = year) |>
    normalize_cde_names(data_term = "spring") |> 
    reporting_category_lookup() |>
    rename(cumulative_enrollment = any_of(c("cumulative_enrollment", "total_enrollment", "enrollment"))) |>
    mutate(cumulative_enrollment = suppressWarnings(as.numeric(cumulative_enrollment)))
})

cum_cde_official <- cum_raw |>
  filter(county_name == "Solano") |>
  filter(is.na(charter) | toupper(charter) == "ALL" | school_code != "0000000") |>
  select(cds, academic_year, reporting_group, student_group, cde_aggregate = cumulative_enrollment) |>
  group_by(cds, academic_year, reporting_group, student_group) |>
  summarise(cde_aggregate = sum(cde_aggregate, na.rm = TRUE), .groups = "drop")

cum_schools <- cum_raw |>
  filter(
    county_name == "Solano", 
    !is.na(cumulative_enrollment), 
    school_code != "0000000", 
    school_name != "Nonpublic, Nonsectarian Schools"
  ) |>
  left_join(scoe_schools, by = join_by("county_code", "district_code", "school_code")) |>
  mutate(
    district_name = coalesce(scoe_reporting_district, district_name),
    school_name = coalesce(scoe_reporting_school, school_name),
    academic_year = factor(academic_year),
    student_group = factor(student_group),
    aggregate_level = "S" 
  ) |>
  select(cds, aggregate_level, county_code, county_name, district_code, district_name, school_code, school_name, academic_year, reporting_year, reporting_group, student_group, cumulative_enrollment)

cum_districts <- cum_schools |>
  group_by(county_code, county_name, district_code, district_name, academic_year, reporting_year, reporting_group, student_group) |>
  summarise(cumulative_enrollment = sum(cumulative_enrollment, na.rm = TRUE), .groups = "drop") |>
  mutate(school_code = "0000000", school_name = "District Aggregate", cds = paste0(county_code, district_code, "0000000"), aggregate_level = "D")

cum_county <- cum_districts |>
  group_by(county_code, county_name, academic_year, reporting_year, reporting_group, student_group) |>
  summarise(cumulative_enrollment = sum(cumulative_enrollment, na.rm = TRUE), .groups = "drop") |>
  mutate(district_code = "00000", district_name = "Solano County Aggregate", school_code = "0000000", school_name = "County Aggregate", cds = paste0(county_code, "000000000000"), aggregate_level = "C")

cum_enrollment_final <- bind_rows(cum_schools, cum_districts, cum_county) |> 
  distinct() |>
  left_join(cum_cde_official, by = c("cds", "academic_year", "reporting_group", "student_group")) |>
  mutate(cde_aggregate = coalesce(cde_aggregate, cumulative_enrollment)) |>
  select(any_of(standard_id_cols), everything())

pin_write(local_board, cum_enrollment_final, "solano_cumulative_enrollment", type = "parquet", description = "Longitudinal Cumulative Enrollment with SCOE aggregations.")

# ==============================================================================
# 4. DASHBOARD ENROLLMENT
# ==============================================================================
message("Processing Dashboard Enrollment...")

# 1. Load the raw data and standardize names/levels
dash_raw <- pmap_dfr(dash_files, function(year, url) {
  load_txt_from_cache(url) |>
    normalize_cde_names() |>
    mutate(reporting_year = coalesce(reporting_year, as.numeric(year)))
}) |>
  # rename(aggregate_level = any_of(c("rtype", "r_type"))) |> 
  filter(county_name == "Solano") |>
  mutate(
    county_name = if_else(rtype == "X", "CA State Aggregate", county_name),
    district_name = if_else(rtype == "X", "State of California", district_name),
    school_name = if_else(rtype == "D" & (is.na(school_name) | school_name == "No Data"), "District Aggregate", school_name)
  )

# 2. Map the actual demographic subgroups
dash_subgroups <- dash_raw |>
  mutate(
    student_group = case_match(
      toupper(str_trim(student_group)),
      "AA" ~ "Black/African American", 
      "AI" ~ "American Indian or Alaska Native",
      "AS" ~ "Asian", 
      "FI" ~ "Filipino", 
      "HI" ~ "Hispanic", 
      "PI" ~ "Pacific Islander", 
      "WH" ~ "White",
      "MR" ~ "Multiple Races/Two or more", 
      "EL" ~ "English Learner", 
      "ELO" ~ "English Learners Only",
      "RFP" ~ "RFEPs Only", 
      "EO" ~ "English Only Students", 
      "SBA" ~ "Smarter Balanced Assessment",
      "CAA" ~ "CA Alternative Assessment", 
      "SED" ~ "Socioeconomically Disadvantaged",
      "SWD" ~ "Students with Disabilities", 
      "FOS" ~ "Foster Youth", 
      "HOM" ~ "Homeless Youth",
      .default = student_group 
    )
  )

# 3. Construct the missing "All Students" group using total_enrollment
dash_all_students <- dash_subgroups |>
  distinct(cds, academic_year, reporting_year, .keep_all = TRUE) |>
  mutate(
    student_group = "All Students",
    subgroup_total = total_enrollment,
    rate = 100 # All Students mathematically represent 100% of the school's enrollment
  )

# 4. Bind them together and apply SCOE mappings
dash_enrollment <- bind_rows(dash_all_students, dash_subgroups) |>
  left_join(scoe_schools, by = join_by("county_code", "district_code", "school_code")) |>
  mutate(
    district_name = coalesce(scoe_reporting_district, district_name),
    school_name = coalesce(scoe_reporting_school, school_name)
  ) |>
  select(any_of(standard_id_cols), everything())

pin_write(local_board, dash_enrollment, "solano_dash_enrollment", type = "parquet", description = "Longitudinal Dashboard Enrollment with SCOE charter rules applied")

# ==============================================================================
# 5. UNDUPLICATED PUPIL COUNT (UPC)
# ==============================================================================
message("Processing UPC Data...")

upc_enrollment <- pmap_dfr(upc_files, function(year, url, sheet, start_row) {
  load_excel_from_cache(url, sheet = sheet, start_row = start_row) |>
    mutate(academic_year = year) |>
    normalize_cde_names(data_term = "fall") |>
    rename(free_reduced_meal_program = any_of(c("free_reduced_price_meals", "free_reduced_meal_program")))
}) |>
  filter(county_name == "Solano") |>
  mutate(
    school_name = if_else(is.na(school_name) | school_name == "N/A", "District Aggregate", school_name),
    aggregate_level = case_when(
      district_code == "00000" ~ "C",
      school_code == "0000000" ~ "D",
      .default = "S"
    )
  ) |>
  left_join(scoe_schools, by = join_by("county_code", "district_code", "school_code")) |>
  mutate(
    district_name = coalesce(scoe_reporting_district, district_name),
    school_name = coalesce(scoe_reporting_school, school_name)
  ) |>
  pivot_longer(
    cols = any_of(c(
      "total_enrollment", "free_reduced_meal_program", "foster", "tribal_foster_youth",
      "homeless", "migrant_program", "direct_certification", "unduplicated_frpm_eligible_count",
      "english_learner", "calpads_unduplicated_pupil_count_upc"
    )),
    names_to = "program",
    values_to = "student_count"
  ) |>
  select(any_of(standard_id_cols), everything())

pin_write(local_board, upc_enrollment, "solano_upc_enrollment", type = "parquet", description = "Longitudinal UPC Enrollment with SCOE charter rules applied")

message("All enrollment processing complete!")