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

major_cities_centroids <- st_centroid(major_cities)
muni_choices <- c("ALL", sort(unique(muni_sf$gm_naam)))

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
        choices = muni_choices,
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
  
  req(muni_sf)
  
  # =========================
  # BASE MAP
  # =========================
  output$map <- renderLeaflet({
    
    leaflet() %>%
      addProviderTiles("CartoDB.VoyagerNoLabels") %>%
      fitBounds(3.2, 50.0, 7.3, 53.0)
  })
  
  # =========================
  # MAIN MAP RENDER (FILTERED)
  # =========================
  observe({
    
    req(input$score)
    
    muni <- input$municipality
    
    # -------------------------
    # FILTER BY MUNICIPALITY
    # -------------------------
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
    
    # -------------------------
    # SCORES
    # -------------------------
    vals_raw <- data_map[[input$score]]
    vals <- round(vals_raw, 2)
    
    pal <- colorNumeric(
      palette = colorRampPalette(c("red", "yellow", "green"))(100),
      domain = vals_raw
    )
    
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
      
      addPolygons(
        fillColor = pal(vals_raw),
        fillOpacity = 0.8,
        color = "white",
        weight = 1,
        label = labels
      ) %>%
      
      addLabelOnlyMarkers(
        data = major_cities_centroids,
        label = ~gm_naam,
        labelOptions = labelOptions(
          noHide = TRUE,
          direction = "center",
          textOnly = TRUE,
          style = list(
            "color" = "#222",
            "font-weight" = "bold",
            "font-size" = "7px",
            "text-shadow" = "2px 2px 4px white"
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

