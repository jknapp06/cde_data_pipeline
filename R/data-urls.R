# data-urls.R
# Central place for all source URLs and small constants.
# Load this first in refresh.R

# ---- School Info URL ----
pubschls_url <- "https://www.cde.ca.gov/schooldirectory/report?rid=dl1&tp=txt"
cde_directory_url <- "https://www.cde.ca.gov/schooldirectory/report?rid=dl1&tp=txt"

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

# ---- Assistance Files ----
assistance_files <- tibble::tribble(
  ~name                   , ~url                                                                    , ~sheet , ~start_row ,
  "assistance_25"         , "https://www.cde.ca.gov/fg/aa/lc/documents/assistancestatus25.xlsx"     ,      4 ,          6 ,
  "assistance_25_charter" , "https://www.cde.ca.gov/fg/aa/lc/documents/charterassistance25.xlsx"    ,      4 ,          6 ,
  "assistance_24"         , "https://www.cde.ca.gov/fg/aa/lc/documents/assistancestatus24.xlsx"     ,      4 ,          6 ,
  "assistance_24_charter" , "https://www.cde.ca.gov/fg/aa/lc/documents/charterassistance24.xlsx"    ,      4 ,          6 ,
  "assistance_23"         , "https://www.cde.ca.gov/fg/aa/lc/documents/assistancestatus23.xlsx"     ,      4 ,          6 ,
  "assistance_23_charter" , "https://www.cde.ca.gov/fg/aa/lc/documents/charterassistance23.xlsx"    ,      4 ,          6 ,
  "assistance_22"         , "https://www.cde.ca.gov/fg/aa/lc/documents/assistancestatus22.xlsx"     ,      4 ,          6 ,
  "assistance_19"         , "https://www.cde.ca.gov/fg/aa/lc/documents/assistancestatus19-rev.xlsx" ,      4 ,          6 ,
  "assistance_18"         , "https://www.cde.ca.gov/fg/aa/lc/documents/assistancestatus18.xlsx"     ,      1 ,          5 ,
  "assistance_17"         , "https://www.cde.ca.gov/fg/aa/lc/documents/assistancestatus2017.xlsx"   ,      4 ,          5
)

# ---- ESSA Files ----
essa_files <- tibble::tribble(
  ~name    , ~url                                                                                                                    , ~sheet , ~start_row ,
  "essa25" , "https://www.cde.ca.gov/sp/sw/t1/documents/essaassistance25.xlsx"                                                       ,      2 ,          3 ,
  "essa24" , "https://www.cde.ca.gov/sp/sw/t1/documents/essaassistance24.xlsx"                                                       ,      2 ,          3 ,
  "essa23" , "https://www.cde.ca.gov/sp/sw/t1/documents/essaassistance23.xlsx"                                                       ,      2 ,          3 ,
  "essa22" , "https://wayback.archive-it.org/21145/20240221130719/https%3A//www.cde.ca.gov/sp/sw/t1/documents/essaassistance22.xlsx" ,      2 ,          3 ,
  "essa21" , "https://wayback.archive-it.org/21145/20240221130719/https%3A//www.cde.ca.gov/sp/sw/t1/documents/essaassistance21.xlsx" ,      1 ,          3 ,
  "essa19" , "https://wayback.archive-it.org/21145/20240221130719/https%3A//www.cde.ca.gov/sp/sw/t1/documents/essaassistance19.xlsx" ,      1 ,          3
)

# Teacher credentialing data
teacher_assignments_url <- "https://www3.cde.ca.gov/demo-downloads/tamo/tamo2324.txt"

# Growth Model Data

growth_url <- "https://www3.cde.ca.gov/researchfiles/cadashboard/growthmodeldownload2025.txt"

# ---- CAASPP URLs ----
caaspp_entities_url <- "https://caaspp-elpac-preview.ets.org/caaspp/researchfiles/sb_ca2025entities_csv.zip"
caaspp_entities_txt <- "sb_ca2025entities_csv.txt"
caaspp_student_groups_url <- "https://caaspp-elpac.ets.org/caaspp/researchfiles/StudentGroups.zip"
caaspp_student_groups_txt <- "StudentGroups.txt"

