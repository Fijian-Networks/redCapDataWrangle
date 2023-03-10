#Clear existing individuals_df and graphics
rm(list=ls())
graphics.off()
library(tidyverse)
library(dplyr)

##########################
# Load Individual's Data #
##########################
individuals=read_csv('individuals.csv',col_types = cols(.default = "c"), na = character())


#######################
# Load Household Data #
#######################
households=read_csv('households.csv',col_types = cols(.default = "c"), na = character()) %>% select(-contains("house_photo"))
households$household_id = as.numeric(households$household_id)

#####################################
# Import Individual Survey Template #
#####################################
survey_import_data=read_csv('survey_import.csv',col_types = cols(.default = "c"), na = character())
survey_import_data$household_id = as.numeric(survey_import_data$household_id)

############################
# Merging appropriate Data #
############################

only_need <- inner_join(individuals, households, by="record_id", na = character()) %>%
  select(-contains("redcap")) %>% select(-contains("...416"))

collate <-select(survey_import_data) %>% bind_rows(survey_import_data, only_need)
collate$original_record_id <- collate$record_id
collate$household_id = as.numeric(collate$household_id)
collate$household_id = sprintf("%05.1f",collate$household_id)

##################################################
# Creating each visits data so its pre-populated #
# Also, reassigning record_id so that            #
# import into redcap doesn't miss anyone         #
##################################################
visit1 <- collate %>% 
  mutate_at(c('redcap_event_name'), ~replace_na(.,"visit_1_arm_1")) %>%
  mutate_if(is.character, ~replace_na(.,"")) %>%
  select(-contains("...416"))
visit1$record_id <- 1:nrow(visit1)

visit2 <- collate %>% mutate_at(c('redcap_event_name'), ~replace_na(.,"visit_2_arm_1")) %>%
  mutate_if(is.character, ~replace_na(.,"")) %>% select(-contains("...416"))
visit2$record_id <- 1:nrow(visit2)

visit3 <- collate %>% mutate_at(c('redcap_event_name'), ~replace_na(.,"visit_3_arm_1")) %>%
  mutate_if(is.character, ~replace_na(.,"")) %>% select(-contains("...416"))
visit3$record_id <- 1:nrow(visit3)
# make a list of them all and smash them together
allData <- list(visit1, visit2, visit3) %>% bind_rows()  %>% group_by(household_id) %>% arrange(household_id)

  
write_csv(visit1, "Visit1_ImportData.csv")

write_csv(allData, "ImportData.csv")



# Extremely useful things for a casual R user...
#https://sparkbyexamples.com/r-programming/replace-na-with-empty-string-in-r-dataframe/

# used this on import to avoid column type conflicts in merging:
# col_types = cols(.default = "c")

# Merging the data added this weird column ...416, hence the instruction at the end of each:
# %>% select(-contains("...416"))
