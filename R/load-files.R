# load-files.R
# Core functions to download, cache, and read raw source files.
# Simplified to strict file caching (no dated versions).

library(dplyr)
library(vroom)
library(openxlsx)
library(glue)
library(janitor)
library(fs)
library(here)

options(
  scipen = 999,
  timeout = max(300, getOption("timeout")) # Force R to wait up to 5 minutes
)

# Ensure cache dir exists
default_cache_dir <- here("data", "cache")
dir_create(default_cache_dir, recurse = TRUE)

# 1. BASE DOWNLOADER ---------------------------------------------------------
safe_download_file <- function(url, dest_file, max_attempts = 3) {
  attempt <- 1
  success <- FALSE

  while (attempt <= max_attempts && !success) {
    if (attempt > 1) {
      message(
        "Retrying download (Attempt ",
        attempt,
        " of ",
        max_attempts,
        ") for: ",
        basename(url)
      )
      Sys.sleep(5)
    }

    dl_status <- tryCatch(
      {
        suppressWarnings(download.file(
          url,
          dest_file,
          mode = "wb",
          quiet = TRUE
        ))
        TRUE
      },
      error = function(e) FALSE,
      warning = function(w) FALSE
    )

    if (dl_status && file.exists(dest_file) && file.info(dest_file)$size > 0) {
      success <- TRUE
    } else {
      if (file.exists(dest_file)) unlink(dest_file)
    }
    attempt <- attempt + 1
  }

  if (!success) {
    stop("Download failed entirely after ", max_attempts, " attempts: ", url)
  }
  invisible(dest_file)
}

# 2. CACHE MANAGER -----------------------------------------------------------
# Checks if we already have the file. If not (or if force=TRUE), downloads it.
get_cached_file <- function(url, force = FALSE) {
  # Strip http(s):// and query parameters (?rid=123)
  safe_url <- gsub("^https?://", "", url)
  safe_url <- sub("\\?.*$", "", safe_url)

  # Replace all slashes and special characters with underscores to create a unique file path
  # e.g., caaspp.org/elpac/StudentGroups.zip becomes caaspp.org_elpac_StudentGroups.zip
  clean_name <- gsub("[^A-Za-z0-9.]", "_", safe_url)

  dest_file <- file.path(default_cache_dir, clean_name)

  if (file.exists(dest_file) && !force) {
    return(dest_file)
  }

  message("Downloading: ", basename(url))
  safe_download_file(url, dest_file)
  return(dest_file)
}


# 3. FILE READERS ------------------------------------------------------------

# Replaces load_assistance_xlsx, load_essa_xlsx, and teacher assignments
load_excel_from_cache <- function(
  url,
  sheet = 1,
  start_row = 1,
  force = FALSE
) {
  dest_file <- get_cached_file(url, force = force)
  message("Reading Excel file: ", basename(dest_file))

  tryCatch(
    {
      openxlsx::read.xlsx(dest_file, sheet = sheet, startRow = start_row) |>
        as_tibble() |>
        janitor::clean_names()
    },
    error = function(e) {
      stop(glue("Failed to read Excel file {dest_file}: {e$message}"))
    }
  )
}

# Handles ZIP archives (like CAASPP)
load_zip_from_cache <- function(
  zip_url,
  file_name,
  delim = "^", # Changed from deliminator to standard delim
  force = FALSE,
  col_names = TRUE,
  ... # Added ... to pass any other readr arguments through
) {
  dest_zip <- get_cached_file(zip_url, force = force)
  message(glue::glue("Reading {file_name} from {basename(dest_zip)}..."))

  tryCatch(
    {
      readr::read_delim(
        unz(dest_zip, file_name),
        delim = delim,
        col_names = col_names,
        show_col_types = FALSE,
        ... # Passing extra args directly to read_delim
      ) |>
        janitor::clean_names()
    },
    error = function(e) {
      stop(glue::glue(
        "Failed to read {file_name} from {dest_zip}: {e$message}"
      ))
    }
  )
}

# General purpose CSV/TXT reader (replaces safe_cde_read)
# The ... allows us to pass specific vroom arguments like delim = "\t"
load_txt_from_cache <- function(url, force = FALSE, ...) {
  dest_file <- get_cached_file(url, force = force)
  vroom::vroom(dest_file, show_col_types = FALSE, ...) |>
    janitor::clean_names()
}


# 4. DASHBOARD SPECIFIC HELPERS ----------------------------------------------

load_dashboard_file_from_cache <- function(local_path, d_indicator, priority) {
  col_types <- switch(
    d_indicator,
    "ELA" = cols(
      coe_flag = col_character(),
      pairshare_method = col_character(),
      .default = col_guess()
    ),
    "Math" = cols(
      coe_flag = col_character(),
      pairshare_method = col_character(),
      .default = col_guess()
    ),
    "ELPI" = cols(coe_flag = col_character(), .default = col_guess()),
    "absenteeism" = cols(
      coe_flag = col_character(),
      certifyflag = col_character(),
      dataerrorflag = col_character(),
      .default = col_guess()
    ),
    "suspension" = cols(
      coe_flag = col_character(),
      certifyflag = col_character(),
      dataerrorflag = col_character(),
      .default = col_guess()
    ),
    cols(.default = col_guess())
  )

  vroom::vroom(local_path, col_types = col_types, progress = FALSE) |>
    clean_names() |>
    mutate(indicator = d_indicator, priority = priority) |>
    rename(
      reporting_year = dplyr::any_of(c("reportingyear", "reporting_year")),
      change_level = dplyr::any_of(c("changelevel", "change_level"))
    )
}

# Orchestrates downloading and binding the entire dashboard set
download_and_load_dashboard_set <- function(dashboard_files, force = FALSE) {
  dashboard_files |>
    rowwise() |>
    mutate(
      local_path = get_cached_file(url, force = force),
      data = list(load_dashboard_file_from_cache(
        local_path,
        indicator,
        priority
      ))
    ) |>
    ungroup() |>
    pull(data) |>
    bind_rows()
}
