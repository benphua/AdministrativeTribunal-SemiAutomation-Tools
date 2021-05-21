# DESCRIPTION -----------------------------------------------------------------

# Program downloads PDFs of UK Information Rights Decisions 
# then converts them to text based on the database structure of the csv file 
# outputted by uk_ir_website_scrapper.R.
# i.e. the row and column IDs from that program affect this program.

# IMPORT PACKAGES -------------------------------------------------------------
library(pdftools) # Primary tool for PDF to text conversion
  # Note: PDF Tools requires Poppler to be installed 
  # See link for installation guide: https://ropensci.org/blog/2016/03/01/pdftools-and-jeroen/
library(tidyverse)
library(tesseract) # for converting PDF OCRs to text

# DOWNLOADER PROGRAM ----------------------------------------------------------
# Import UK IR decision database
df <- read.csv("data/2020 07 17 1545 hrs - uk_ir_df.csv", stringsAsFactors = F)

# pull all URLs for each Decision PDF
url_list <- df[,24]

# Waiting variable between iterations so as to not overwhelm the PDF holding server
suspender <- 2.0

# counter for naming the files
count = 0 

# returns a folder of pdfs from 1 to 2,527
  # note!: a broken link kills the loop (happened 11 times)
for (url in url_list) {
  count = count + 1
  download.file(url, destfile = str_c("pdf/",count, ".pdf")) # shape ( pdf/1.pdf )
  Sys.sleep(suspender) # slows the code down
}

# PDF TO TEXT PROGRAM ----------------------------------------------------------

# Create an empty dataframe to hold the final dataset
  # will contain ID and vector of strings

col.names = c("ID", "txt")
colClasses = c("numeric", "character")

text_df <- read.table(text = "",
                      colClasses = colClasses,
                      col.names = col.names)

# Initialise Variables

# relative path variable (Note: folder here must be updated)
pdf_path_1 <- "pdf_core/"

# iterator constraints
starting_file <- 1

# PDF files from 1 to 2,524
no_of_files <- 2524

# Primary Program: Converts each PDF to text
# Loop, for every file in pdf_path_1:
for (file in starting_file:no_of_files) {
  # create the filename as a string for this iteration of the loop
  file_name <- paste(pdf_path_1, file, ".pdf", sep = "")
  
  # create a vector of strings for that file
  txt <- pdf_text(file_name)  
  
  # remove whitespace before and after
  txt <- str_trim(txt, side = "both")
  
  # remove whitespace within
  txt <- str_squish(txt)
  
  # concatenate the vector of strings
  txt <- paste(txt, sep = "", collapse = "")
  
  # create an interim dataframe with the iteration as the ID and the vector of strings in the second column
  df <- data.frame(file, txt, stringsAsFactors = FALSE)
  # make sure you use strings as factors = false
  
  # append to the end of the main dataframe
  text_df <- rbind(text_df, df)
}

# Check files (if needed)
#write.csv(text_df, "data/text_df.csv", row.names = FALSE)


# OCR PDF TO TEXT PROGRAM -----------------------------------------------------

# Resolve any OCR Files
## Any blank rows (i.e. no text string) assumed to be scanned PDFs requiring
## OCR technology to resolve.

# create an empty dataframe to hold the OCR dataset
col.names = c("ID", "txt")
colClasses = c("numeric", "character")

ocr_df <- read.table(text = "",
                     colClasses = colClasses,
                     col.names = col.names)

# return vector of IDs where the second column value is blank, these will require OCR
fix <- which(text_df$txt == "")
# Will contain a list of indices where the txt value is nothing

# Loop to extract text from PDFs that need OCR
# for each file in the fix list
for (file in fix) {
  # create the file name as a string for this iteration of the loop
  file_name <- paste(pdf_path_1, file, ".pdf", sep = "")
  
  # create a vector of strings for that file
  txt <- pdf_ocr_text(file_name) 
  
  # remove whitespace before and after
  txt <- str_trim(txt, side = "both")
  
  # remove whitespace within
  txt <- str_squish(txt)
  
  # concatenate the vector of strings
  txt <- paste(txt, sep = "", collapse = "")
  
  # create an interim dataframe with the iteration as the ID and the vector of strings in the second column
  df <- data.frame(file, txt, stringsAsFactors = FALSE)
  # make sure you use strings as factors = false
  
  # append to the end of the vector
  ocr_df <- rbind(ocr_df, df)
}

# perform a full join with the main dataframe for first part of substitution
full_df <- full_join(text_df, ocr_df, by = "file")

# Fill empty txt column as needed
full_df$txt.x <- ifelse(full_df$txt.x == "", full_df$txt.y, full_df$txt.x)

# Delete the unneeded column
full_df <- subset(full_df, select = -c(txt.y))

# Rename the txt.x column
full_df <- 
  full_df %>%
  rename(txt = txt.x)

# Ensure no empty cells
which(full_df$txt == "")

# Check files
#write.csv(full_df, "data/full_df.csv", row.names = FALSE)

# FINALISE DATASET -----------------------------------------------------

# Import the dataset with all the class values
main_df <- read.csv("data/2020 08 01 2246 hrs - uk_ir_df - E1 Ready.csv", stringsAsFactors = FALSE)

# just need to append a column from full_df onto the main_df
combined_df <- cbind(main_df, txt = full_df$txt)

# Write combined dataset to file
write.csv(combined_df, "data/2020 08 06 1615 hrs - uk_ir_df.csv", row.names = FALSE)