# 01_process_dashboard.R
# Extracts, cleans, and pins California School Dashboard & Assistance data

library(tidyverse)
library(here)
library(pins)

options(scipen = 999)

# 1. Establish robust project paths and load helpers -------------------------
source(here("R", "data-urls.R"))
source(here("R", "load-files.R"))
source(here("R", "clean.R"))

# Connect to the local Pins board
local_board <- board_folder(here("data", "pins"))

# 3. Read Dashboard Indicator Files -------------------------------------------
message("Loading dashboard indicator files...")
dashboard_raw <- download_and_load_dashboard_set(dashboard_files)

# Set all school names to current names from latest year
max_year <- max(dashboard_raw$reportingyear, na.rm = TRUE)

current_names_codes <- dashboard_raw |>
  filter(reportingyear == max_year) |>
  select(cds, countyname, districtname, schoolname) |>
  distinct()

dashboard_raw <- dashboard_raw |>
  select(-countyname, -districtname, -schoolname) |>
  left_join(current_names_codes, by = "cds")

# 4. Read & Normalize Assistance Files ----------------------------------------
message("Loading assistance files...")

# Define the exact parameters for each file
assistance_meta <- tribble(
  ~name                   , ~url                                  , ~sheet , ~start_row ,
  "assistance_25"         , assistance_urls$assistance_25         ,      4 ,          6 ,
  "assistance_25_charter" , assistance_urls$assistance_25_charter ,      4 ,          6 ,
  "assistance_24"         , assistance_urls$assistance_24         ,      4 ,          6 ,
  "assistance_24_charter" , assistance_urls$assistance_24_charter ,      4 ,          6 ,
  "assistance_23"         , assistance_urls$assistance_23         ,      4 ,          6 ,
  "assistance_23_charter" , assistance_urls$assistance_23_charter ,      4 ,          6 ,
  "assistance_22"         , assistance_urls$assistance_22         ,      4 ,          6 ,
  "assistance_19"         , assistance_urls$assistance_19         ,      4 ,          6 ,
  "assistance_18"         , assistance_urls$assistance_18         ,      1 ,          5 ,
  "assistance_17"         , assistance_urls$assistance_17         ,      4 ,          5
)

# Use pmap to iterate over the table and load the files
raw_assistance_list <- pmap(
  assistance_meta,
  function(name, url, sheet, start_row) {
    load_excel_from_cache(url, sheet = sheet, start_row = start_row)
  }
) |>
  set_names(assistance_meta$name)

message("Normalizing assistance data...")
assistance <- normalize_assistance(raw_assistance_list)


# 5. Read & Normalize ESSA Files ----------------------------------------------
message("Loading ESSA files...")

essa_meta <- tribble(
  ~name    , ~url             , ~sheet , ~start_row ,
  "essa25" , essa_urls$essa25 ,      2 ,          3 ,
  "essa24" , essa_urls$essa24 ,      2 ,          3 ,
  "essa23" , essa_urls$essa23 ,      2 ,          3 ,
  "essa22" , essa_urls$essa22 ,      2 ,          3 ,
  "essa21" , essa_urls$essa21 ,      1 ,          3 ,
  "essa19" , essa_urls$essa19 ,      1 ,          3
)

raw_essa_list <- pmap(essa_meta, function(name, url, sheet, start_row) {
  # 1. Load the raw excel file
  df <- load_excel_from_cache(url, sheet = sheet, start_row = start_row)

  # 2. Force demographic columns to numeric (NAs will be introduced by coercion for "*")
  numeric_cols <- c(
    "aa",
    "ai",
    "as",
    "el",
    "fi",
    "fos",
    "hi",
    "hom",
    "pi",
    "sed",
    "swd",
    "tom",
    "wh",
    "enrollment_count"
  )

  existing_numeric_cols <- intersect(numeric_cols, names(df))

  df |>
    mutate(across(
      .cols = all_of(existing_numeric_cols),
      .fns = ~ suppressWarnings(as.numeric(.x))
    ))
}) |>
  set_names(essa_meta$name)

essa <- normalize_essa(raw_essa_list)

# 6. Join Assistance & Compute Eligibility ------------------------------------
message("Merging dashboard with assistance and computing eligibility...")

dashboard_clean <- dashboard_raw |>
  rename_with(~ str_to_lower(.x)) |>
  mutate(
    studentgroup = if_else(
      is.na(studentgroup) & indicator == "ELPI",
      "EL",
      studentgroup
    ),
    student_group_long = case_match(
      studentgroup,
      "ALL" ~ "All students",
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
      "EO" ~ "English Only",
      "SBA" ~ "Smarter Balanced Assessment",
      "CAA" ~ "CA Alternative Assessment",
      "SED" ~ "Socioeconomically Disadvantaged",
      "SWD" ~ "Students with Disabilities",
      "FOS" ~ "Foster Youth",
      "HOM" ~ "Homeless Youth",
      "TOM" ~ "Multiple Races/Two or more",
      "LTEL" ~ "Long-Term English Learner",
      .default = studentgroup
    ),
    countyname = case_match(
      rtype,
      "X" ~ "CA State Aggregate",
      .default = countyname
    ),
    schoolname = case_when(
      rtype == "D" & is.na(schoolname) ~ "District Aggregate",
      TRUE ~ schoolname
    )
  )