# ---- Statewide CAASPP Files ----
caaspp_files <- tibble::tribble(
  ~year , ~url                                                                         , ~txt_file                  ,
   2025 , "https://caaspp-elpac.ets.org/caaspp/researchfiles/sb_ca2025_all_csv_v1.zip" , "sb_ca2025_all_csv_v1.txt" ,
   2024 , "https://caaspp-elpac.ets.org/caaspp/researchfiles/sb_ca2024_all_csv_v1.zip" , "sb_ca2024_all_csv_v1.txt" ,
   2023 , "https://caaspp-elpac.ets.org/caaspp/researchfiles/sb_ca2023_all_csv_v1.zip" , "sb_ca2023_all_csv_v1.txt" ,
   2022 , "https://caaspp-elpac.ets.org/caaspp/researchfiles/sb_ca2022_all_csv_v1.zip" , "sb_ca2022_all_csv_v1.txt" ,
   2021 , "https://caaspp-elpac.ets.org/caaspp/researchfiles/sb_ca2021_all_csv_v2.zip" , "sb_ca2021_all_csv_v2.txt" ,
   2019 , "https://caaspp-elpac.ets.org/caaspp/researchfiles/sb_ca2019_all_csv_v4.zip" , "sb_ca2019_all_csv_v4.txt"
)


elpac_student_groups_url <- "https://caaspp-elpac.ets.org/elpac/researchfiles/StudentGroups.zip"

# --- Census Day Enrollment Files ---
census_files <- tibble::tribble(
  ~year , ~url                                                                ,
   2025 , "https://www3.cde.ca.gov/demo-downloads/census/cdenroll2526.txt"    ,
   2024 , "https://www3.cde.ca.gov/demo-downloads/census/cdenroll2425.txt"    ,
   2023 , "https://www3.cde.ca.gov/demo-downloads/census/cdenroll2324-v2.txt"
)

old_census_files <- tibble::tribble(
  ~year_group , ~url                                                             ,
  "2020-22"   , "https://www3.cde.ca.gov/demo-downloads/enrsch/enr202022-v2.txt" ,
  "2017-19"   , "https://www3.cde.ca.gov/demo-downloads/enrsch/enr201719-v2.txt"
)

# --- Cumulative Enrollment Files ---
cumulative_files <- tibble::tribble(
  ~year , ~url                                                        ,
   2025 , "https://www3.cde.ca.gov/demo-downloads/ce/cenroll2425.txt" ,
   2024 , "https://www3.cde.ca.gov/demo-downloads/ce/cenroll2324.txt" ,
   2023 , "https://www3.cde.ca.gov/demo-downloads/ce/cenroll2223.txt" ,
   2022 , "https://www3.cde.ca.gov/demo-downloads/ce/cenroll2122.txt" ,
   2021 , "https://www3.cde.ca.gov/demo-downloads/ce/cenroll2021.txt" ,
   2020 , "https://www3.cde.ca.gov/demo-downloads/ce/cenroll1920.txt"
)

# --- Dashboard Enrollment Files ---
dash_files <- tibble::tribble(
  ~year , ~url                                                                                  ,
   2025 , "https://www3.cde.ca.gov/researchfiles/cadashboard/censusenrollratesdownload2025.txt" ,
   2024 , "https://www3.cde.ca.gov/researchfiles/cadashboard/censusenrollratesdownload2024.txt" ,
   2023 , "https://www3.cde.ca.gov/researchfiles/cadashboard/censusenrollratesdownload2023.txt" ,
   2022 , "https://www3.cde.ca.gov/researchfiles/cadashboard/censusenrollratesdownload2022.txt" ,
   2021 , "https://www3.cde.ca.gov/researchfiles/cadashboard/censusenrollratesdownload2021.txt" ,
   2020 , "https://www3.cde.ca.gov/researchfiles/cadashboard/censusenrollratesdownload2020.txt" ,
   2019 , "https://www3.cde.ca.gov/researchfiles/cadashboard/censusenrollratesdownload2019.txt" ,
   2018 , "https://www3.cde.ca.gov/researchfiles/cadashboard/censusenrollratesdownload2018.txt"
)

