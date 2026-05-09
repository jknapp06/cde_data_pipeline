
### Not working ###

library(dplyr)
library(purrr)
library(rvest)
library(httr2)
library(pins)

board <- board_folder("C:/Users/JKnapp/OneDrive - Solano County Office of Education/cde_data_pipeline/data/pins")
schools_dir <- pin_read(board, "ca_schools_directory")

solano_schools <- schools_dir %>%
  filter(county_name == "Solano")

scrape_admin_email <- function(cds_code) {
  Sys.sleep(1.5)
  
  url <- paste0("https://www.cde.ca.gov/schooldirectory/details?cdscode=", cds_code)
  
  req <- request(url) %>%
    req_user_agent("SCOE Data Pipeline") %>%
    req_error(is_error = function(resp) FALSE)
  
  resp <- req_perform(req)
  
  if (resp_status(resp) != 200) {
    return(NA_character_)
  }
  
  emails <- resp_body_html(resp) %>%
    html_elements(xpath = "//th[contains(., 'Administrator')]/following-sibling::td//a[starts-with(@href, 'mailto:')]") %>%
    html_attr("href") %>%
    sub("^mailto:", "", .) %>%
    unique()
  
  if (length(emails) == 0) {
    return(NA_character_)
  }
  
  paste(emails, collapse = "; ")
}

solano_schools <- solano_schools %>%
  mutate(admin_emails = map_chr(cds, scrape_admin_email))