check_priorities <- function(priority, priorities) {
  priority %in% unlist(priorities)
}

dashboard_with_assistance <- dashboard_clean |>
  left_join(
    assistance,
    by = join_by(cds, studentgroup, reportingyear, charter_flag)
  ) |>
  left_join(
    priority_eligibility_lookup,
    by = join_by("assistance_current" == "assistance")
  ) |>
  rename(priorities_current = priorities) |>
  left_join(
    priority_eligibility_lookup,
    by = join_by("assistance_prior" == "assistance")
  ) |>
  rename(priorities_prior = priorities) |>
  left_join(priority_eligibility_lookup, by = "assistance")

dashboard_with_elibibility <- dashboard_with_assistance |>
  mutate(
    priority_eligible = if_else(
      is.na(charter_flag),
      map2_lgl(priority, priorities, check_priorities),
      assistance_status == "Differentiated Assistance" &
        map2_lgl(priority, priorities_current, check_priorities)
    )
  ) |>
  select(-starts_with("priorities"))

message("Computing indicator eligibility and priority-4 summary...")
priority_4_tbl <- compute_priority4_summary(dashboard_with_elibibility)

ca_dashboard <- dashboard_with_elibibility |>
  left_join(
    priority_4_tbl,
    by = join_by(cds, reportingyear, student_group_long)
  ) |>
  mutate(
    indicator_eligible = case_when(
      priority == 8 & priority_eligible ~ TRUE,
      priority != 4 & priority_eligible & color == "1" ~ TRUE,
      priority != 4 &
        priority_eligible &
        reportingyear == 2022 &
        statuslevel == 1 ~ TRUE,
      studentgroup != "LTEL" &
        priority == 4 &
        indicator == "ELA" &
        caaspp_eligible == TRUE ~ TRUE,
      studentgroup != "LTEL" &
        priority == 4 &
        indicator == "Math" &
        caaspp_eligible == TRUE ~ TRUE,
      priority == 4 & indicator == "ELPI" & elpi_eligible == TRUE ~ TRUE,
      TRUE ~ FALSE
    )
  ) |>
  select(-c(ELA, Math, ELPI, caaspp_eligible, elpi_eligible))

small_dashboard <- ca_dashboard |>
  filter(countyname %in% c("Solano", "CA State Aggregate"))

# 7. Download & Clean Teacher Data --------------------------------------------
message("Loading teacher credentialing data...")
teacher_assignments <- load_txt_from_cache(teacher_assignments_url)
teacher_assignments_clean <- normalize_teacher_assignments(teacher_assignments)
solano_teachers <- teacher_assignments_clean |> filter(countyname == "Solano")

# 8. Join with ESSA for local dashboard_essa ----------------------------------
dashboard_essa <- ca_dashboard |>
  filter(countyname == "Solano") |>
  left_join(
    essa,
    join_by(
      cds,
      districtname,
      countyname,
      schoolname,
      studentgroup,
      reportingyear
    )
  )


# 9. Pin to Local Board -------------------------------------------------------
message("Pinning all datasets to the OneDrive board...")

# Note: We use 'name' to identify the pin, and 'title'/'description' for metadata
pin_write(
  local_board,
  ca_dashboard,
  name = "ca_dashboard_full",
  type = "parquet",
  title = "Full CA Dashboard"
)
pin_write(
  local_board,
  small_dashboard,
  name = "solano_dashboard",
  type = "parquet",
  title = "Solano Dashboard"
)
pin_write(
  local_board,
  assistance,
  name = "assistance_data",
  type = "parquet",
  title = "School Assistance Status"
)
pin_write(
  local_board,
  essa,
  name = "essa_data",
  type = "parquet",
  title = "ESSA Data"
)
pin_write(
  local_board,
  dashboard_essa,
  name = "solano_dashboard_essa",
  type = "parquet",
  title = "Solano Dashboard + ESSA Joined"
)
pin_write(
  local_board,
  teacher_assignments_clean,
  name = "ca_teacher_assignments",
  type = "parquet",
  title = "CA Teacher Assignments"
)
pin_write(
  local_board,
  solano_teachers,
  name = "solano_teacher_assignments",
  type = "parquet",
  title = "Solano Teacher Assignments"
)

message("Success! All dashboard data refreshed and pinned to OneDrive.")
