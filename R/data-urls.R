# data-urls.R
# Central place for all source URLs and small constants.
# Load this first in refresh.R

dashboard_files <- tibble::tribble(
  ~priority , ~indicator       , ~url                                                                             ,
          4 , "ELA"            , "https://www3.cde.ca.gov/researchfiles/cadashboard/eladownload2025.txt"          ,
          4 , "Math"           , "https://www3.cde.ca.gov/researchfiles/cadashboard/mathdownload2025.txt"         ,
          4 , "science"        , "https://www3.cde.ca.gov/researchfiles/cadashboard/sciencedownload2025.txt"      ,
          4 , "ELPI"           , "https://www3.cde.ca.gov/researchfiles/cadashboard/elpidownload2025.txt"         ,
          8 , "college/career" , "https://www3.cde.ca.gov/researchfiles/cadashboard/ccidownload2025.txt"          ,
          5 , "graduation"     , "https://www3.cde.ca.gov/researchfiles/cadashboard/graddownload2025.txt"         ,
          5 , "absenteeism"    , "https://www3.cde.ca.gov/researchfiles/cadashboard/chronicdownload2025.txt"      ,
          6 , "suspension"     , "https://www3.cde.ca.gov/researchfiles/cadashboard/suspdownload2025.txt"         ,
          4 , "ELA"            , "https://www3.cde.ca.gov/researchfiles/cadashboard/eladownload2024.txt"          ,
          4 , "Math"           , "https://www3.cde.ca.gov/researchfiles/cadashboard/mathdownload2024.txt"         ,
          4 , "science"        , "https://www3.cde.ca.gov/researchfiles/cadashboard/sciencedownload2024.txt"      ,
          4 , "ELPI"           , "https://www3.cde.ca.gov/researchfiles/cadashboard/elpidownload2024.txt"         ,
          8 , "college/career" , "https://www3.cde.ca.gov/researchfiles/cadashboard/ccidownload2024.txt"          ,
          5 , "graduation"     , "https://www3.cde.ca.gov/researchfiles/cadashboard/graddownload2024.txt"         ,
          5 , "absenteeism"    , "https://www3.cde.ca.gov/researchfiles/cadashboard/chronicdownload2024.txt"      ,
          6 , "suspension"     , "https://www3.cde.ca.gov/researchfiles/cadashboard/suspdownload2024.txt"         ,
          4 , "ELA"            , "https://www3.cde.ca.gov/researchfiles/cadashboard/eladownload2023.txt"          ,
          4 , "Math"           , "https://www3.cde.ca.gov/researchfiles/cadashboard/mathdownload2023.txt"         ,
          4 , "ELPI"           , "https://www3.cde.ca.gov/researchfiles/cadashboard/elpidownload2023.txt"         ,
          8 , "college/career" , "https://www3.cde.ca.gov/researchfiles/cadashboard/ccidownload2023.txt"          ,
          5 , "graduation"     , "https://www3.cde.ca.gov/researchfiles/cadashboard/graddownload2023.txt"         ,
          5 , "absenteeism"    , "https://www3.cde.ca.gov/researchfiles/cadashboard/chronicdownload2023.txt"      ,
          6 , "suspension"     , "https://www3.cde.ca.gov/researchfiles/cadashboard/suspdownload2023.txt"         ,
          4 , "ELA"            , "https://www3.cde.ca.gov/researchfiles/cadashboard/eladownload2022.txt"          ,
          4 , "Math"           , "https://www3.cde.ca.gov/researchfiles/cadashboard/mathdownload2022.txt"         ,
          4 , "ELPI"           , "https://www3.cde.ca.gov/researchfiles/cadashboard/elpidownload2022.txt"         ,
          8 , "college/career" , "https://www3.cde.ca.gov/researchfiles/cadashboard/ccidownload2022.txt"          ,
          5 , "graduation"     , "https://www3.cde.ca.gov/researchfiles/cadashboard/graddownload2022.txt"         ,
          5 , "absenteeism"    , "https://www3.cde.ca.gov/researchfiles/cadashboard/chronicdownload2022.txt"      ,
          6 , "suspension"     , "https://www3.cde.ca.gov/researchfiles/cadashboard/suspdownload2022.txt"         ,
          4 , "ELA"            , "https://www3.cde.ca.gov/researchfiles/cadashboard/eladownload2019.txt"          ,
          4 , "Math"           , "https://www3.cde.ca.gov/researchfiles/cadashboard/mathdownload2019.txt"         ,
          4 , "ELPI"           , "https://www3.cde.ca.gov/researchfiles/cadashboard/elpidownload2019.txt"         ,
          8 , "college/career" , "https://www3.cde.ca.gov/researchfiles/cadashboard/ccidownload2019.txt"          ,
          5 , "graduation"     , "https://www3.cde.ca.gov/researchfiles/cadashboard/graddownload2019.txt"         ,
          5 , "absenteeism"    , "https://www3.cde.ca.gov/researchfiles/cadashboard/chronicdownload2019.txt"      ,
          6 , "suspension"     , "https://www3.cde.ca.gov/researchfiles/cadashboard/suspdownload2019.txt"         ,
          5 , "graduation"     , "https://www3.cde.ca.gov/researchfiles/cadashboard/graddownload2021dassonly.txt" ,
          5 , "graduation"     , "https://www3.cde.ca.gov/researchfiles/cadashboard/graddownload2020dassonly.txt"
)

