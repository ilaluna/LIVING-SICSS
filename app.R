## Install packages (if not already installed)
# shiny
if (!requireNamespace("shiny", quietly = TRUE)) {
  install.packages("shiny")
}
# sf
if (!requireNamespace("sf", quietly = TRUE)) {
  install.packages("sf")
}
# dplyr
if (!requireNamespace("dplyr", quietly = TRUE)) {
  install.packages("dplyr")
}
# ggplot2
if (!requireNamespace("ggplot2", quietly = TRUE)) {
  install.packages("ggplot2")
}
# leaflet
if (!requireNamespace("leaflet", quietly = TRUE)) {
  install.packages("leaflet")
}
# renv
if (!requireNamespace("renv", quietly = TRUE)) {
  install.packages("renv")
}


## Load libraries
library(shiny)
library(sf)
library(dplyr)
library(ggplot2)
library(leaflet)
library(renv)

### Set working directory
setwd("C:/Users/lunardel/Downloads")

## Source data
source("Script_SICCS.R")

## Transform coordinates to work with leaflet
st_geometry(PC4_codes) <- "geom"

# if geometry is not the right size, than change into the appropriate one
if (st_crs(PC4_codes)$epsg != 4326) {
  PC4_codes <- st_transform(PC4_codes, 4326)
}

# Change name of score into more easily readable ones
score_vars <- c(
  "Livability" = "lbm",
  "Difference from national score" = "afw",
  "Physical environment" = "fys",
  "Security" = "onv",
  "Social cohesion" = "soc",
  "Amenities" = "vrz",
  "Housing stock" = "won"
)

# Get name of the main cities to map their centroids
major_cities <- muni_sf[muni_sf$gm_naam %in% c(
  "Amsterdam",
  "Rotterdam",
  "Utrecht",
  "'s-Gravenhage",
  "'s-Hertogenbosch",
  "Eindhoven",
  "Groningen",
  "Tilburg",
  "Almere",
  "Breda",
  "Nijmegen",
  "Zwolle",
  "Enschede"
), ]

# Get centroids on the main cities
major_cities_centroids <- st_centroid(major_cities)
muni_choices <- c("ALL", sort(unique(muni_sf$gm_naam)))

## Define UI for application that draws a histogram
ui <- fluidPage(
  # title of the dashboard
  titlePanel(
    div(
    style = "text-align:center;", # align title in the center
    "Livability Dashboard" # title
  )),
  # layout of the sidebar
  sidebarLayout(
    sidebarPanel(
      # select the inputs
      selectInput(
        "score", # we want to be able to change displayed score
        "Select indicator:", #title of input
        choices = score_vars #choosing from the score variables
      ),
      
      selectizeInput( 
        "municipality", # we also want to just focus on different municipalities, for better interpretation
        "Search municipality:", # title of input
        choices = muni_choices, # all municipalieties plus whole country option
        selected = "ALL", # all is the default
        options = list(
          placeholder = "Type municipality...", #possibility to type municipality name
          maxOptions = 1000
        )
      )
    ),
    
    mainPanel(
      leafletOutput("map", height = 700), # dimension
      h4("Map of the Netherlands"), # x-axis title
      verbatimTextOutput("municipality_info")
    )
  )
)

server <- function(input, output, session) {
  
  req(muni_sf)
  
  # Base map
  
  output$map <- renderLeaflet({
    
    leaflet() %>%
      addProviderTiles("CartoDB.VoyagerNoLabels") %>% # no labels on the map below, to avoid confusion
      fitBounds(3.2, 50.0, 7.3, 53.0) # centering the map
  })
  
  # MAin map render
  observe({
    
    req(input$score)
    
    muni <- input$municipality #municipality names
    
    # filter by municipality
    # making sure that in whole country is not selected, we can filter for single municipality
    if (is.null(muni) || muni == "ALL" || muni == "") {
      
      data_map <- PC4_codes
      
    } else {
      
      data_map <- PC4_codes[
        trimws(tolower(PC4_codes$gm_naam)) ==
          trimws(tolower(muni)),
      ]
      
      # fallback if empty
      if (nrow(data_map) == 0) {
        data_map <- PC4_codes
      }
    }
    
    # scores
    vals_raw <- data_map[[input$score]]
    vals <- round(vals_raw, 2) # round scores to second decimal
    
    pal <- colorNumeric( # change color palette: red for lower scores, green for higher scores
      palette = colorRampPalette(c("red", "yellow", "green"))(100),
      domain = vals_raw
    )
    # add information per PC4 area: Pc4 code, municipality, score
    labels <- sprintf(
      "<b>PC4:</b> %s<br><b>Municipality:</b> %s<br><b>%s:</b> %s",
      data_map$PC4,
      data_map$gm_naam,
      input$score,
      vals
    ) |> lapply(htmltools::HTML)
    
    # -------------------------
    # DRAW MAP
    # -------------------------
    leafletProxy("map", data = data_map) %>%
      clearShapes() %>%
      clearControls() %>%
      # polygons aesthetics
      addPolygons(
        fillColor = pal(vals_raw),
        fillOpacity = 0.8,
        color = "white",
        weight = 1,
        label = labels
      ) %>%
      # add name of the cities, for geo reference
      addLabelOnlyMarkers(
        data = major_cities_centroids, # we use centroids to put them on the map
        label = ~gm_naam, 
        labelOptions = labelOptions(
          noHide = TRUE,
          direction = "center",
          textOnly = TRUE,
          style = list( # change color, size, etc...
            "color" = "#222",
            "font-weight" = "bold",
            "font-size" = "7px",
            "text-shadow" = "2px 2px 4px white"
          )
        )
      ) %>%
      # ad legend
      addLegend(
        position = "topright", # change place
        pal = pal,
        values = vals_raw,
        title = input$score
      )
  })
}

shinyApp(ui, server)

