# -----------------------------------------
# Project: FEA-ther (Functional Enrichment Analysis Tool)
# Author: Lucien Piat
# Affiliation: Rouen Normandie University
# Date: 04/10/2024
# Description: This Shiny application allows users to perform functional enrichment analysis
#              on biological data. Users can upload CSV files, select options for analysis, and 
#              visualize the results through interactive plots and tables.
#
# Usage: Load the required packages, upload your data, and follow the on-screen instructions.
# -----------------------------------------

#Install the packages
check_and_install_packages <- function(packages) {
  new_packages <- packages[!(packages %in% installed.packages()[, "Package"])]
  if (length(new_packages)) {
    install.packages(new_packages)
  }
  lapply(packages, require, character.only = TRUE)
}
required_packages <- c(
  "shiny", "shinycssloaders", "shinyalert", "shinydashboard", 
  "dashboardthemes", "DT", "ggiraph", "zip", "ggplot2", "data.table"
)
check_and_install_packages(required_packages)

# Load the packages
library(shiny)
library(shinycssloaders)
library(shinyalert)
library(shinydashboard)
library(dashboardthemes)
library(DT)
library(ggiraph)
library(ggplot2)
library(data.table)

# Import the functions
source("functions.R")
source("server.R")

# Import the custom theme
source("custom_theme.R")

dashboardPage(
  
  # -----------------------------------------
  # HEADER, with an image
  # -----------------------------------------
  
  create_dashboard_header(), 
  
  # -----------------------------------------
  # Sidebar, with images, custom color and a full file input suite
  # -----------------------------------------
  
  dashboardSidebar(
    sidebarMenu(
      tags$li(
        class = "nav-item",
        tags$a(
          href = "#",
          class = "nav-link",
          icon('dove'),
          "Home, select your analysis ↓", style = "font-size: 15px;" # Adjust font size as needed
        )
      ),
      fileInput("file", "Choose a File", width = '100%', placeholder = "Your CSV", buttonLabel = 'Import'),
      tags$hr(style = "border: 1.5px solid #5c2a5c;"),
      selectInput("separator", 'Separator', choices = c('Auto', 'Semicolon', 'Comma', 'Tab', 'Space', 'Dot')),
      tags$hr(style = "border: 1.5px solid #5c2a5c;"),
      selectInput("organism", 'Select an organism name', choices = c('Pavo cristatus', "Afropavo congensis", "Pavo muticus")),
      tags$hr(style = "border: 1.5px solid #5c2a5c;"),
      menuItem("  Whole Data Inspection", tabName = "whole_data_inspection_mitem", icon = icon("eye"), selected = TRUE),
      menuItem("  Go Term Enrichment", tabName = "go_term_enrichment_mitem", icon = icon("database")),
      menuItem("  Pathway Enrichment", tabName = "pathway_enrichment_mitem", icon = icon("repeat")),
      menuItem("About", tabName = "about", icon = icon("info-circle"))
    )
  ),
  
  # -----------------------------------------
  # Body, with error handling, nice colors and all the boxes
  # -----------------------------------------
  
  dashboardBody(
    customTheme,
    tags$head(tags$style(HTML(".box { border-top: 3px solid #61b644; }"))),
    
    # Define tab items
    tabItems(
      tabItem(tabName = "whole_data_inspection_mitem",
              h2("Whole Data Inspection"),
              fluidRow(
                box(title = "Volcano Plot", width = 7, withSpinner(girafeOutput("volcano_plot", height = 400))),
                box(title = "Options", width = 5, 
                    sliderInput("p_val_slider","P-value cutoff from input", 0, 1, 0.05, step = 0.01),
                    sliderInput("log2FC_slider","log2 FoldChange cutoff from input:", 0, 5, 1, step = 0.1),
                    downloadButton("download", label = "Download volcano plot"))
              ),
              fluidRow(box(title = "Filtered table", width = 12, withSpinner(dataTableOutput("table"))))  # Add spinner to the table
      ),
      tabItem(tabName = "go_term_enrichment_mitem",
              h2("Go Term Enrichment"),
              tags$div(style = "text-align: center;",
                       tags$img(src = "dodo.png", height = "100", alt = "dodo")
              ),
              p("#TODO")
      ),
      tabItem(tabName = "pathway_enrichment_mitem",
              h2("Pathway Enrichment"),
              tags$div(style = "text-align: center;",
                       tags$img(src = "dodo.png", height = "100", alt = "dodo")
              ),
              p("#TODO")
      ),
      aboutTab() # Create the about tab from custom function
    )
  )
)