# Teacher credentialing data
teacher_assignments_url <- "https://www3.cde.ca.gov/demo-downloads/tamo/tamo2324.txt"

# Assistance files (from your original script)
assistance_urls <- list(
  assistance_25 = "https://www.cde.ca.gov/fg/aa/lc/documents/assistancestatus25.xlsx",
  assistance_25_charter = "https://www.cde.ca.gov/fg/aa/lc/documents/charterassistance25.xlsx",
  assistance_24 = "https://www.cde.ca.gov/fg/aa/lc/documents/assistancestatus24.xlsx",
  assistance_24_charter = "https://www.cde.ca.gov/fg/aa/lc/documents/charterassistance24.xlsx",
  assistance_23 = "https://www.cde.ca.gov/fg/aa/lc/documents/assistancestatus23.xlsx",
  assistance_23_charter = "https://www.cde.ca.gov/fg/aa/lc/documents/charterassistance23.xlsx",
  assistance_22 = "https://www.cde.ca.gov/fg/aa/lc/documents/assistancestatus22.xlsx",
  assistance_19 = "https://www.cde.ca.gov/fg/aa/lc/documents/assistancestatus19-rev.xlsx",
  assistance_18 = "https://www.cde.ca.gov/fg/aa/lc/documents/assistancestatus18.xlsx",
  assistance_17 = "https://www.cde.ca.gov/fg/aa/lc/documents/assistancestatus2017.xlsx"
)

# ESSA files (from your original script)
essa_urls <- list(
  essa25 = "https://www.cde.ca.gov/sp/sw/t1/documents/essaassistance25.xlsx",
  essa24 = "https://www.cde.ca.gov/sp/sw/t1/documents/essaassistance24.xlsx",
  essa23 = "https://www.cde.ca.gov/sp/sw/t1/documents/essaassistance23.xlsx",
  essa22 = "https://wayback.archive-it.org/21145/20240221130719/https%3A//www.cde.ca.gov/sp/sw/t1/documents/essaassistance22.xlsx", # double-check if needed
  essa21 = "https://wayback.archive-it.org/21145/20240221130719/https%3A//www.cde.ca.gov/sp/sw/t1/documents/essaassistance21.xlsx",
  essa19 = "https://wayback.archive-it.org/21145/20240221130719/https%3A//www.cde.ca.gov/sp/sw/t1/documents/essaassistance19.xlsx"
  # essa18 = "https://www.cde.ca.gov/sp/sw/t1/documents/scheligibilitystate.xlsx"
)

# ---- CAASPP URLs ----
entities_2025_url <- "https://caaspp-elpac-preview.ets.org/caaspp/researchfiles/sb_ca2025entities_csv.zip"
caaspp_student_groups_url <- "https://caaspp-elpac.ets.org/caaspp/researchfiles/StudentGroups.zip"

solano_caaspp_2025_url <- "https://caaspp-elpac.ets.org/caaspp/researchfiles/sb_ca2025_all_48_csv_v1.zip"
solano_caaspp_2024_url <- "https://caaspp-elpac.ets.org/caaspp/researchfiles/sb_ca2024_all_48_csv_v1.zip"
solano_caaspp_2023_url <- "https://caaspp-elpac.ets.org/caaspp/researchfiles/sb_ca2023_all_48_csv_v1.zip"

