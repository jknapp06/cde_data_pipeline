library(pins)
library(dplyr)
library(purrr)
library(here)

# Connect to the local Pins board
local_board <- board_folder(here("data", "pins"))

# Fetch the names of all pins on the board
all_pins <- pin_list(local_board)

# Function to read a pin and format its schema as a Markdown table
get_pin_schema <- function(pin_name) {
  df <- pin_read(local_board, pin_name)
  
  # Extract column names and their primary data type
  col_types <- map_chr(df, ~class(.x)[1])
  
  # Build the Markdown string
  paste0(
    "### `", pin_name, "`\n",
    "| Column Name | Data Type | Description/Notes |\n",
    "| :--- | :--- | :--- |\n",
    paste0("| `", names(col_types), "` | ", col_types, " |  |", collapse = "\n"),
    "\n\n"
  )
}

# Apply function to all pins and collapse into a single text block
message("Extracting schemas...")
schema_markdown <- map_chr(all_pins, get_pin_schema) |> paste(collapse = "")

# Write to file so you can easily copy and paste it into the README
writeLines(schema_markdown, here("schema_dump.md"))
message("Success! Schemas written to schema_dump.md")