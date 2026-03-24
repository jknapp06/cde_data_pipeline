# # 📊 CDE Data Pipeline

## Overview
This repository contains an end-to-end data pipeline for fetching, cleaning, and standardizing California Department of Education (CDE) datasets. The pipeline leverages the `pins` package to cache processed data as high-performance `.parquet` files, creating a reliable local data lake for downstream analysis and dashboarding.

### Orchestration
The entire pipeline can be refreshed by running the master orchestrator script:
`source("R/refresh_all.R")`

This script executes 11 self-contained modules in sequence, ensuring that foundational lookup tables (like the school directory) are built before dependent datasets are processed.

---

## 🗂️ Pin Inventory by Source Script

### `00_process_schools.R`
| Pin Name | Description | Key Features |
| :--- | :--- | :--- |
| `ca_schools_directory` | Master lookup table for CA public schools. | Contains canonical `snake_case` names and applies SCOE-specific charter funding/reporting rules. |

### `01_process_dashboard.R`
| Pin Name | Description | Key Features |
| :--- | :--- | :--- |
| `ca_dashboard_full` | Complete CA School Dashboard | Unfiltered dashboard metrics for the whole state. |
| `solano_dashboard` | Solano County Dashboard | Filtered for Solano LEAs. |
| `solano_dashboard_essa` | Solano Dashboard + ESSA | Includes Differentiated Assistance and ESSA eligibility flags. |
| `ca_teacher_assignments` | Statewide Teacher Assignments | Cleaned credentialing and assignment data. |
| `solano_teacher_assignments`| Solano Teacher Assignments | Filtered for Solano LEAs. |

### `02_process_caaspp.R`
| Pin Name | Description | Key Features |
| :--- | :--- | :--- |
| `solano_caaspp_clean` | Solano County & State CAASPP Data | Cleaned CAASPP results filtered exclusively for Solano County LEAs and State Aggregates. |

### `03_process_enrollment.R`
| Pin Name | Description | Key Features |
| :--- | :--- | :--- |
| `solano_census_enrollment` | Longitudinal Census Day Enrollment | Standardized demographics and grades; applies SCOE charter rules. |
| `solano_cumulative_enrollment`| Longitudinal Cumulative Enrollment | Total enrolled throughout the year; uses `student_group_long`. |
| `solano_dash_enrollment` | Longitudinal Dashboard Enrollment | Enrollment tied to Dashboard reporting groups; accounts for state aggregates. |
| `solano_upc_enrollment` | Longitudinal UPC Enrollment | Pivoted program counts (FRPM, Foster, Homeless, etc.). |

### `04_process_assessments.R`
| Pin Name | Description | Key Features |
| :--- | :--- | :--- |
| `solano_cast` | Solano CAST Data | Science testing results for Solano County (2021-2024). |
| `solano_elpac_initial` | Initial ELPAC Data | Solano County Initial ELPAC results (2019-2024). |
| `solano_elpac_summative` | Summative ELPAC Data | Solano County & State Aggregates (2019-2024). |

### `05_process_attendance.R`
| Pin Name | Description | Key Features |
| :--- | :--- | :--- |
| `solano_attendance` | Solano Chronic Absenteeism | Longitudinal data with demographic mapping and SCOE rules applied. |

### `06_process_discipline.R`
| Pin Name | Description | Key Features |
| :--- | :--- | :--- |
| `solano_discipline` | Solano Suspension Data | Longitudinal suspension data with demographic mapping and SCOE rules applied. |

### `07_process_frpm.R`
| Pin Name | Description | Key Features |
| :--- | :--- | :--- |
| `ca_frpm` | Statewide FRPM Data | Free/Reduced Price Meals data for all of CA. |
| `solano_frpm` | Solano FRPM Data | Solano subset with SCOE rules applied. |

### `08_process_el.R`
| Pin Name | Description | Key Features |
| :--- | :--- | :--- |
| `ca_english_learners` | Statewide English Learner Data | Statewide EL enrollment counts. |
| `solano_english_learners` | Solano English Learner Data | Solano subset with SCOE rules applied. |

### `09_process_homeless.R`
| Pin Name | Description | Key Features |
| :--- | :--- | :--- |
| `homeless_enrollment_clean`| Cleaned Homeless Enrollment Data | Statewide homeless enrollment data cleaned and standardized. |

### `10_process_upc.R`
| Pin Name | Description | Key Features |
| :--- | :--- | :--- |
| `ca_upc` | Statewide UPC Data | Unduplicated Pupil Counts at LEA and School levels. |
| `solano_upc` | Solano UPC Data | Solano subset with SCOE rules applied. |

---

## 🛠️ Universal Conventions & Architecture

To make joining datasets seamless across this project, all dataframes adhere to strict structural rules:

1. **Storage Format:** Saved as compressed `.parquet` files via `pins` for rapid I/O and low memory overhead.
2. **Column Naming:** Strictly `snake_case` (e.g., `county_name`, `academic_year`). Special characters and spaces are stripped during ingestion.
3. **Identifiers:** * `cds`, `school_code`, `district_code`, `county_code` are parsed as **character strings** to preserve leading zeros.
   * Geographical text columns are always named exactly `county_name`, `district_name`, and `school_name`.
4. **SCOE Charter Routing:** Most Solano-specific datasets map charter schools back to their appropriate SCOE reporting district/school using the canonical `solano_schools_directory`.

## 📖 Key Variable Glossary

* **`indicator`**: The specific Dashboard metric (e.g., "ELA", "Math", "graduation").
* **`color`**: The Dashboard performance tier (1 = Red, 2 = Orange, 3 = Yellow, 4 = Green, 5 = Blue).
* **`reporting_category_long`**: Demographic grouping used in Census/UPC data (e.g., "Hispanic or Latino").
* **`student_group_long`**: Demographic grouping mapped to match the public Dashboard subgroups.
* **`program`**: Pivot key used in UPC files representing funding categories (e.g., "foster", "homeless").