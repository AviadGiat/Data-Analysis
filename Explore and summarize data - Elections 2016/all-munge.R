####################################################################
##              2016 Presidential Campaign Finance                ##
##                       Data Wrangling                           ##
####################################################################


## WORKING DIRECTORY
getwd()
setwd('EDA/Final Project/2016-all-candidates')



####################################################################
##                               LIBRARIES                        ##
####################################################################

library(ggplot2)
library(gridExtra)
library(plyr)
library(dplyr)
library(tidyr)  
library(csv)
library(data.table)
library(scales)
library(gender)
library(reshape2)
library(sqldf)
library(lubridate)
library(openintro)



####################################################################
##                              SOURCES                           ##
####################################################################

# https://classic.fec.gov/disclosurep/PDownload.do
# Dataset used = Contributor Data Download (ALL)
# https://cran.r-project.org/web/packages/gender/vignettes/predicting-gender.html



####################################################################
##                         UPLOAD THE DATA                        ##
####################################################################

# READ THE CSV FILE
finance <- fread("all-original.csv") # Local file with the financeial
# Uploading the 1.42 GB file to RStudio made it add an extra column
# to the dataset and push all the column names one slot forward.
## TUNE THE VARIABLE NAMES
# Rename the columns and remove the last column.
names(finance)[1:19] <- c("cmte_id", "cand_id", "candidate", 
                          "contributor", "city", "state",
                          "zipcode", "employer", 
                          "occupation", "amount", 
                          "date", "receipt_desc", 
                          "memo_cd", "memo_text", "form_tp",
                          "file_num", "tran_id", "election_tp", 
                          "nothing")
finance$nothing <- NULL
# Now, that the dataset is set up correctly, 
# I can start inspecting and munging it.



####################################################################
##                          INSPECT THE DATA                      ##
####################################################################

# dim(finance) # Find the dimentions of the matrix
# class(finance) # Find the class for the dataset
# names(finance) # Find the names of the variables in the dataset
# str(finance) # Find the structure of the variables
# summary(finance) # Statistics for the columns

## VARIABLE MAPPING
# --------------------------------------------------------------- 
# "cand_id" - candidate ID
# "candidate" - Candidate name
# "contributor" - Contributor name
# "city" - Contributor city
# "state" - Contributor state
# "zipcode" - Contributor zipcode
# "employer" - Contributor employer
# "occupation" - Contributor occupation
# "amount" - Amount contributed
# "date" - Contribution transaction date
# "election_tp" - Election type (General or Primaries)
# "party" - The political party of the candidate
# "gender" - The contributor's gender
# ---------------------------------------------------------------

# Note about states abbreviations (AE, AP and AA)
# Overseas military addresses must contain the APO or FPO designation 
# along with a two-character "state" abbreviation of AE, AP, or AA and 
# the ZIP Code or ZIP+4 Code. AE is used for armed forces in Europe, 
# the Middle East, Africa, and Canada; AP is for the Pacific; and AA 
# is the Americas excluding Canada.

# Note about addressess with DPO, APO and FPO
# If you are shipping to a military base or diplomatic location, you'll
# be using an APO, FPO or DPO address. ... APO stands for Army Post 
# Office and is associated with Army or Air Force installations. 
# FPO stands for Fleet Post Office and is associated with Navy 
# installations and ships.



####################################################################
##                       wrangle the data                         ##
####################################################################

###############################################
## REMOVE SOME COLUMNS. REMOVE ROWS WITH (-) ##
###############################################

# Remove columns that I will not use for this project
finance <- dplyr::select(finance, -c("cmte_id", "file_num", 
                                     "form_tp", "memo_text", 
                                     "memo_cd", "receipt_desc"))
# From 18 columns we went down to 11 columns.



###############################################
##          REMOVE NEGATIVE NUMBERS          ##
###############################################

# Remove records that have minus (-) in the contributed amount
# table(finance$amount < 0)
finance <- finance[!(finance$amount <= 0), ]
# table(finance$amount < 0)
# This did not changed the median. The mean changed from 126 to 134.
# 7,340,715 observations remained in the dataset, while 99,312 
# were omitted.



###########################################
##           ELECTION TYPES              ##
###########################################

# Narrowing the records to only 2016 elections
# unique(finance$election_tp)
finance <- subset(finance, election_tp == 'G2016' | election_tp == 'P2016')
# unique(finance$election_tp)
# 14,983 records were ommited and we are now on 7,325,732 rows.



###########################################
##             CANDIDATE                 ##
###########################################

