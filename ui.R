# -----------------------------------------
# Project: FEA-ther (Functional Enrichment Analysis Tool)
# Author: Lucien Piat
# Affiliation: Rouen Normandie University
# Creation: 04/10/2024
# Last update : 13/11/2024
# Description: This Shiny application allows users to perform functional enrichment analysis
#              on biological data. Users can upload CSV files, select options for analysis, and 
#              visualize the results through interactive plots and tables.
#
# Usage: Load the required packages, upload your data, and follow the on-screen instructions.
# -----------------------------------------

# Import the functions
source("functions.R")
source("server.R")



#Install the packages
required_packages <- c(
  "shiny", "shinycssloaders", "shinyalert", "shinydashboard", 
  "dashboardthemes", "DT", "ggiraph", "zip", "ggplot2", "data.table"
)
load_required_packages(required_packages)

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
      #Add a custome home on top with image
      custom_home(),
      
      #Input options
      fileInput("file", "Choose a File", width = '100%', placeholder = "Your CSV", buttonLabel = 'Import'),
      tags$hr(style = "border: 1.5px solid #5c2a5c;"),
      selectInput("separator", 'Separator', choices = c('Auto', 'Semicolon', 'Comma', 'Tab', 'Space', 'Dot')),
      tags$hr(style = "border: 1.5px solid #5c2a5c;"),
      selectInput("organism", 'Select an organism name', choices = c('Pavo cristatus', "Afropavo congensis", "Pavo muticus")),
      tags$hr(style = "border: 1.5px solid #5c2a5c;"),
      
      #Add the menu 
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
    #Use the custom theme
    customTheme,
    tags$head(tags$style(HTML(".box { border-top: 3px solid #61b644; }"))),
    
    # Define tab items
    tabItems(
      #Whole data inspection, plot
      tabItem(tabName = "whole_data_inspection_mitem",
              h2("Whole Data Inspection"),
              fluidRow(
                #Add plot
                box(title = "Volcano Plot", width = 7, withSpinner(girafeOutput("volcano_plot", height = 400))),
                #Add two sliders
                box(title = "Options", width = 5, 
                    sliderInput("p_val_slider", "P-value cutoff from input", 0, 1, 0.05, step = 0.01),
                    sliderInput("log2FC_slider", "log2 FoldChange cutoff from input:", 0, 5, 1, step = 0.1),
                    
                    # Create a fluidRow for the radio button and download button side by side
                    # First column for the radio button
                    fluidRow(
                      column(5, 
                             radioButtons("downloadType", "Select what to download:",
                                          choices = c("Plot (PNG)" = "plot", "Table (CSV)" = "table"),
                                          selected = "plot")
                      ),
                      # Second column for the download button
                      column(6, 
                             tags$div(style = "height: 30px;"),  
                             tags$div(style = "text-align: left;",
                                      downloadButton("download", label = "Download")
                             )
                      )
                    )
                )
              ),
              #Add the table with a spinner
              fluidRow(box(title = "Filtered table", width = 12, withSpinner(dataTableOutput("table"))))
      ),
      
      #Placeholder for the future tabs
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
      
      # Create the about tab from custom function
      aboutTab() 
    )
  )
  
  
)
