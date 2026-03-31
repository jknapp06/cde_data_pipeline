# refresh_all.R
# Master orchestrator to rebuild the entire CDE data pipeline

library(here)

message("Starting full CDE pipeline refresh...")

# Each of these scripts is completely self-contained and will load
# its own packages and helpers as it spins up.
source(here("R", "00_process_schools.R"))
source(here("R", "01_process_dashboard.R"))
source(here("R", "02_process_caaspp.R"))
source(here("R", "03_process_enrollment.R"))
source(here("R", "04_process_assessments.R"))
source(here("R", "05_process_attendance.R"))
source(here("R", "06_process_discipline.R"))
source(here("R", "07_process_frpm.R"))
source(here("R", "08_process_el.R"))
source(here("R", "09_process_homeless.R"))
source(here("R", "10_process_upc.R"))

message("Pipeline refresh complete!")