## VARIABLE NAME CHANGE
# Change the names of the candidates
# unique(finance$candidate)
finance$candidate <- 
  mapvalues(finance$candidate,
            from=c("Sanders, Bernard","Clinton, Hillary Rodham",
                   "Trump, Donald J.", "Cruz, Rafael Edward 'Ted'",
                   "Paul, Rand", "Carson, Benjamin S.", "Bush, Jeb",
                   "Rubio, Marco", "Santorum, Richard J.",
                   "Kasich, John R.", "Stein, Jill", "Fiorina, Carly",
                   "O'Malley, Martin Joseph", "Huckabee, Mike",
                   "Johnson, Gary", "Perry, James R. (Rick)",
                   "Gilmore, James S III", "Lessig, Lawrence",
                   "Graham, Lindsey O.", "Walker, Scott",
                   "McMullin, Evan", "Webb, James Henry Jr.",
                   "Christie, Christopher J.", "Jindal, Bobby",
                   "Pataki, George E."), 
            to=c("Sanders", "Clinton", "Trump", "Cruz",  "Paul",
                 "Carson", "Bush", "Rubio", "Santorum", "Kasich",
                 "Stein", "Fiorina", "O'Malley", "Huckabee",
                 "Johnson", "Perry", "Gilmore", "Lessig", "Graham",
                 "Walker", "McMullin", "Webb", "Christie", "Jindal",
                 "Pataki"))
# unique(finance$candidate)
# Now, all names of candidates are represented by their last name



###########################################
##                PARTY                  ##
###########################################

# Assign a party to each of the rows based on the name of the 
# candidate
party_affil <- function(x) {
  if (x == "Sanders" | x ==  'Clinton' |  x == 'O\'Malley' |  x ==  'Webb' |  x ==  'Lessig') {
    return('Democrat')
  } else if (x == 'Stein') {
    return('Green')
  } else if (x == 'McMullin') {
    return('Independent')
  } else {
    return('Republican')
  }
}
# Apply the function to the Finance dataframe
finance$party <- sapply(finance$candidate, party_affil)

# Check the matching candidates and parties
# finance %>%
#   group_by(candidate, party) %>%
#   distinct(candidate) %>%
#   print(tbl_df(finance), n=25)
# All candidates have an extra column with their party affiliation now



###########################################
##                GENDER                 ##
###########################################

# Add gender to the dataset, based on the Gender package
# Isolate the first name from the contributor and create a new column for it.
finance$name <- sub(" .*", "", sub(".*, ", "", finance$contributor))

# Add column with random years between 1930-2000 as the contributor birth years
finance$years <- as.integer(runif(nrow(finance), min = 1930, max = 2000))

# Add new data frame with the genders based on the names and years
finance_gender <- gender_df(finance, name_col = "name", year_col = "years",
                            method = "ssa")

# Remove repetitions from the gender data frame
finance_gender <- unique(finance_gender)

# Make the new dataset a data table like the finance one before joining
finance_gender <- as.data.table(finance_gender)

# Isolate the 2 columns we are after in the finance_gender_df dataset
finance_gender <- finance_gender[, c("name", "gender")]

# Merge with dplyr
# finance_new <- left_join(finance, finance_gender, by = "name")
# Gives - Error: cannot allocate vector of size 3.6 Gb

# Merge finance and finance_gender, using SQLDF (30 miutes to run)
system.time(finance <- sqldf("SELECT DISTINCT finance.*, finance_gender.gender FROM finance inner join finance_gender on finance.name = finance_gender.name"))
# print(tbl_df(finance), n=100)

# Remove the 'name' and 'years' columns
finance <- dplyr::select(finance, -c("name", "years"))
# head(finance)

# Remove the string 'either' from the gender column that was created with the
# sqld package.
toBeRemoved <- which(finance$gender=="either")
finance <- finance[-toBeRemoved,]
# table(finance$gender=="either")

# Remove duplicated column
finance$gender..17 <- NULL
head(finance)



###########################################
##                 DATE                  ##
###########################################

# Change the date column to POSIXct and re-organize the order of the components
# Long proces
finance$date <- parse_date_time(finance$date, orders = c("dmy"))
# finance$date <- as.Date(finance$date)



###########################################
##               ZIPCODES                ##
###########################################

# Clean zipcodes with the zipcode package
finance$zipcode <- clean.zipcodes(finance$zipcode)

# Shorten the clean zipcodes to 5 first digits
finance$zipcode <- strtrim(finance$zipcode, 5)



###########################################
##                STATES                 ##
###########################################

# Change abbr to full name for the state with the openintro library
finance$state <- abbr2state(finance$state)

# Change all values to lowercases
finance$state<- sapply(finance$state, tolower)

# Remove NAs from the dataset
finance <- finance[complete.cases(finance), ]

# Remove the non-contiguous states
finance <- subset(finance, !(state %in% c("alaska", "hawaii", "puerto rico")))



###########################################
##          Sample dataset               ##
###########################################

# In case we want a smaller and faster dataset to work with
# set.seed(2986)
# system.time(finance_sample <- finance[sample(1:nrow(finance), 900000), ])
# system.time(finance_sample <- inner_join(finance_sample, finance_gender, 
# by = 'name'))
# dim(finance_sample)
# head(finance_sample)



###########################################
##              SAVE AS CSV              ##
###########################################

# Save the dataframe as a .csv, so I won't have to run the
# above code every time during the exploration process.
write.csv(finance,'finance.csv', row.names=FALSE)
head(finance, 10)
# dim(finance)

# Test the wrangled dataset
# test <- fread('finance.csv')
# test <- tbl_df(test)
# head(test)
# names(test)

# finance