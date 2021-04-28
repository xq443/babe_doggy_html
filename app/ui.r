#   ____________________________________________________________________________
#   UI                                                                      ####



library(shinyWidgets)
library(shiny)
library(leaflet)
library(plotly)
library(shinyjs)
library(shinyBS)

### . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . ..
### Colors                                                                  ####

#C10250 purple
#03BCC0 green
#D2D945 yellow/green
#FCB040 orange
#FF5850 red
#436983 hipster blue

shinyUI(navbarPage(title = "Woof Woof",
                   theme = "style/style.css",
                   fluid = TRUE, 
                   collapsible = TRUE,
                   
                   # ----------------------------------
                   # tab panel 1 - Home
                   tabPanel("Home",
                            includeHTML("home.html"),
                            tags$script(src = "plugins/scripts.js"),
                            tags$head(
                              tags$link(rel = "stylesheet", 
                                        type = "text/css", 
                                        href = "plugins/font-awesome-4.7.0/css/font-awesome.min.css"),
                              tags$link(rel = "icon", 
                                        type = "image/png", 
                                        href = "images/logo_icon.png")
                            ),
                            includeHTML("scrollToTop.html")
                   ),

                   # ----------------------------------
                   # tab panel 2 - Dog parks & hospitals
                   tabPanel("Dog parks & hospitals",
                            #leafletOutput("map",width="100%",height=700),
                            #includeHTML("scrollToTop.html")
                            fluidPage(
                              fluidRow(column(4,
                                              selectizeInput("Category", "Choose Parks/Hospitals",
                                                             choices = c("Choose Category" = "",
                                                                         "Parks to Walk Dog",
                                                                         "Veterinary Hospitals"),
                                                             multiple = T)),
                                       column(8, leafletOutput("map", height = "680px")))
                            ),
                            absolutePanel(
                              id = "control",
                              class = "panel panel-default",
                              fixed = TRUE,
                              draggable = TRUE,
                              top = 230,
                              left = 20,
                              right = "auto",
                              bottom = "auto",
                              width = 400,
                              height = "auto",
                              h2("Transportation Guide"),
                              tags$style("#click_coord{font-size: 16px;display:inline}"), 
                              h4(strong('Current Location :', style="display:inline")), p(textOutput("click_coord")),
                             
                              tags$style("#nearest_park{font-size: 16px;display:inline}"), 
                              h4(strong("Nearest Park: ", style="display:inline")),  p(textOutput("nearest_park")),
                              tags$style("#distance_to_park{font-size: 16px;display:inline}"), 
                              h4(strong("Distance to Nearest Park : ", style="display:inline")), p(textOutput("distance_to_park")),
                              tags$style("#walk_min{font-size:16px; display:inline}"),
                              h4(strong("Estimated time to the Nearest Park : ", style="display:inline")), p(textOutput("walk_min")),
                              
                              tags$style("#nearest_hosp{font-size: 16px;display:inline}"), 
                              h4(strong("Nearest Veterinary Hospital : ", style="display:inline")),  p(textOutput("nearest_hosp")),
                              tags$style("#distance_to_hosp{font-size: 16px;display:inline}"), 
                              h4(strong("Distance to Nearest Hospital : ", style="display:inline")), p(textOutput("distance_to_hosp")),
                              tags$style("#walk_min_hosp{font-size:16px; display:inline}"),
                              h4(strong("Estimated time to Nearest Hospital : ", style="display:inline")), p(textOutput("walk_min_hosp"))
                            )),
                   
                   tabPanel('Dog Density and Bite',
                            fluidPage(
                              tabsetPanel(
                              tabPanel("Dog License Location",
                                       titlePanel("Dog License Location"),
                                       sidebarPanel(
                                         fluidRow(
                                           selectizeInput("place", "Choose the Borough",
                                                          choices = c("Choose Borough" = "",
                                                                      as.vector(unlist(unique(df['Borough'])))),
                                                          multiple = T)),
                                         fluidRow(
                                           pickerInput("gender", 'Choose Gender',
                                                       choices = as.vector(unlist(unique(df['AnimalGender'])))[1:2],
                                                       options = list(`actions-box` = TRUE),
                                                       multiple = T)
                                           
                                         )
                                         
                                       ),
                                       mainPanel(
                                         
                                         leafletOutput("last_dance", height = "700px")
                                       )
                              ),
                              tabPanel("Dog Density Map",titlePanel("Dog Density Map"),
                                       sidebarPanel(
                                         fluidRow(
                                           selectizeInput("boro", "Choose the Borough",
                                                          choices = c("Choose Borough" = "",
                                                                      as.vector(unlist(unique(xiangjianni['Borough'])))),
                                                          multiple = T)),
                                         fluidRow(
                                           pickerInput("sex", 'Choose Gender',
                                                       choices = as.vector(unlist(unique(xiangjianni['AnimalGender'])))[1:2],
                                                       options = list(`actions-box` = TRUE),
                                                       multiple = T)
                                           
                                         )
                                         
                                       ),
                                       mainPanel(
                                         
                                         leafletOutput("map_density", height = "700px")
                                       )
                              ),
                              
                              tabPanel('Dog Bite Locations',titlePanel('Dog Bite Locations'), 
                                       sidebarPanel(
                                       fluidRow(
                                                                 selectizeInput("boro1", "Choose the Borough",
                                                                                choices = c("Choose Borough" = "",
                                                                                            as.vector(unlist(unique(dog_bite_clean_1['Borough'])))),
                                                                                multiple = T)),
                                       # add row 2: select time range
                                       fluidRow(
                                                       dateRangeInput('bite_date', 'Time Period:', start = '2015-01-01'),
                                                       multiple = T)),
                                       
                                       # add row 3: map
                            
                                       mainPanel(
                                         
                                         leafletOutput("dog_bite_map", height = "700px")
                                       )
                                       )
                                       
                              )
                              
                            )),

                   # ----------------------------------
                   # tab panel 3 - Summary Statistics
                   tabPanel("Summary Statistics",
                            fluidPage(
                              tabsetPanel(
                                tabPanel("Popular Dog Names",
                                         fluidRow(
                                           column(4,
                                                  radioButtons(
                                                    inputId="pick_year",
                                                    label = "Pick a year to explore",
                                                    choices = c(
                                                      "2015","2016","2017","2018"
                                                    )
                                                  )),
                                           column(4,radioButtons( 
                                             inputId="pick_gender",
                                             label = "Pick a gender to explore",
                                             choices = c( "Male","Female")
                                           ))),
                                         fluidRow(column(8,plotOutput(outputId='name_plot',height = "500px",width = "100%")))),
                                
                                tabPanel("Popular Breeds by Neighborhood",
                                         titlePanel(h3("Bar Chart")),
                                         sidebarLayout(
                                           sidebarPanel(
                                             selectInput("pick_borough", 
                                                         label="Choose a Neighborhood",
                                                         choices=c("Borough Park","Bronx Park and Fordham","Bushwick and Williamsburg",
                                                                   "Canarsie and Flatlands","Central Bronx","Central Brooklyn",
                                                                   "Central Harlem", "Central Queens","Chelsea and Clinton", "East Harlem",
                                                                   "East New York and New Lots","Flatbush","Gramercy Park and Murray Hill","Greenpoint","Greenwich Village and Soho",
                                                                   "High Bridge and Morrisania","Hunts Point and Mott Haven","Inwood and Washington Heights","Jamaica","Kingsbridge and Riverdale")
                                             ),
                                             selectInput("pick_gender1",
                                                         label = "Choose a gender",
                                                         choices = c("Male","Female")
                                                         
                                             )
                                           ),
                                           mainPanel(
                                             plotlyOutput("ggBarPlotA")
                                           )
                                         )),
                                
                                tabPanel("Dog Bite Record by Borough",
                                         titlePanel(h3("Dog Bite Record by Borough")),
                                         sidebarLayout(
                                           sidebarPanel(
                                             selectInput("Borough", 
                                                         label="Choose a Borough",
                                                         choices=c("Brooklyn","Bronx","Manhattan","Queens","Staten Island")
                                             ),
                                             selectInput("Spayneuter",
                                                         label = "Spayneuter or Not",
                                                         choices = c("Yes","No")
                                                         
                                             )
                                           ),
                                           mainPanel(
                                             plotlyOutput("ggPiePlot",height="600px")
                                           )
                                         )
                                )
                                
                              )
                            )),
                   
                   # ----------------------------------
                   # tab panel 4 - About
                   tabPanel("About",
                            includeHTML("about.html"),
                            shinyjs::useShinyjs(),
                            tags$head(
                                tags$link(rel = "stylesheet", 
                                          type = "text/css", 
                                          href = "plugins/carousel.css"),
                                tags$script(src = "plugins/holder.js")
                            ),
                            tags$style(type="text/css",
                                       ".shiny-output-error { visibility: hidden; }",
                                       ".shiny-output-error:before { visibility: hidden; }"
                            )
                   )
))



