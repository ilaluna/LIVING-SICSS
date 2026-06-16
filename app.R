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
st_geometry(PC4_codes) <- "geom"

if (st_crs(PC4_codes)$epsg != 4326) {
  PC4_codes <- st_transform(PC4_codes, 4326)
}

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
    
    bb <- st_bbox(PC4_codes)
    
    leaflet() %>%
      addProviderTiles(providers$CartoDB.Positron) %>%
      fitBounds(
        lng1 = as.numeric(bb["xmin"]),
        lat1 = as.numeric(bb["ymin"]),
        lng2 = as.numeric(bb["xmax"]),
        lat2 = as.numeric(bb["ymax"])
      ) %>%
      addPolygons(
        data = PC4_codes,
        layerId = ~PC4_codes,
        fillOpacity = 0.8,
        weight = 1,
        color = "white"
      )
  })
  
  observe({
    
    req(input$score)
    
    vals <- round(PC4_codes[[input$score]],2)
    
    pal <- colorNumeric(
      palette = "viridis",
      domain = vals,
      na.color = "transparent"
    )
    
    labels <- paste0(
      "<b>PC4:</b> ", PC4_codes$PC4,
      "<br><b>Municipality:</b> ", PC4_codes$gm_naam,
      "<br><b>", input$score, ":</b> ", vals
    ) |> lapply(htmltools::HTML)
    
    leafletProxy("map", data = PC4_codes) %>%
      clearShapes() %>%
      clearControls() %>%
      
      addPolygons(
        fillColor = pal(vals),
        fillOpacity = 0.8,
        color = "white",
        weight = 1,
        layerId = ~PC4,
        label = labels
      ) %>%
      
      addLegend(
        position = "bottomright",
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
