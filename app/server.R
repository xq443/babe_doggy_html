#   ____________________________________________________________________________
#   Server                                                                  ####
library(shinyWidgets)
library(geojsonio)
library(shiny)
library(rgdal)
library(leaflet)
library(sp)
library(tidyr)
library(magrittr)
library(lubridate)
library(ggmap)
library(xts)
library(shinyjs)
library(jsonlite)
library(urltools)
library(utils)
library(rvest)
library(stringr)
library(rgeos)
library(xml2)
library(selectr)
library(purrr)
library(RColorBrewer)
library(DT)
library(shinyBS)
library(googleVis)
library(geosphere)
library(leaflet.extras)
library(data.table)
library(tigris) 
library(plotly)
library(rmapshaper)
library(ggplot2)
library(ggthemes)
library(tidyverse)
library(ggpubr)
library(gridExtra)
library(cowplot)
library(shinyWidgets)
library(htmlwidgets)
library(KernSmooth)
library(raster)
library(dplyr)
library(revgeo)




char_zips <- zctas(cb = TRUE,state="NY")

####Format Setting

format_metric <- function(x, type) {
    switch(type,
           currency = paste0("$", 
                             formatC(round(as.numeric(x), 0), 
                                     big.mark = ",", 
                                     digits = nchar(as.character(round(as.numeric(x), 0)))
                             )
           ),
           real = format(round(as.numeric(x), 1), 
                         nsmall = 1, big.mark = ","),
           int = formatC(as.numeric(x), big.mark = ",", 
                         digits = nchar(as.character(x))),
           year = round(as.numeric(x),0),
           pct = paste0(format(round(as.numeric(x) * 100, 1), 
                               nsmall = 1, big.mark = ","),"%"))
}

