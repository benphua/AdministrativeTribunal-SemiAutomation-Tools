# PROGRAM DESCRIPTION --------------------------------------------------------
# Scrapes the main table of all cells in the UK Information Rights Tribunal Database

# Bugs
# Note that program does not provide warnings where row item has no link or link
  # address is wrong. This is dealt with at the PDF management stage.

# IMPORT LIBRARIES ------------------------------------------------------------
library(xml2)
library(rvest)
library(stringr)
library(tidyr)
library(dplyr)

# INITIALISE VARIABLES --------------------------------------------------------

# Code Suspender - to prevent overwhelming the requested server
suspender <- 5.0

# Information Rights Tribunal Base Page URL
ir_url <- "http://informationrights.decisions.tribunals.gov.uk/Public/search.aspx?Page="

# For Loop Counter, initialise at 1 to represent page 1
counter <- 1

# End of For Loop Terminator, calculates the total number of pages in the UK tribunal database at time of html call
# !!NOTE!!: Hardcoded for website design, note code and check against latest website design
pages <-
  # calls the first page of the IRD database
  read_html("http://informationrights.decisions.tribunals.gov.uk/Public/search.aspx?Page=1") %>%
  # pulls the html for "Displaying results 1 to 10 (of XXXX)" (NOTE: This may change over time)
  html_node("#contentarea div:nth-child(1)") %>%
  # extract the text from the html element
  html_text() %>%
  # extract the string next to "of<s>" (HARDCODE), ben: the stringr regex cheatsheet is useful here
  str_extract("(?<=of\\s)(\\w+)") %>%
  # turn the string to a number
  as.numeric() %>%
  # divide by 10
  `/` (10) %>%
  # round up to get the last page number of the current set of decisions
  round(digits = 0)

# Return current number of pages in the UK IR tribunal dataset
pages

# Dataframe to hold final dataset 
col.names = c("Jurisdictional area", "Case Title", "Appellant", "Respondent", "Additional Party", "Reference", "Date", "Appeal", "Link")
colClasses = c("character", "character", "character", "character", "character", "character", "Date", "character", "character")
uk_ir_df <- read.table(text = "",
                       colClasses = colClasses,
                       col.names = col.names)

# SCRAPE UK FIRST-TIER INFORMATION RIGHTS DECISION DATABASE -------------------

# Main For Loop to Create UK Tribunal Dataset
  # For each page in the UK Tribunal web portal:
for (page in 1:pages) { # *** Ben: change back to pages for full code TESTER ***
  
  # 1. PREPARE CURRENT PAGE'S URL & HTML
  # generate HTML URL based on the current page (HARDCODED)
  html_url <- paste(ir_url, page, sep = "") 
  # 'http://informationrights.decisions.tribunals.gov.uk/Public/search.aspx?Page=' + 'page'
  
  # pull current page's entire html code
  html_file <- read_html(html_url)
  
  
  # 2. EXTRACT CURRENT PAGE'S MAIN TABLE DATA (SYSTEM A AS PER MAIN THESIS)
  # Make a table of all data points less the report links
  df <-
    html_file %>% # from html object
    html_nodes("table") %>% # extract all table objects
    .[[2]] %>% # HARDCODED the data required is in the second table of the current web design
    html_table(trim = TRUE) # coerces the data into a dataframe and trims all whitespace characters/ whitespace
  
  
  # At this stage MD.1 and MD.2 already have their own columns in the above dataframe table
  
  
  # cleaning #1: remove case summary column using subset command
  df <- subset(df, select = -c(4)) # deletes column 4
  
  # cleaning #2: remove all whitespace in between text
  df[,2] <-
    df %>%
    select("Case Title and Reference") %>% # HARDCODED
    mutate(
      across(where(is.character),str_squish)
    )
  
  # wrangle #1: split case title and reference into their own columns (i.e. Separate MD.3 into its own column)
  df <-
    df %>%
    extract("Case Title and Reference", c("Case Title", "Reference"), "(.+)(?=\\s) ([\\w+/]+)")
  #(.+)(?=\\s)
  # one or more characters except \n
  # which is immediately followed by a whitespace at the end
  #[\\w+/]+ = one or more word characters followed by a / repeated one or more times
  # to capture the possibility of EA/2019/0179/A types
  
  # wrangle #2: move 'additional party' to its own column (i.e. separate MD.5 additional party names into its own column)
  df <-
    df %>%
    separate("Case Title", c("Case Title", "Additional Party"), sep = "Additional Party")
  
  # wrangle #3: keep case title but note the appellant and 1st respondent to their own columns (i.e. separate MD.4 and MD.5 first respondent name into their own columns)
  df <-
    df %>%
    separate("Case Title", c("Appellant", "Respondent"), sep = " v ", remove = FALSE)
  
  
  # 3. EXTRACT CURRENT PAGE'S DECISION PDF LINKS
  
  # Pull all links and put them into a vector of strings
  links <-
    html_file %>% # from the html object...
    html_nodes(".percent100") %>% # filter to links only based on SelectorGadget
    html_nodes("a[title$='decision']") %>% # pull all 'a' elements where the title ends with decision
    html_attr("href") # extract the text from the href section
  
  # Clean #1: put the full URL back in "../"
  links <- str_replace_all(links, "\\.\\.{1}", "http://informationrights.decisions.tribunals.gov.uk")
  # for each string in the vector
  # replace the first instance of ".." with the full URL as above, first only because ".." can appear
  # in the rest of the link due to naming convention weirdness...
  
  # Clean #2: replace all broken links with an empty string
  links <- str_replace_all(links, ".*(/)$", "")
  # Regex captures any URL that ends with / because if the link is correct it should end with .pdf only (hypothesis) 
  
  # wrangle #1: Add links to the current page's main table
  # add a vector as a column to the df for the URL
  # ref: https://www.c-sharpcorner.com/article/r-data-frame-operations-adding-rows-removing-rows-and-merging-two-data-frame/
  df$Link <- links
  
  # 4. APPEND CURRENT PAGE TO MAIN DF
  uk_ir_df <- rbind(uk_ir_df, df)
  
  # pause execution to prevent responding server overload
  Sys.sleep(suspender)
}

# Write latest database to a csv file
write.csv(uk_ir_df, "uk_ir_df_base.csv")