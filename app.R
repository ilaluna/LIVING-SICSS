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

# Columns that can be mapped
score_vars <- c("lbm", "afw", "fys", "onv", "soc", "vrz", "won")

## Define UI for application that draws a histogram
ui <- fluidPage(
  
  titlePanel("Livability Dashboard"),
  
  sidebarLayout(
    sidebarPanel(
      
      selectInput(
        "score",
        "Select indicator:",
        choices = score_vars
      ),
      
      selectizeInput(
        "municipality",
        "Search municipality:",
        choices = c("ALL", sort(unique(muni_sf$gm_naam))),
        selected = "ALL",
        options = list(
          placeholder = "Type municipality...",
          maxOptions = 1000
        )
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
      flyToBounds(
        lng1 = as.numeric(bb["xmin"]),
        lat1 = as.numeric(bb["ymin"]),
        lng2 = as.numeric(bb["xmax"]),
        lat2 = as.numeric(bb["ymax"])
      )
  })
  
  observe({
    
    req(input$score)
    
    # raw values (DO NOT round for palette)
    vals_raw <- PC4_codes[[input$score]]
    vals <- round(vals_raw, 2)
    
    pal <- colorNumeric(
      palette = colorRampPalette(c("red", "yellow", "green"))(100),
      domain = vals_raw
    )
    
    labels <- sprintf(
      "<b>PC4:</b> %s<br><b>Municipality:</b> %s<br><b>%s:</b> %s",
      PC4_codes$PC4,
      PC4_codes$gm_naam,
      input$score,
      vals
    ) |> lapply(htmltools::HTML)
    
    leafletProxy("map", data = PC4_codes) %>%
      clearShapes() %>%
      clearControls() %>%
      
      addPolygons(
        fillColor = pal(vals_raw),
        fillOpacity = 0.8,
        color = "white",
        weight = 1,
        layerId = ~PC4,
        label = labels,
        labelOptions = labelOptions(
          direction = "auto",
          textsize = "11px",
          style = list(
            "font-weight" = "bold",
            "color" = "#333"
          )
        )
      ) %>%
      
      addLegend(
        position = "bottomright",
        pal = pal,
        values = vals_raw,
        title = input$score
      )
  })
}

shinyApp(ui, server)
