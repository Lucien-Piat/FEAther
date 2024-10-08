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

# Install the required packages
required_packages <- c("shiny","shinycssloaders", "shinyalert", "shinydashboard", "dashboardthemes", "DT")
new_packages <- required_packages[!(required_packages %in% installed.packages()[, "Package"])]

if (length(new_packages)) {
  install.packages(new_packages)
}

# Load the packages
library(shiny)
library(shinycssloaders)
library(shinyalert)
library(shinydashboard)
library(dashboardthemes)
library(DT)

# Import the functions from another script
source("functions.R")

# Import the custom theme i created
source("custom_theme.R")

dashboardPage(
  
  # -----------------------------------------
  # HEADER, with an image
  # -----------------------------------------
  
  dashboardHeader(
    title = tags$div(style = "display: flex; align-items: center;",
                     tags$img(src = "logo.png", height = "50px"),
                     tags$span(style = "margin-left: 20px;", "FEA-ther")
    ),
    titleWidth = 230
  ),
  
  # -----------------------------------------
  # Sidebar, with images, custom color and a full file input suite
  # -----------------------------------------
  
  dashboardSidebar(
    sidebarMenu(
      menuItem("Home", tabName = "home", icon = icon('dove'), selected = TRUE),
      fileInput("file", "Choose a File", width = '100%', placeholder = "Your CSV", buttonLabel = 'Import'),
      fluidRow(column(4, checkboxInput("header", "Header", TRUE)), 
               column(8, selectInput("separator", 'Separator', choices = c('Comma', 'Tab', 'Space', 'Dot')))),
      tags$hr(style = "border: 1.5px solid #5c2a5c;"),
      selectInput("organism", 'Select an organism name', choices = c('Homo sapiens', "Quercus robur")),
      tags$hr(style = "border: 1.5px solid #5c2a5c;"),
      sidebarMenu(
        customMenuItem("  Whole Data Inspection", "item_1", "item.png"), # Use this custom function to add an image for max fun
        customMenuItem("  Go Term Enrichement
", "item_2", "item.png"),
        customMenuItem("  Pathway Enrichement", "item_3", "item.png")
      ),
      sidebarMenu(menuItem("About", tabName = "about", icon = icon("info-circle")))
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
      tabItem(tabName = "home",
              h2("Functional Enrichment Analysis"),
              fluidRow(
                box(title = "Volcano Plot", width = 7, withSpinner(plotOutput("plot_1", height = 250))),
                box(title = "Options", width = 5, 
                    sliderInput("p_val_slider","P-value cutoff from input", 0, 1, 0.05, step = 0.01),
                    sliderInput("log2FC_slider","log2 FoldChange cutoff from input:", 0, 5, 1, step = 0.1),
                    downloadButton("download", label = "Download volcano plot"))
              ),
              fluidRow(box(width = 12, withSpinner(dataTableOutput("table"))))  # Add spinner to the table
      ),
      # Create the about tab from custom function
      aboutTab()
    )
  )
)
