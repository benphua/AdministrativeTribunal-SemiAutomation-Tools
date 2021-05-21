# 1. OVERVIEW -------------------------------------------------------------------

# Program Name: UK Judge Extractor
# Purpose: Extract Judge names from each tribunal report's "txt" data
# Last update: 26 Sep 2020

# 2. IMPORT PACKAGES -------------------------------------------------------------

library(pdftools)
library(tesseract) # for ocr
library(tidyverse)
library(lubridate)
library(writexl)
library(tictoc)

# 3. FUNCTION DEFINITION ---------------------------------------------------------

# Function that deals with a specific error scenario (see below) by returning 
# the name with the largest value in the list
which_word <- function(txt_list){
  output <- double() # prepare and output set
  
  for(name in txt_list){ # for each name
    output <- c(output, (str_count(name, "\\w+"))) # count the number of words in each list element
  }
  
  idx <- which.max(output) # returns the element with the most words
  
  txt_list[[idx]]
}

# Error Scenario:
# Program returns two names "Kennedy" "Judge Shanks" - 
# Both names are in the dictionary: Kennedy is a Judge name too but 
# Judge Shanks is the judge for this report. 
# The longer name relies on this function to deal with this error scenario.

# Unsolved Error Scenario
# "Kennedy" "Shanks" - cannot be salvaged with this program, 
# Single name Judge predictions should be reviewed by hand except Shanks

# 4. DATA PREPARATION ---------------------------------------------------------

# 4.1: Import Text Data -------------------------------------------------------

# Bring in the e6 table with the updated names on top of 2020 08 01 2246 hrs uk ir df e1 ready and consolidated judge, laymember names
e6 <- read.csv("e6.csv", header = T, stringsAsFactors = F)

# Bring in uk_df which has txt in its last column
uk_df <- read.csv("uk_df.csv", header = TRUE, stringsAsFactors = FALSE)

# Combine e3a with the txt
e_df <- cbind(e6, txt = uk_df$txt)

# Convert to a tibble
e_df <- as_tibble(e_df)

# Dates Fixing
# Original Date Column
e_df <- e_df %>%
  mutate(Date.of.Promulgation..Decision..Original = dmy(Date.of.Promulgation..Decision..Original))

# Checked Date Column (Ben: This one is a bit of a mess, the original date is usually close enough)
e_df <- e_df %>%
  mutate(Date.of.Promulgation..Decision..Check  = dmy(Date.of.Promulgation..Decision..Check))

# You only need the txt column for this extractor
txt_vector <- e_df$txt
# Ben: may need something more sophisticated if you decide to use only parts of the string of each txt


# 4.2: Tune amount of text to use from the front and back of the document -----

# Note: Adjust this function's front and back page limit to improve accuracy.

# Function that first creates two subsets containing the first bunch of pages
# then the last bunch of paragraphs
subset_combine <- function(txt, start = c(1,-500), end = c(1000,-1)) {
  # c(front set, backset), 1 is the first page, -500 is -500 from the backpage
  # 1000 is the end for the first set, -1 is the last word from the back
  subsets <- str_sub(txt, start, end)
  str_c(subsets, collapse = " ")
}

# Memory reduction is useful too
txt_vector <- map(txt_vector, ~subset_combine(.))


# 4.3: Import Judge Dictionary ------------------------------------------------

# This dictionary contains all unique ways that Judge names appear in 
# UK Info Tribunal reports to date and a unique key that consolidates all ways 
# into a single name (see file for details)

# This file has to be updated for all judge names that failed to be predicted.

# It is used twice once for the prediction and once for setting the name to 
# a single unique key.
 
# (Last Updated 10 Sep 2020 1723 Hrs)

# Import Judge dictionary as a dataframe
judge_dict <- read.csv("judge_dict.csv", stringsAsFactors = F)

judge_vector <- as.vector(judge_dict$Aka)

# Debug Point
#judge_vector


# 4. PREDICT EACH REPORT'S JUDGE'S NAME ---------------------------------------

# Search each txt for Judge entities

tic()

sparse_list <- map(txt_vector, ~str_extract(., judge_vector))
# Purrr map the txt vector with the function str_extract  

toc()

# Takes about 6 seconds entire N 2,524 reports

