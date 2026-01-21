#LOADING IN DATAFRAMES
#-------------------------------------------------------------------------------
library(tidyverse)

#LOAD IN THE DATA 
################################################################################
#MOVE ALL RAW DATA FILES INTO data/raw folder (you can drag and drop)
#REPLACE FILENAME WITH THE ACTUAL FILENAME OF YOUR DATA
raw_quesdata <- read_csv("data/raw/COrina_PCLr.csv")
raw_imagingdata_FA <- read_csv("data/processed/roi_FA_values.csv")
raw_imagingdata_MD <- read_csv("data/processed/roi_MD_values.csv")
raw_imagingdata_AD <- read_csv("data/processed/roi_AD_values.csv")
raw_imagingdata_RD <- read_csv("data/processed/roi_RD_values.csv")

raw_IQdata <- read_csv("data/raw/IQ_data.csv")

#CURRENT STUDY DOESN'T USE QUALTRICS MEASURES, SO THIS IS COMMENTED OUT
#raw_Qualtricsdata <- read_csv("data/raw/FILENAME.csv")
#Remove unecessary Qualtrics output
#raw_Qualtricsdata <- raw_Qualtricsdata[-c(2), ]
#colnames(raw_Qualtricsdata) <- as.character(raw_Qualtricsdata[1, ])
#raw_Qualtricsdata <- raw_Qualtricsdata[-1, ]
#raw_Qualtricsdata <- raw_Qualtricsdata <- raw_Qualtricsdata[, -(1:17)]

#the dataframe names must stay the same for subsequent code to work properly 
#(e.g. raw_behaviouraldata)
################################################################################

#VIEW THE IMPORTED DATA
View(raw_quesdata)
View(raw_imagingdata_FA)
View(raw_imagingdata_MD)
View(raw_imagingdata_AD)
View(raw_imagingdata_RD)
View(raw_IQdata)
#View(raw_Qualtricsdata)

head(raw_quesdata)
head(raw_imagingdata_FA)
head(raw_imagingdata_MD)
head(raw_imagingdata_AD)
head(raw_imagingdata_RD)
head(rawIQdata)
#head(raw_Qualtricsdata)
#-------------------------------------------------------------------------------
#MERGE DATASETS TOGETHER

#To merge all the datasets together they have to have the same column name for the subject ID.
#Here we rename the subject ID column in each dataset to "subject_id" for consistency.
#Change "COLUMN_NAME" to the actual column name in your datasets if it's different 
#Leave this as a string (keep the "")
#In QUALTRICS  this will likely output as Q(##) 
#raw_quesdata <- raw_quesdata |> rename(subject_id = "COLUMN_NAME")
raw_imagingdata_FA <- raw_imagingdata_FA |> rename(subject_id = "subject")
#raw_Qualtricsdata <- raw_Qualtricsdata |> rename(subject_id = "COLUMN_NAME")

#Ensure this is changed
View(raw_behaviouraldata)
View(raw_imagingdata)
View(raw_Qualtricsdata)

rawdata <- raw_imagingdata %>%
  left_join(raw_quesdata,  by = "subject_id") |>
  left_join(raw_IQdata,    by = "subject_id")

#VIEW THE MERGED DATA
View(rawdata)

#SAVE THE MERGED DATA (as a .csv file)
write_csv(rawdata, paste0("data/raw/rawdata_prelimSSSP_abstract.csv"))
