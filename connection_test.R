library(pins)
library(rsconnect)

# 1. Connect to the board
# Since you're already authenticated for other projects, this should
# automatically find your Connect Cloud account and connect.
my_cloud_board <- board_connect()

# 2. Write a tiny test dataset to the cloud
message("Publishing test pin...")
pin_write(
  board = my_cloud_board,
  x = mtcars, # using R's built-in car dataset
  name = "test_mtcars_data",
  type = "parquet",
  title = "My First Cloud Pin",
  description = "Testing the connection from Positron to Posit Connect Cloud"
)

# 3. Read it back down to prove it works
test_read <- pin_read(my_cloud_board, "test_mtcars_data")
head(test_read)
