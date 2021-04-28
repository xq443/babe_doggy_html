df1<-data.frame(read.csv("C:/Users/59482/Desktop/my_part/data/NYC_dogs_clean.csv"))
library(dplyr) 

df1_new<- df1 %>%
  dplyr::select(AnimalGender,Borough,ZipCode,LicenseIssuedDate,LicenseExpiredDate)

library("readxl")
df2<-data.frame(read_xlsx("C:/Users/59482/Desktop/my_part/data/us-zip-code-latitude-and-longitude.xlsx")) 

df2_new<-df2 %>%
  mutate(Zip=as.numeric(Zip),Latitude=as.numeric(Latitude),Longitude=as.numeric(Longitude)) %>%
  filter(Zip<10455) %>%
  dplyr::select(Zip,Latitude,Longitude)

df<-df1_new %>% 
  inner_join(df2_new,by=c("ZipCode"="Zip")) %>%
  filter(Borough %in% c("Bronx","Brooklyn","Manhattan","Queens")) %>%
  dplyr::select(-ZipCode)

write.csv(df,file="C:/Users/59482/Desktop/my_part/data/df.csv",quote=F,row.names = F)