shinyServer(function(input, output) {
  output$map <- renderLeaflet({
    map <- leaflet() %>%
      addProviderTiles("CartoDB.Positron", 
                       options = providerTileOptions(noWrap = TRUE)) %>%
      setView(-73.9252853,40.7910694,zoom = 13) %>%
      addResetMapButton()
    
    leafletProxy("map", data = cleaned_hospital) %>%
      addMarkers(~Longitude, ~Latitude,
                 group = "cleaned_hospital",
                 options = markerOptions(), popup = ~ paste0("<b>",Name,"</b>",
                                                        "<br/>", "Phone: ", Phone,
                                                        "<br/>", "Address: ", Location),
                 label = ~ Name,
                 icon = list(iconUrl = 'Icon/1.png'
                             ,iconSize = c(25,25)))
    
    leafletProxy("map", data = cleaned_park_ad) %>%
      addMarkers(~park_long, ~park_lat,
                 group = "cleaned_park_ad",
                 options = markerOptions(), popup = ~ paste0("<b>",park_name,"</b>",
                                                             "<br/>", "Neighborhood: ", park_neighb,
                                                             "<br/>", "Address: ", Address,
                                                             "<br/>", "Zipcode: ", park_zipcode),
                 label = ~ park_name,
                 icon = list(iconUrl = 'Icon/paw.png'
                             ,iconSize = c(25,25)))
    
    
    
    map
    
})
  observeEvent(input$Category, {
    if("Parks to Walk Dog" %in% input$Category) leafletProxy("map") %>% showGroup("cleaned_park_ad")
    else{leafletProxy("map") %>% hideGroup("cleaned_park_ad")}
    if("Veterinary Hospitals" %in% input$Category) leafletProxy("map") %>% showGroup("cleaned_hospital")
    else{leafletProxy("map") %>% hideGroup("cleaned_hospital")}
  }, ignoreNULL = FALSE)
  
  
  
  
## mouse click present
  observeEvent(input$map_click, {
    click <- input$map_click
    input_long = click$lng
    input_lat = click$lat
    input_zip_code = revgeo(longitude = input_long,
                            latitude = input_lat,
                            output = "hash")$zip
    input_zip_code = substr(input_zip_code, 1, 5)
    
    distance  = vector()
    nearest_park = character()
    indx = integer()
    
    for (i in 1:87) {
      # find the nearest dog park by distance
      distance[i] =  distm(c(input_long, input_lat),
                           c(cleaned_park_ad$park_long[i], cleaned_park_ad$park_lat[i]),
                           fun = distHaversine)
    }
    indx = which.min(distance)
    nearest_park = as.character(cleaned_park_ad[indx, "park_name"])
    distance_to_park = min(distance)
    
    distance_hosp  = vector()
    nearest_hosp = character()
    indx_hosp = integer()
    
    for (i in 1:110) {
      # find the nearest Veterinary Hospital by distance
      distance_hosp[i] =  distm(c(input_long, input_lat),
                           c(cleaned_hospital$Longitude[i], cleaned_hospital$Latitude[i]),
                           fun = distHaversine)
    }
    indx_hosp = which.min(distance_hosp)
    nearest_hosp = as.character(cleaned_hospital[indx_hosp, "Name"])
    distance_to_hosp = min(distance_hosp)
    
    walk_min =  distance_to_park/(1.4*60)
    walk_min_hosp = distance_to_hosp/(1.4*60)
    
    leafletProxy("map")  %>% clearGroup("circles")  %>%  
      addCircles(lng=input_long, lat=input_lat, group='circles', color = 'red',  weight= 20)
    
    output$click_coord <-
      renderText(paste("Latitude :", round(input_lat, 5), ", Longitude :", round(input_long, 5)))
    output$nearest_park <- renderText(nearest_park)
    output$distance_to_park <- renderText(paste(round( distance_to_park) , " m"))
    output$walk_min <- renderText(paste(round(walk_min) , " minutes"))
    
    output$nearest_hosp <- renderText(nearest_hosp)
    output$distance_to_hosp <- renderText(paste(round( distance_to_hosp) , " m"))
    output$walk_min_hosp <- renderText(paste(round(walk_min_hosp) , " minutes"))
    
  })
  
  output$densitymap <- renderLeaflet({
    leaflet() %>%
      addProviderTiles("CartoDB.Positron", 
                       options = providerTileOptions(noWrap = TRUE)) %>%
      setView(-73.9252853,40.7910694,zoom = 10) %>%
      addResetMapButton()
  })
  
  df_new<-reactive({
    
    if(is.null(input$place))
      true_place = as.vector(unlist(unique(df['Borough'])))
    else
      true_place = input$place
    
    if(is.null(input$gender))
      true_gender = as.vector(unlist(unique(df['AnimalGender'])))[1:2]
    else
      true_gender= input$gender
    
    df %>%
      filter(AnimalGender %in% true_gender &
               Borough %in% true_place) 
  })
  
  
  output$last_dance <- renderLeaflet({
    leaflet(options = leafletOptions(minZoom = 8, maxZoom = 18)) %>%
      addTiles() %>%
      setView(lng = -73.99, lat = 40.84, zoom = 10) %>%
      addCircleMarkers(lng = df$Longitude, lat = df$Latitude,
                       clusterOptions = markerClusterOptions())
  })
  
  observe({
    df_final<-df_new()
    leafletProxy("last_dance",data = df_final) %>%
      fitBounds(lat1 = min(df_final$Latitude), 
                lng1 = min(df_final$Longitude), 
                lat2 = max(df_final$Latitude), 
                lng2 = max(df_final$Longitude))%>%
      clearMarkerClusters()%>%
      clearPopups() %>%
      clearMarkers() %>%
      addMarkers(lng = ~Longitude, lat = ~Latitude, 
                 clusterOptions = markerClusterOptions(showCoverageOnHover = TRUE,
                                                       zoomToBoundsOnClick = TRUE, spiderfyOnMaxZoom = FALSE,
                                                       removeOutsideVisibleBounds = TRUE,
                                                       spiderLegPolylineOptions = list(weight = 1.5, color = "#222", opacity =
                                                                                         0.5), freezeAtZoom = FALSE))
  })
  
  df_new_new<-reactive({
    if(is.null(input$boro))
      true_area = as.vector(unlist(unique(xiangjianni['Borough'])))
    else
      true_area = input$boro
    
    if(is.null(input$sex))
      true_ani_gender = as.vector(unlist(unique(xiangjianni['AnimalGender'])))[1:2]
    else
      true_ani_gender= input$sex
    
    wxl<-xiangjianni %>%
      filter(AnimalGender %in% true_ani_gender &
               Borough %in% true_area) %>%
      group_by(ZipCode) %>%
      mutate(number=n()) %>%
      dplyr::select(ZipCode,number)
    geo_join(char_zips, 
             wxl, 
             by_sp = "GEOID10", 
             by_df = "ZipCode",
             how = "inner")
  })
  
  
  output$map_density <- renderLeaflet({char_zips = df_new_new()
  
  pal <- colorNumeric(
    palette = "Greens",
    domain = char_zips@data$number)
  
  # create labels for zipcodes
  labels <- 
    paste0(
      "Zip Code: ",
      char_zips@data$GEOID10, "<br/>",
      "Number of Dogs: ",char_zips@data$number) %>%
    lapply(htmltools::HTML)
  
  leaflet(char_zips) %>%
    # add base map
    addTiles() %>% 
    setView(-74.0260,40.7236, 11) %>%
    # add zip codes
    addPolygons(fillColor = ~pal(number),
                weight = 2,
                opacity = 1,
                color = "white",
                dashArray = "3",
                fillOpacity = 0.7,
                highlight = highlightOptions(weight = 2,
                                             color = "#666",
                                             dashArray = "",
                                             fillOpacity = 0.7,
                                             bringToFront = TRUE),
                label = labels) %>%
    # add legend
    leaflet::addLegend(pal = pal, 
              values = char_zips@data$number, 
              opacity = 0.7, 
              title = htmltools::HTML("Number of <br> 
                                    Dogs in NY <br> 
                                    by Zip Code"),
              position = "bottomright")
  
  })
  
  boroughSwitch<-reactive({
    Borough<-switch(input$Borough,
                    Brooklyn="Brooklyn",
                    Bronx="Bronx",
                    Manhattan="Manhattan",
                    Queens="Queens",
                    'Staten Island'="Staten Island"
    )
    return(Borough)
  })
  
  bite_reactive<-reactive({
    # Display graph as select all in the input
    if(is.null(input$boro1))
      true_area1 = as.vector(unlist(unique(dog_bite_clean_1['Borough'])))
    else
      true_area1 = input$boro1
    
    # selected data
    selected_data<-dog_bite_clean_1 %>%
      filter(Borough %in% true_area1) %>%
      filter(DateOfBite >= input$bite_date[1] & DateOfBite <= input$bite_date[2])%>%
      group_by(ZipCode) %>%
      mutate(number=n()) %>%
      dplyr::select(ZipCode,number,Gender)
    
    # inner join map & data
    geo_join(char_zips, 
             selected_data, 
             by_sp = "GEOID10", 
             by_df = "ZipCode",
             how = "inner")
  })
  
  
  # output map
  output$dog_bite_map <- renderLeaflet({df_new_new_new=bite_reactive()
  
  pal <- colorNumeric(
    palette = "BuPu",
    domain = df_new_new_new@data$number)
  
  
  # create labels for zipcodes
  labels <- 
    paste0(
      "Zip Code: ",
      df_new_new_new@data$GEOID10, "<br/>",
      "Number of Dog Bites: ",df_new_new_new@data$number) %>%
    lapply(htmltools::HTML)
  
  leaflet(df_new_new_new) %>%
    
    # add base map
    # other template 
    addTiles() %>% 
    setView(-74.0260,40.7236, 11) %>%
    
    # add zip code region
    addPolygons(fillColor = ~pal(number),
                weight = 2,
                opacity = 1,
                color = "white",
                dashArray = "3",
                fillOpacity = 0.7,
                highlight = highlightOptions(weight = 2,
                                             color = "purple",
                                             dashArray = "",
                                             fillOpacity = 0.7,
                                             bringToFront = TRUE),
                label = labels) %>%
    
    # add legend
    leaflet::addLegend(pal = pal, 
                       values = df_new_new_new@data$number, 
                       opacity = 0.7, 
                       title = htmltools::HTML("Number of <br> 
                                    Dog Bites in NY <br> 
                                    by Zip Code"),
                       position = "bottomright")
  
  })
  
  
  
  
  
  
  
  output$ggPiePlot<-renderPlot({
    ggplot(bite%>%filter(Borough==boroughSwitch())%>%
             group_by(Breed)%>%
             summarize(count = n())%>%
             arrange(desc(count))%>%
             top_n(10),
           aes(x="", y=count, fill=Breed))+
      geom_bar(stat="identity", width=1) +
      coord_polar("y", start=0)+
      theme_void()+
      geom_text(aes(label = count),
                position = position_stack(vjust = 0.5))
  })
  
  dataInput<-reactive({
    switch(input$pick_year,
           "2015"="2015",
           "2016"="2016",
           "2017"="2017",
           "2018"="2018")
  })
  
  groupInput<-reactive({
    switch(input$pick_gender,
           "Male"="M",
           "Female"="F")
  })
  
  neigbhdSwitch<-reactive({
    borough<-switch(input$pick_borough,
                    "Borough Park"="Borough Park",
                    "Bronx Park and Fordham"="Bronx Park and Fordham",
                    "Bushwick and Williamsburg"="Bushwick and Williamsburg",
                    "Canarsie and Flatlands"= "Canarsie and Flatlands",
                    "Central Bronx"="Central Bronx",
                    "Central Brooklyn"= "Central Brooklyn",
                    "Central Harlem"="Central Harlem",
                    "Central Queens"="Central Queens",
                    "Chelsea and Clinton"="Chelsea and Clinton", 
                    "East Harlem"="East Harlem",
                    "East New York and New Lots"="East New York and New Lots",
                    "Flatbush"="Flatbush",
                    "Gramercy Park and Murray Hill"="Gramercy Park and Murray Hill",
                    "Greenpoint"="Greenpoint",
                    "Greenwich Village and Soho"="Greenwich Village and Soho",
                    "High Bridge and Morrisania"="High Bridge and Morrisania",
                    "Hunts Point and Mott Haven"="Hunts Point and Mott Haven",
                    "Inwood and Washington Heights"="Inwood and Washington Heights",
                    "Jamaica"="Jamaica",
                    "Kingsbridge and Riverdale"="Kingsbridge and Riverdale"
    )
    return(borough)
  })
  
  BreedGSwitch<-reactive({
    breed_gender<-switch(input$pick_gender1,
                         "Male"="M",
                         "Female"="F")
    return(breed_gender)
  })
  
  boroughSwitch<-reactive({
    Borough<-switch(input$Borough,
                    Brooklyn="Brooklyn",
                    Bronx="Bronx",
                    Manhattan="Manhattan",
                    Queens="Queens",
                    'Staten Island'="Staten Island"
    )
    return(Borough)
  })
  
  SpayNeuterSwitch <-reactive({
    SpayNeuter<-switch(input$Spayneuter,
                       "Yes"="TRUE",
                       "No"="FALSE"
    )
    return(SpayNeuter)
  })
  
  output$name_plot<-renderPlot({
    names<-data%>%mutate(LicenseIssueYear=LicenseIssuedDate%>%as.Date('%m/%d/%Y')%>%format('%Y')%>%as.numeric())%>%
      filter(LicenseIssueYear==dataInput())%>%
      filter(AnimalGender!="")%>%
      filter(AnimalName!=""&AnimalName!="UNKNOWN"&AnimalGender==groupInput())%>%
      group_by(AnimalName,AnimalGender)%>%count()%>%arrange(desc(n))
    names[1:15,]%>%ggplot(aes(x=reorder(AnimalName,n),y=n,fill=AnimalName))+
      geom_col(show.legend = FALSE)+
      coord_flip()+
      theme_light()+labs(x="Top 15 Popular Dog Names",
                         y="Count",
                         title = "NYC's Most Popular Dog Names by Gender")+
      theme(plot.title = element_text(hjust = 0.5)) 
  })
  
  output$ggBarPlotA<-renderPlotly({
    Breed_data<-data%>%filter(Neighborhood==neigbhdSwitch())%>%
      filter(AnimalGender==BreedGSwitch())%>%
      filter(AnimalGender!=""&BreedName!="Unknown")%>%
      group_by(BreedName,AnimalGender)%>%count()%>%arrange(desc(n))
    Breed1<-Breed_data[1:10,]
    breed_name<-Breed_data[1:10,]$BreedName%>%as.vector()
    count<-Breed1$n
    plot_ly(x=~breed_name,y=~count,type = "bar",
            marker = list(color = 'rgb(58,200,225)',
                          line = list(color = 'rgb(8,48,107)', width = 1.5)))%>%
      layout(title="Top 10 Breed Names by Borough",
             xaxis=list(title=""))
  }) 
  
  output$ggPiePlot<-renderPlotly({
    bite%>%filter(Borough==boroughSwitch())%>%
      filter(SpayNeuter==SpayNeuterSwitch())%>%
      group_by(Breed)%>%
      summarize(count = n())%>%top_n(20)%>%
      plot_ly(labels=~Breed,values=~count)%>%
      add_pie(hole=0.5)%>%
      layout(title="Donut Charts",showlegend=F)
  })
  
  

    
})