# ---- CAST & CAASPP URLs ----
cast_urls <- list(
  "2024" = "https://caaspp-elpac.ets.org/caaspp/researchfiles/cast_ca2024_all_csv_v1.zip",
  "2023" = "https://caaspp-elpac.ets.org/caaspp/researchfiles/cast_ca2023_all_csv_v1.zip",
  "2022" = "https://caaspp-elpac.ets.org/caaspp/researchfiles/cast_ca2022_all_csv_v1.zip",
  "2021" = "https://caaspp-elpac.ets.org/caaspp/researchfiles/cast_ca2021_all_csv_v2.zip"
)
caaspp_student_groups_url <- "https://caaspp-elpac.ets.org/caaspp/researchfiles/StudentGroups.zip"

# ---- ELPAC URLs ----
elpac_initial_urls <- list(
  "2024" = "https://caaspp-elpac.ets.org/elpac/researchfiles/ia_elpac2024_all_csv_v1.zip",
  "2023" = "https://caaspp-elpac.ets.org/elpac/researchfiles/ia_elpac2023_all_csv_v1.zip",
  "2022" = "https://caaspp-elpac.ets.org/elpac/researchfiles/ia_elpac2022_all_csv_v1.zip",
  "2021" = "https://caaspp-elpac.ets.org/elpac/researchfiles/ia_elpac2021_all_csv_v1.zip",
  "2020" = "https://caaspp-elpac.ets.org/elpac/researchfiles/ia_elpac2020_all_csv_v1.zip",
  "2019" = "https://caaspp-elpac.ets.org/elpac/researchfiles/ia_elpac2019_all_csv_v1.zip"
)

elpac_summative_urls <- list(
  "2024" = "https://caaspp-elpac.ets.org/elpac/researchfiles/sa_elpac2024_all_csv_v1.zip",
  "2023" = "https://caaspp-elpac.ets.org/elpac/researchfiles/sa_elpac2023_all_csv_v1.zip",
  "2022" = "https://caaspp-elpac.ets.org/elpac/researchfiles/sa_elpac2022_all_csv_v1.zip",
  "2021" = "https://caaspp-elpac.ets.org/elpac/researchfiles/sa_elpac2021_all_csv_v1.zip",
  "2019" = "https://caaspp-elpac.ets.org/elpac/researchfiles/sa_elpac2019_all_csv_v2.zip"
)
elpac_student_groups_url <- "https://caaspp-elpac.ets.org/elpac/researchfiles/StudentGroups.zip"

# ---- School Info URL ----
pubschls_url <- "https://www.cde.ca.gov/schooldirectory/report?rid=dl1&tp=txt"
cde_directory_url <- "https://www.cde.ca.gov/schooldirectory/report?rid=dl1&tp=txt"

# --- Census Day Enrollment URLs ---
census_urls <- c(
  "2024" = "https://www3.cde.ca.gov/demo-downloads/census/cdenroll2425.txt",
  "2023" = "https://www3.cde.ca.gov/demo-downloads/census/cdenroll2324-v2.txt"
)

old_census_urls <- c(
  "2020-22" = "https://www3.cde.ca.gov/demo-downloads/enrsch/enr202022-v2.txt",
  "2017-19" = "https://www3.cde.ca.gov/demo-downloads/enrsch/enr201719-v2.txt"
)

# --- Cumulative Enrollment URLs ---
cumulative_urls <- c(
  "2024" = "https://www3.cde.ca.gov/demo-downloads/ce/cenroll2324.txt",
  "2023" = "https://www3.cde.ca.gov/demo-downloads/ce/cenroll2223.txt",
  "2022" = "https://www3.cde.ca.gov/demo-downloads/ce/cenroll2122.txt",
  "2021" = "https://www3.cde.ca.gov/demo-downloads/ce/cenroll2021.txt",
  "2020" = "https://www3.cde.ca.gov/demo-downloads/ce/cenroll1920.txt"
)

# --- Dashboard Enrollment URLs ---
dash_urls <- c(
  "2023" = "https://www3.cde.ca.gov/researchfiles/cadashboard/censusenrollratesdownload2023.txt",
  "2022" = "https://www3.cde.ca.gov/researchfiles/cadashboard/censusenrollratesdownload2022.txt",
  "2021" = "https://www3.cde.ca.gov/researchfiles/cadashboard/censusenrollratesdownload2021.txt",
  "2020" = "https://www3.cde.ca.gov/researchfiles/cadashboard/censusenrollratesdownload2020.txt",
  "2019" = "https://www3.cde.ca.gov/researchfiles/cadashboard/censusenrollratesdownload2019.txt",
  "2018" = "https://www3.cde.ca.gov/researchfiles/cadashboard/censusenrollratesdownload2018.txt"
)

