library(tidyverse)
library(lubridate)
library(tigris) 
library(shinyWidgets)

cleaned_hospital <- read_csv('Data/cleaned_hospital.csv') 
cleaned_hospital <- cleaned_hospital %>% mutate(id = 1:nrow(cleaned_hospital))
df <- read.csv('Data/df.csv')
cleaned_park <- read_csv('Data/dog_park_clean.csv')
ori_park <- read_csv('Data/Dog_Run_Or.csv')
cleaned_park_ad <- cleaned_park %>% left_join(ori_park, by = c('park_name' = 'Name')) %>% 
  dplyr::select(-X1, -Prop_ID, -DogRuns_Type, -Accessible, -Notes)


xiangjianni<-read.csv("Data/NYC_dogs_clean.csv")
bite <- read.csv("Data/cleaned_dog_bite_FINAL.csv")
data <- read.csv("Data/DogLicensing_clean.csv")

top_20_neibhd<-data%>%group_by(Neighborhood)%>%count()
top_20_neibhd$Neighborhood[1:20]%>%as.vector()

dog_bite_clean_1 <- read_csv('Data/dog_bite_clean_1.csv')



#clean_dog <- read_csv("NYC_dogs_clean.csv")
#d1 <- clean_dog %>% group_by(BreedName) %>% count() %>% arrange(desc(n))
#dog_bite <- read_csv('DOHMH_Dog_Bite_Data.csv')
#clean_dog_bite <- dog_bite %>% select(-Species) %>% drop_na(ZipCode) %>% 
#  mutate(DateOfBite = as.Date(DateOfBite, format = "%b %d %Y")) %>% 
#  mutate(UniqueID = 1:nrow(clean_dog_bite))
#write_csv(clean_dog_bite, 'cleaned_dog_bite.csv')
