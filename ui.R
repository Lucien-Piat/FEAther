# -----------------------------------------
# Project: FEA-ther (Functional Enrichment Analysis Tool)
# Author: Maël Louis, Antoine Malet and Lucien Piat 
# Affiliation: Rouen Normandie University
# Creation: 04/10/2024 | Last update: 09/05/2025
# -----------------------------------------

# --- Load libraries ---
library(shiny); library(shinycssloaders); library(shinyalert); library(shinydashboard)
library(dashboardthemes); library(DT); library(plotly); library(data.table)
library(shinyjs); library(shinyBS)

# --- Load custom modules ---
source("functions.R")                          # Contains custom UI and logic components
source(file.path("www", "custom_theme.R"))     # Custom dashboard theme

# --- UI Definition ---
ui <- dashboardPage(
  title = "FEA-ther",  # Tab title in browser
  
  # --- Custom Header ---
  custom_dashboard_header(),
  
  # --- Sidebar with navigation and input ---
  dashboardSidebar(
    sidebarMenu(
      custom_home(),  # Branding/logo sidebar top
      fileInput("file", "Choose a File", width = "100%", placeholder = "Your CSV", buttonLabel = "Import"),
      tags$hr(style = "border: 1.5px solid #5c2a5c;"),
      selectInput("organism", "Select an organism name", choices = c("Mus musculus", "Homo sapiens")),
      tags$hr(style = "border: 1.5px solid #5c2a5c;"),
      menuItem("  Whole Data Inspection", tabName = "whole_data_inspection_mitem", icon = icon("eye"), selected = TRUE),
      menuItem("  Go Term Enrichment", tabName = "go_term_enrichment_mitem", icon = icon("database")),
      menuItem("  Pathway Enrichment", tabName = "pathway_enrichment_mitem", icon = icon("repeat")),
      menuItem("About", tabName = "about", icon = icon("info-circle"))
    )
  ),
  
  # --- Main dashboard content area ---
  dashboardBody(
    customTheme,  # Apply custom theme
    tags$head(tags$style(HTML(".box { border-top: 3px solid #61b644; }"))),  # Custom box style
    
    tabItems(
      
      # === Whole Data Inspection Tab ===
      tabItem(
        tabName = "whole_data_inspection_mitem",
        h2("Whole Data Inspection"),
        
        fluidRow(
          # --- Volcano Plot ---
          box(title = "Volcano Plot", width = 7, withSpinner(plotlyOutput("volcano_plot"))),
          
          # --- Controls for Plot Filtering ---
          box(title = "Options", width = 5,
              sliderInput("p_val_slider", "P-value cutoff from input", min = 0, max = 1, value = 0.05, step = 0.01),
              sliderInput("log2FC_slider", "log2 FoldChange cutoff from input:", min = 0, max = 4, value = 1, step = 0.01),
              fluidRow(column(12, downloadButton("download", label = "Download Table (CSV)"))),
              fluidRow(column(12, tags$p("The table is filtered based on the pan/zoom of the plot AND the sliders.")))
          )
        ),
        
        # --- Filtered Table Output ---
        fluidRow(box(title = "Filtered table", width = 12, withSpinner(dataTableOutput("table"))))
      ),
      
      # === GO Term Enrichment Tab (ORA + GSEA) ===
      tabItem(
        tabName = "go_term_enrichment_mitem",
        h2("GO Term Enrichment"),
        
        # Full-width container
        fluidRow(
          column(width = 12, tabsetPanel( id = "go_mode_tabs", type = "pills",  
              
              # --- ORA Tab ---
              tabPanel(
                title = div(
                  icon("chart-bar", style = "color: black;"),
                  strong(" Over-Representation Analysis (ORA)", style = "color: black;")),br(),
      
                # --- ORA Input Controls ---
                h3("ORA Configuration"),
                enrichmentControlsUI(prefix = "ora", button_id = "ora_enrich_button", button_label = " Start ORA"),
                tags$hr(),
                
                # --- ORA Plot Controls ---
                fluidRow(column(7, sliderInput("ora_show_category", "Number of Terms to Plot:", min = 5, max = 50, value = 15, step = 1))),
                
                # --- ORA Plots Output ---
                oraPlotsUI(),
                
                # --- ORA Results Table ---
                resultsTableUI(title = "ORA Results Table", output_id = "ego_table", include_mode_switch = TRUE, mode_input_id = "ora_table_mode")
              ),
              
              # --- GSEA Tab ---
              tabPanel(
                title = div(
                  icon("dna", style = "color: black;"),
                  strong(" Gene Set Enrichment Analysis (GSEA)", style = "color: black;")),br(),
                
                # --- GSEA Input Controls ---
                h3("GSEA Configuration"),
                enrichmentControlsUI(prefix = "gsea", button_id = "gsea_enrich_button", button_label = " Start GSEA"),
                
                # --- GSEA Plot Controls ---
                fluidRow(column(7, sliderInput("gsea_show_category", "Number of Terms to Plot:", min = 5, max = 50, value = 15, step = 1))),
                
                # --- GSEA Plots ---
                gseaPlotsUI(),
                
                # --- GSEA Results Table ---
                resultsTableUI(title = "GSEA Results Table", output_id = "gsea_table")
              )
            )
          )
        )
      ),
      
      # === Pathway Enrichment Placeholder Tab ===
      tabItem(
        tabName = "pathway_enrichment_mitem",
        h2("Pathway Enrichment"),
        tags$div(style = "text-align: center;", tags$img(src = "dodo.png", height = "100", alt = "dodo")),
        p("#TODO: Pathway analysis module coming soon.")
      ),
      
      # === About Tab ===
      aboutTab()
    )
  )
)
