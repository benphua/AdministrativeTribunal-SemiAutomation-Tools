# 1. OVERVIEW -----------------------------------------------------------------

# Program Name: Tribunal Member Name Extractor for UK Information Rights First-Tier Tribunal
# Purpose: Extract Judge names from each tribunal report's "txt" data
# Last update: 26 Sep 2020

# 2. IMPORT PACKAGES ----------------------------------------------------------

library(pdftools)
library(tesseract) # for ocr
library(tidyverse)
library(lubridate)
library(writexl)
library(tictoc)

# 3. DATA PREPARATION ---------------------------------------------------------

# 3.1: Import Text Data -------------------------------------------------------

# e6 now updated with lay member consolidated names, can change this data table to the Judge one if necessary
e6 <- read.csv("e6.csv", header = T, stringsAsFactors = F)

# Bring in uk_df which has txt in its last column
uk_df <- read.csv("uk_df.csv", header = TRUE, stringsAsFactors = FALSE)

# Combine e6 with the txt
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

# 3.2: Tune amount of text to use from the front of the document --------------

# Adjust this function for front page set to improve performance. 
# Note that unlike the Judge extractor, this program only needs the front page 
# set as Tribunal members never appear at the back of the report to date reducing the code.

txt_vector <- map(txt_vector, ~str_sub(., start = 1, end = 1000))

# 3.3: Import Judge Dictionary ------------------------------------------------

# Import Lay Member dictionary as a data frame
lay_dict <- read.csv("lay_dict.csv", stringsAsFactors = F)

lay_vector <- as.vector(lay_dict$Aka)

# Debug Point
#lay_vector

# 4. PREDICT EACH REPORT'S TRIBUNAL MEMBER NAMES IF THEY WERE PRESENT ---------

# Extract the names of Lay Members from each txt into a Sparse_List

tic()
sparse_list <- map(txt_vector, ~str_extract(., lay_vector))
toc()

# Took 2.561 seconds to run

# Debug Point
#sparse_list[[3]]

# Turn Sparse_List into a Dense_List

# Code to prepare for dense_list transformation, discard requires at least one item in each list
# If not it will delete the row which is not what we want
for(row in 1:length(sparse_list)){ 
  checker <- all(is.na(sparse_list[[row]])) # Check each list element if it is all na
  if (checker == TRUE){ # if it is 
    sparse_list[[row]] <- "No Lay Members or Failed" # then put failed
  } else {
    next 
  }
}

# Debug Point
#sparse_list[[1]] # 1 and 2 were Judge only

# Goal now is to clean each inner list and get rid of useless bits
dense_list <- map(sparse_list, ~discard(.x, is.na))
# For each list, discard all elements which are na

# Title Case All Elements

fixed_list <- map(dense_list, str_to_title)

# Now that prediction is completed we can modify this column for Unique Key work
lay_dict$Aka <- modify(lay_dict$Aka, str_to_title)

# Turn all aliases of a name to the unique name key
# For each vector in fixed_list...
for (list_idx in 1:length(fixed_list)){
  # determine the length for this particular vector
  vector_length <- length(fixed_list[[list_idx]])
  
  # For each element in this vector...
  for (vector_idx in 1:vector_length){
    # extract the index where this element exists in the dictionary, if not it will NA
    idx <- match(fixed_list[[list_idx]][vector_idx], lay_dict$Aka)
    
    if (NA %in% idx == FALSE){ # i.e. there is an index value inside because a match was found
      fixed_list[[list_idx]][vector_idx] = lay_dict$Name[[idx]] # replace value with the unique ID name
    } else {
      fixed_list[[list_idx]][vector_idx] = "No Lay Members or Failed!" # Has a exclamation pt to distinguish   
      # from previous code
    }
  }
}

# Remove any duplicates

# Removes duplicates from each vector in the list
for (list_idx in 1:length(fixed_list)){
  fixed_list[[list_idx]] <- unique(fixed_list[[list_idx]])
}

# Check each vector that has more than two names predicted
# Since most if not all tribunals have only two lay members present
checker <- map_lgl(fixed_list, ~length(.x) > 2) 
# Note the lgl postfix
counter <- which(checker) # tells us how many TRUE logicals are in the checker
length(counter) # see how bad the situation is

counter # return the index values of the items that should be manually checked

# Check when there are three values by hand
fixed_list[[553]]

# Checked, Michael Jones was not on the tribunal, remove his name from this element
fixed_list[[553]] <- fixed_list[[553]][fixed_list[[553]] != "Michael Jones"]

# Check if fixed
fixed_list[[553]]

# 5. EVALUATE RESULTS --------------------------------------------------------

# Prepare data to be evaluated in excel

# create an empty dataframe of same length as original input, here is N = 2524
# one column for first name, another for second name, 
# and a third for error capture (i.e. three names or more) Ben: the code should take [3:] and put the lot 
# in this cell

# tibble with 1 column
name_tibble <- tibble(1:length(fixed_list))

# col 1
name_tibble$Pred_Lay_1 <- ""

# col 2
name_tibble$Pred_Lay_2 <- ""

# col 3
name_tibble$Error <- ""

# delete the first column
name_tibble[,1] = NULL

# Pass names to the dataframe properly

# For each vector in the fixed_list and each row in the name_tibble data frame
for(i in 1:length(fixed_list)){
  # determine the length for this particular vector
  vector_length <- length(fixed_list[[i]])
  
  # For each element in this vector
  for(vector_idx in 1:vector_length){
    name_tibble[i,vector_idx] <- fixed_list[[i]][vector_idx]
  }
}

# Error Check
allmisscols <- sapply(name_tibble, function(x) all(x == '' ))

# If TRUE then entire column is empty which is what we want
allmisscols

# Delete the Error Column
name_tibble[,3] = NULL

# Bind the predictions to the input dataframe for review
e_df <- cbind(e_df, Lay.Member.1.Pred = name_tibble$Pred_Lay_1)
e_df <- cbind(e_df, Lay.Member.2.Pred = name_tibble$Pred_Lay_2)

# Check to see if appellant name is same as Lay Member 1 and 2
same_l_name_1 <- map2_lgl(.x = e_df$Appellant, .y = e_df$Pred_Lay_1, ~.x == .y)
same_l_name_2 <- map2_lgl(.x = e_df$Appellant, .y = e_df$Pred_Lay_2, ~.x == .y)
same_l_name_1_checker <- which(same_l_name_1)
same_l_name_2_checker <- which(same_l_name_2)

length(same_l_name_1_checker) # OK
length(same_l_name_2_checker) # OK

e_check <- e_df %>%
  select(!txt)

# Export check file
write_xlsx(e_check, path = "lay_check.xlsx") # Remember to rename the file before re-running!!!!