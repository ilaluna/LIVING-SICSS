## Install packages (if not already installed)
# shiny
if (!requireNamespace("shiny", quietly = TRUE)) {
  install.packages("shiny")
}
if (!requireNamespace("sf", quietly = TRUE)) {
  install.packages("sf")
}
if (!requireNamespace("dplyr", quietly = TRUE)) {
  install.packages("dplyr")
}
if (!requireNamespace("ggplot2", quietly = TRUE)) {
  install.packages("ggplot2")
}
if (!requireNamespace("leaflet", quietly = TRUE)) {
  install.packages("leaflet")
}
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
# make sure geometry is active
st_geometry(PC4_codes) <- "geom"

# transform to WGS84 (required for Leaflet)
PC4_codes <- st_transform(PC4_codes, 4326)

# verify
st_crs(PC4_codes)

# Columns that can be mapped
score_vars <- c("lbm", "afw", "fys", "onv", "soc", "vrz", "won")

## Define UI for application that draws a histogram
ui <- fluidPage(
  
  titlePanel("Municipality Dashboard"),
  
  sidebarLayout(
    sidebarPanel(
      selectInput(
        "score",
        "Select indicator:",
        choices = score_vars
      )
    ),
    
    mainPanel(
      leafletOutput("map", height = 700),
      h4("Selected municipality"),
      verbatimTextOutput("municipality_info")
    )
  )
)

server <- function(input, output, session) {
  
  output$map <- renderLeaflet({
    leaflet(PC4_codes) %>%
      addTiles() %>%
      addPolygons(
        layerId = ~gm_naam,
        weight = 1,
        color = "white"
      )
  })
  
  observe({
    
    req(input$score)
    
    vals <- PC4_codes[[input$score]]
    
    pal <- colorNumeric("viridis", domain = vals)
    
    leafletProxy("map", data = PC4_codes) %>%
      clearShapes() %>%
      clearControls() %>%
      addPolygons(
        fillColor = pal(vals),
        fillOpacity = 0.8,
        color = "white",
        weight = 1,
        layerId = ~gm_naam,
        label = ~gm_naam
      ) %>%
      addLegend(
        "bottomright",
        pal = pal,
        values = vals,
        title = input$score
      )
  })
  
  observeEvent(input$map_shape_click, {
    
    municipality <- input$map_shape_click$id
    
    selected <- PC4_codes[PC4_codes$gm_naam == municipality, ]
    
    output$municipality_info <- renderPrint({
      selected |> st_drop_geometry()
    })
  })
}

shinyApp(ui, server)