# --- Unduplicated Pupil Count (UPC) URLs ---
upc_urls <- c(
  "2024" = "https://www.cde.ca.gov/ds/ad/documents/cupc2324-k12.xlsx",
  "2023" = "https://www.cde.ca.gov/ds/ad/documents/cupc2223-k12.xlsx",
  "2022" = "https://www.cde.ca.gov/ds/ad/documents/cupc2122-k12.xlsx",
  "2021" = "https://www.cde.ca.gov/ds/ad/documents/cupc2021-k12.xlsx",
  "2020" = "https://www.cde.ca.gov/ds/ad/documents/cupc1920-k12.xlsx"
)

# --- Attendance URLs ---
absent_urls <- c(
  "2025" = "https://www3.cde.ca.gov/demo-downloads/attendance/chronicabsenteeism25-v2.txt",
  "2024" = "https://www3.cde.ca.gov/demo-downloads/attendance/chronicabsenteeism24.txt",
  "2023" = "https://www3.cde.ca.gov/demo-downloads/attendance/chronicabsenteeism23.txt",
  "2022" = "https://www3.cde.ca.gov/demo-downloads/attendance/chronicabsenteeism22-v3.txt",
  "2021" = "https://www3.cde.ca.gov/demo-downloads/attendance/chronicabsenteeism21.txt",
  "2019" = "https://www3.cde.ca.gov/demo-downloads/attendance/chronicabsenteeism19.txt"
)

# --- Discipline URLs ---
suspend_urls <- c(
  "2025" = "https://www3.cde.ca.gov/demo-downloads/discipline/suspension25-v2.txt",
  "2024" = "https://www3.cde.ca.gov/demo-downloads/discipline/suspension24.txt",
  "2023" = "https://www3.cde.ca.gov/demo-downloads/discipline/suspension23.txt",
  "2022" = "https://www3.cde.ca.gov/demo-downloads/discipline/suspension22-v2.txt",
  "2021" = "https://www3.cde.ca.gov/demo-downloads/discipline/suspension21.txt",
  "2020" = "https://www3.cde.ca.gov/demo-downloads/discipline/suspension20.txt",
  "2019" = "https://www3.cde.ca.gov/demo-downloads/discipline/suspension19.txt"
)

# --- Free and Reduced Price Meals URLs ---
frpm_urls <- c(
  "2024" = "https://www.cde.ca.gov/ds/ad/documents/frpm2324.xlsx",
  "2023" = "https://www.cde.ca.gov/ds/ad/documents/frpm2223.xlsx",
  "2022" = "https://www.cde.ca.gov/ds/ad/documents/frpm2122_v2.xlsx",
  "2021" = "https://www.cde.ca.gov/ds/ad/documents/frpm2021.xlsx",
  "2020" = "https://www.cde.ca.gov/ds/ad/documents/frpm1920.xlsx",
  "2019" = "https://www.cde.ca.gov/ds/ad/documents/frpm1819.xlsx"
)

# --- English Learner URLs ---
el_urls <- c(
  "2025" = "https://dq.cde.ca.gov/dataquest/dlfile/dlfile.aspx?cLevel=School&cYear=2024-25&cCat=EL&cPage=fileselsch",
  "2024" = "https://dq.cde.ca.gov/dataquest/dlfile/dlfile.aspx?cLevel=School&cYear=2023-24&cCat=EL&cPage=fileselsch",
  "2023" = "https://dq.cde.ca.gov/dataquest/dlfile/dlfile.aspx?cLevel=School&cYear=2022-23&cCat=EL&cPage=fileselsch",
  "2022" = "https://dq.cde.ca.gov/dataquest/dlfile/dlfile.aspx?cLevel=School&cYear=2021-22&cCat=EL&cPage=fileselsch",
  "2021" = "https://dq.cde.ca.gov/dataquest/dlfile/dlfile.aspx?cLevel=School&cYear=2020-21&cCat=EL&cPage=fileselsch",
  "2020" = "https://dq.cde.ca.gov/dataquest/dlfile/dlfile.aspx?cLevel=School&cYear=2019-20&cCat=EL&cPage=fileselsch",
  "2019" = "https://dq.cde.ca.gov/dataquest/dlfile/dlfile.aspx?cLevel=School&cYear=2018-19&cCat=EL&cPage=fileselsch"
)

# Local cache directory for downloaded raw files
cache_dir <- "data/cache"
dir.create(cache_dir, recursive = TRUE, showWarnings = FALSE)