# Output:
# Each List index corresponds to a txt key ID
# Each inner list contains names and many NA values 
# If a Judge entity is not found then the entire txt ID will be NA

# If it can't find the pattern it returns NA as per str_extract function

# Sparse list is a list of length 2524 equivalent to 2524 txt decision reports

# Each list element contains a character vector of [x] elements where 
# [x] == the number of names in Judge Vector

# Debug Point
#sparse_list[[1995]]

# Code to prepare for dense_list transformation, 
for(row in 1:length(sparse_list)){ 
  checker <- all(is.na(sparse_list[[row]])) # Check each list element if it is all na
  if (checker == TRUE){ # if it is 
    sparse_list[[row]] <- "Failed" # then put failed, meaning Judge name was not successfully predicted
  } else {
    next 
  }
}

# Goal now is to clean each inner list and get rid of useless bits
dense_list <- map(sparse_list, ~discard(.x, is.na))
# For each list, discard all elements which are na

# Title Case all Elements 
fixed_list <- map(dense_list, str_to_title)

# Final list contains only the most frequently occurring Judge name in that txt first few words and last few words
final_list <- map(fixed_list, which_word)

# Unlist the final list
predicted_names <- unlist(final_list, recursive=F)

# Now we have a character vector of the final names
# Good place to check if the N value is OK, 2524 OK
str(predicted_names)

# Turn into a tibble for later work
name_tibble <- tibble(predicted_names)

# Rename the header for later work
name_tibble <- rename(name_tibble, Interim = predicted_names)

# Create an empty column for later work
name_tibble$Predicted <- ""

# 5. SET PREDICTION TO UNIQUE KEY----- ---------------------------------------

# This step sets each Prediction to a single name for a specific Judge

# E.g. Judge Shanks appears in his reports as Murray Shanks, Shanks, SHANKS, 
# Judge Shanks we want to consolidate all of that to a single entity "Shanks" 
# (which appears to be his preferred way of showing only his last name)

# Now that prediction is completed we can modify the judge dict for Unique Key work
judge_dict$Aka <- modify(judge_dict$Aka, str_to_title)

# Sets Prediction to Unique Key
for(name in 1:nrow(name_tibble)){
  # Extract the index if it exists, if not it will NA
  idx <- match(name_tibble$Interim[[name]], judge_dict$Aka)
  
  if (NA %in% idx == FALSE) { # i.e. there is an index value inside because a match was found
    name_tibble$Predicted[[name]] = judge_dict$Name[[idx]] # place the unique identifier key to column
  } else {
    name_tibble$Predicted[[name]] = NA # program did not find the relevant name
    # In production put "Failed" rather than NA might be less confusing 
  }
}

# Bind the predictions
e_df <- cbind(e_df, Judge.Predicted = name_tibble$Predicted)

# Check to see if the appellant's name is the same as the Judge's name
same_name <- map2_lgl(.x = e_df$Appellant, .y = e_df$Judge.Predicted, ~.x == .y)

# Compare Appellant's Name vs. Judge.Predicted row by row, same_name vector containing TRUE or FALSE
# TRUE equal same
# FALSE equal not

same_name_checker <- which(same_name)

length(same_name_checker) # OK

# 6. EVALUATE RESULTS --------------------------------------------------------

# 6.1: Evaluate Against Handcoded Dataset ------------------------------------

# Note: Code is archived for now as this code was previously run for the full dataset

# Compare Judge.Consolidated vs. Judge.Predicted row by row, new column Pred.Result containing TRUE or FALSE
# TRUE equal same
# FALSE equal not
#Pred.Result <- map2_chr(.x = e_df$Judge.Consolidated, .y = e_df$Judge.Predicted, ~.x == .y)

#Pred.Result <- tibble(Pred.Result)

#e_df <- cbind(e_df, Pred.Result = Pred.Result$Pred.Result)

# File to export to check and debug
#e_check <- e_df %>%
#  select(!txt)

# Identify misclassification rate
#e_check %>%
#  group_by(Pred.Result) %>%
#  count()

# Export check file
#write_xlsx(e_check, path = "e_check.xlsx")


# 6.2: Evaluate Entire Dataset by Hand ----------------------------------------

# See how many failed
e_check <- e_df %>%
  select(!txt)

# Export check file
write_xlsx(e_check, path = "e_check.xlsx") # Remember to rename the file before re-running!!!!