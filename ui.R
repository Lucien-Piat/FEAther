
# -----------------------------------------
# Project: FEA-ther (Functional Enrichment Analysis Tool)
# Author: Maël Louis, Antoine Malet and Lucien Piat 
# Affiliation: Rouen Normandie University
# Creation: 04/10/2024
# Last update: 18/11/2024
# -----------------------------------------
library("shiny")
library("shinycssloaders")
library("shinyalert")
library("shinydashboard")
library("dashboardthemes")
library("DT")
library("plotly")
library("data.table")
source("functions.R")
library("shinyjs")
library("shinyBS")
source(file.path("www", "custom_theme.R"))

# UI object of the app
ui <- dashboardPage(
  title = "FEA-ther", # Title for the tab name in browser,
  
  # -----------------------------------------
  # HEADER, with an image
  # -----------------------------------------
  custom_dashboard_header(),
  
  # -----------------------------------------
  # Sidebar, with images, custom color and a full file input suite
  # -----------------------------------------
  dashboardSidebar(
    sidebarMenu(
      # Add a custom home on top with image
      custom_home(),
      
      # Input options
      fileInput("file", "Choose a File", width = "100%", placeholder = "Your CSV", buttonLabel = "Import"),
      tags$hr(style = "border: 1.5px solid #5c2a5c;"),
      selectInput("organism", "Select an organism name", choices = c("Mus musculus", "Homo sapiens")),
      tags$hr(style = "border: 1.5px solid #5c2a5c;"),
      
      # Add the menu
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
    # Use the custom theme
    customTheme,
    tags$head(tags$style(HTML(".box { border-top: 3px solid #61b644; }"))),
    
    # Define tab items
    tabItems(
      # Whole data inspection, plot
      tabItem(
        tabName = "whole_data_inspection_mitem",
        h2("Whole Data Inspection"),
        fluidRow(
          # Add plot (replaced ggiraphOutput with plotlyOutput)
          box(title = "Volcano Plot", width = 7, withSpinner(plotlyOutput(outputId = "volcano_plot"))),
          # Add two sliders
          box(
            title = "Options", width = 5,
            sliderInput("p_val_slider", "P-value cutoff from input", 0, 1, 0.05, step = 0.01),
            sliderInput("log2FC_slider", "log2 FoldChange cutoff from input:", 0, 4, 1, step = 0.01),
            
            # Download button
            fluidRow(
              column(12, tags$div(style = "text-align: left;", downloadButton("download", label = "Download Table (CSV)")))
            ),
            fluidRow(
              column(12, tags$div(style = "text-align: left;", tags$p(style = "color: balck;", "The table is filtered based on the pan/zoom of the plot AND the sliders")))
            )
          )
        ),
        # Add the table with a spinner
        fluidRow(box(title = "Filtered table", width = 12, withSpinner(dataTableOutput("table"))))
      ),
      
      tabItem(
        tabName = "go_term_enrichment_mitem",
        h2("GO Term Enrichment"),
        h3('Over-Representation Analysis (ORA)'),
        # Controls for enrichment analysis
        fluidRow(
          
          column(3, selectInput("ontology", "Ontology:", 
                                choices = c("Biological Process" = "BP", 
                                            "Molecular Function" = "MF", 
                                            "Cellular Component" = "CC",
                                            "All" = "ALL"), 
                                selected = "BP")),
          
          column(3, 
                 div(style = "display: flex; align-items: center;", 
                     selectInput("p_adjust_method", "P-Adjust Method:", 
                                 choices = c("Bonferroni" = "BH",
                                             "False Discovery Rate (FDR)" = "fdr"), 
                                 selected = "BH"),
                     tags$span(icon("info-circle"), id = "p_adjust_info", 
                               style = "cursor: pointer; margin-left: 5px;") 
                 )
          ),
          
          bsTooltip(id = "p_adjust_info", title = "P.value adjustment method, for more information click on the about tab", 
                    placement = "right", trigger = "hover"),
          
          column(2, 
                 radioButtons("representation_filter", "Select Representation Type:", 
                              choices = c(
                                "⬆️ Over-represented" = "over", 
                                "⬇️ Under-represented" = "under", 
                                "🔀 Both" = "both"
                              ), 
                              selected = "both", 
                              inline = FALSE)  # Ensure vertical stacking
          ), 
          column(2, 
                 tags$div(
                   style = "background-color: rgb(64,147,83); padding: 15px; border-radius: 30px; text-align: center; color: white;",
                   actionButton("enrich_button", 
                                label = " Start ORA", 
                                icon = icon("rocket"),   # Changed icon from "search" to "rocket"
                                style = "background-color:rgb(209,219,39); color: black; 
                               border-radius: 30px; padding: 10px; font-size: 15px;")
                 )
          )
          
        ),
        tags$hr(),
        
        # Slider for controlling the number of GO terms shown
        fluidRow(
          column(7, 
                 sliderInput("show_category", 
                             label = "Number of Terms to Plot:", 
                             min = 5, max = 50, value = 15, step = 1))
        ),
        
        # Plots: Tabs for different ORA visualizations
        tabsetPanel(
          tabPanel("Dot Plot", withSpinner(plotOutput(outputId = "go_plot", height = 600))),
          tabPanel("Bar Plot", withSpinner(plotOutput(outputId = "barplot", height = 600))),
          tabPanel("Net Plot", withSpinner(plotOutput(outputId = "emapplot", height = 600))),
          tabPanel("Tree Plot", withSpinner(plotOutput(outputId = "treeplot", height = 600)))
        )
      ), 
      
      tabItem(
        tabName = "pathway_enrichment_mitem",
        h2("Pathway Enrichment"),
        tags$div(style = "text-align: center;", tags$img(src = "dodo.png", height = "100", alt = "dodo")),
        p("#TODO")
      ),
      
      # Create the about tab from custom function
      aboutTab()
    )
  )
)