# --- Unduplicated Pupil Count (UPC) Files ---
upc_files <- tibble::tribble(
  ~year , ~url                                                       , ~sheet , ~start_row ,
   2025 , "https://www.cde.ca.gov/ds/ad/documents/cupc2425-k12.xlsx" ,      2 ,          2 ,
   2024 , "https://www.cde.ca.gov/ds/ad/documents/cupc2324-k12.xlsx" ,      2 ,          2 ,
   2023 , "https://www.cde.ca.gov/ds/ad/documents/cupc2223-k12.xlsx" ,      2 ,          2 ,
   2022 , "https://www.cde.ca.gov/ds/ad/documents/cupc2122-k12.xlsx" ,      2 ,          2 ,
   2021 , "https://www.cde.ca.gov/ds/ad/documents/cupc2021-k12.xlsx" ,      2 ,          2 ,
   2020 , "https://www.cde.ca.gov/ds/ad/documents/cupc1920-k12.xlsx" ,      2 ,          2
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
  # "2026" = "https://www.cde.ca.gov/ds/ad/documents/frpm2526.xlsx",
  "2025" = "https://www.cde.ca.gov/ds/ad/documents/frpm2425.xlsx",
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

# --- English Learner (ELAS/LTEL/At-Risk) URLs ---
# This is the dataset your RMarkdown report relies on!
ltel_urls <- c(
  "2025" = "https://dq.cde.ca.gov/dataquest/longtermel/lteldnld.aspx?year=2024-25",
  "2024" = "https://dq.cde.ca.gov/dataquest/longtermel/lteldnld.aspx?year=2023-24",
  "2023" = "https://dq.cde.ca.gov/dataquest/longtermel/lteldnld.aspx?year=2022-23",
  "2022" = "https://dq.cde.ca.gov/dataquest/longtermel/lteldnld.aspx?year=2021-22",
  "2021" = "https://dq.cde.ca.gov/dataquest/longtermel/lteldnld.aspx?year=2020-21",
  "2020" = "https://dq.cde.ca.gov/dataquest/longtermel/lteldnld.aspx?year=2019-20",
  "2019" = "https://dq.cde.ca.gov/dataquest/longtermel/lteldnld.aspx?year=2018-19"
)

# --- FEP (Fluent-English-Proficient) URLs ---
fep_urls <- c(
  "2025" = "https://dq.cde.ca.gov/dataquest/dlfile/dlfile.aspx?cLevel=School&cYear=2024-25&cCat=FEP&cPage=filesfepsch",
  "2024" = "https://dq.cde.ca.gov/dataquest/dlfile/dlfile.aspx?cLevel=School&cYear=2023-24&cCat=FEP&cPage=filesfepsch",
  "2023" = "https://dq.cde.ca.gov/dataquest/dlfile/dlfile.aspx?cLevel=School&cYear=2022-23&cCat=FEP&cPage=filesfepsch",
  "2022" = "https://dq.cde.ca.gov/dataquest/dlfile/dlfile.aspx?cLevel=School&cYear=2021-22&cCat=FEP&cPage=filesfepsch",
  "2021" = "https://dq.cde.ca.gov/dataquest/dlfile/dlfile.aspx?cLevel=School&cYear=2020-21&cCat=FEP&cPage=filesfepsch",
  "2020" = "https://dq.cde.ca.gov/dataquest/dlfile/dlfile.aspx?cLevel=School&cYear=2019-20&cCat=FEP&cPage=filesfepsch",
  "2019" = "https://dq.cde.ca.gov/dataquest/dlfile/dlfile.aspx?cLevel=School&cYear=2018-19&cCat=FEP&cPage=filesfepsch"
)

# --- Reclassification URLs ---
reclass_urls <- c(
  "2025" = "https://dq.cde.ca.gov/dataquest/dlfile/dlfile.aspx?cLevel=School&cYear=2024-25&cCat=Reclass&cPage=filesreclass",
  "2024" = "https://dq.cde.ca.gov/dataquest/dlfile/dlfile.aspx?cLevel=School&cYear=2023-24&cCat=Reclass&cPage=filesreclass",
  "2023" = "https://dq.cde.ca.gov/dataquest/dlfile/dlfile.aspx?cLevel=School&cYear=2022-23&cCat=Reclass&cPage=filesreclass",
  "2022" = "https://dq.cde.ca.gov/dataquest/dlfile/dlfile.aspx?cLevel=School&cYear=2021-22&cCat=Reclass&cPage=filesreclass",
  "2021" = "https://dq.cde.ca.gov/dataquest/dlfile/dlfile.aspx?cLevel=School&cYear=2020-21&cCat=Reclass&cPage=filesreclass",
  "2020" = "https://dq.cde.ca.gov/dataquest/dlfile/dlfile.aspx?cLevel=School&cYear=2019-20&cCat=Reclass&cPage=filesreclass",
  "2019" = "https://dq.cde.ca.gov/dataquest/dlfile/dlfile.aspx?cLevel=School&cYear=2018-19&cCat=Reclass&cPage=filesreclass"
)

# ---- CAST Files ----
cast_files <- tibble::tribble(
  ~year , ~url                                                                           , ~txt_file                    ,
   2025 , "https://caaspp-elpac.ets.org/caaspp/researchfiles/cast_ca2025_all_csv_v1.zip" , "cast_ca2025_all_csv_v1.txt" ,
   2024 , "https://caaspp-elpac.ets.org/caaspp/researchfiles/cast_ca2024_all_csv_v1.zip" , "cast_ca2024_all_csv_v1.txt" ,
   2023 , "https://caaspp-elpac.ets.org/caaspp/researchfiles/cast_ca2023_all_csv_v1.zip" , "cast_ca2023_all_csv_v1.txt" ,
   2022 , "https://caaspp-elpac.ets.org/caaspp/researchfiles/cast_ca2022_all_csv_v1.zip" , "cast_ca2022_all_csv_v1.txt" ,
   2021 , "https://caaspp-elpac.ets.org/caaspp/researchfiles/cast_ca2021_all_csv_v2.zip" , "cast_ca2021_all_csv_v2.txt" # Notice the v2 is cleanly handled here!
)

# ---- Initial ELPAC Files ----
elpac_initial_files <- tibble::tribble(
  ~year , ~url                                                                           , ~txt_file                     , ~has_header ,
   2025 , "https://caaspp-elpac.ets.org/elpac/researchfiles/ia_elpac2025_all_csv_v1.zip" , "ia_elpac2025_all_csv_v1.txt" , TRUE        ,
   2024 , "https://caaspp-elpac.ets.org/elpac/researchfiles/ia_elpac2024_all_csv_v1.zip" , "ia_elpac2024_all_csv_v1.txt" , TRUE        ,
   2023 , "https://caaspp-elpac.ets.org/elpac/researchfiles/ia_elpac2023_all_csv_v1.zip" , "ia_elpac2023_all_csv_v1.txt" , TRUE        ,
   2022 , "https://caaspp-elpac.ets.org/elpac/researchfiles/ia_elpac2022_all_csv_v1.zip" , "ia_elpac2022_all_csv_v1.txt" , TRUE        ,
   2021 , "https://caaspp-elpac.ets.org/elpac/researchfiles/ia_elpac2021_all_csv_v1.zip" , "ia_elpac2021_all_csv_v1.txt" , TRUE        ,
   2020 , "https://caaspp-elpac.ets.org/elpac/researchfiles/ia_elpac2020_all_csv_v1.zip" , "ia_elpac2020_all_csv_v1.txt" , FALSE
)

# ---- Summative ELPAC Files ----
elpac_summative_files <- tibble::tribble(
  ~year , ~url                                                                           , ~txt_file                     ,
   2025 , "https://caaspp-elpac.ets.org/elpac/researchfiles/sa_elpac2025_all_csv_v1.zip" , "sa_elpac2025_all_csv_v1.txt" ,
   2024 , "https://caaspp-elpac.ets.org/elpac/researchfiles/sa_elpac2024_all_csv_v1.zip" , "sa_elpac2024_all_csv_v1.txt" ,
   2023 , "https://caaspp-elpac.ets.org/elpac/researchfiles/sa_elpac2023_all_csv_v1.zip" , "sa_elpac2023_all_csv_v1.txt" ,
   2022 , "https://caaspp-elpac.ets.org/elpac/researchfiles/sa_elpac2022_all_csv_v1.zip" , "sa_elpac2022_all_csv_v1.txt" ,
   2021 , "https://caaspp-elpac.ets.org/elpac/researchfiles/sa_elpac2021_all_csv_v1.zip" , "sa_elpac2021_all_csv_v1.txt" ,
   2019 , "https://caaspp-elpac.ets.org/elpac/researchfiles/sa_elpac2019_all_csv_v2.zip" , "sa_elpac2019_all_csv_v2.txt" # Handles the v2 here
)

elpac_student_groups_url <- "https://caaspp-elpac.ets.org/elpac/researchfiles/StudentGroups.zip"

# ---- Homeless Enrollment Files ----
homeless_files <- tibble::tribble(
  ~academic_year , ~url                                                          ,
  # "2025-26"      , "https://www3.cde.ca.gov/demo-downloads/homeless/hse2526.txt" ,
  "2024-25"      , "https://www3.cde.ca.gov/demo-downloads/homeless/hse2425.txt" ,
  "2023-24"      , "https://www3.cde.ca.gov/demo-downloads/homeless/hse2324.txt" ,
  "2022-23"      , "https://www3.cde.ca.gov/demo-downloads/homeless/hse2223.txt" ,
  "2021-22"      , "https://www3.cde.ca.gov/demo-downloads/homeless/hse2122.txt" ,
  "2020-21"      , "https://www3.cde.ca.gov/demo-downloads/homeless/hse2021.txt" ,
  "2019-20"      , "https://www3.cde.ca.gov/demo-downloads/homeless/hse1920.txt"
)
