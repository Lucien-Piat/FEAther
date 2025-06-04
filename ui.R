# -----------------------------------------
# Project: FEA-ther (Functional Enrichment Analysis Tool)
# Author: Maël Louis, Antoine Malet and Lucien Piat 
# Affiliation: Rouen Normandie University
# Creation: 04/10/2024 | Last update: 02/06/2025
# -----------------------------------------

### NOTE 1, THIS CODE USE FUNCTIONS FROM THE FILE functions.R 
## THIS REDUCE THE CLUTTER HERE

### NOTE 2, WE USE A DEPRECATED FUNCTION FOR THE CUSTOM THEME BUT IT IS PRETTY

# Load libraries
library(shiny); library(shinycssloaders); library(shinyalert); library(shinydashboard)
library(dashboardthemes); library(DT); library(plotly); library(data.table)
library(shinyjs); library(shinyBS); library(shinybusy)

# Load custom modules
source("functions.R")
source(file.path("www", "custom_theme.R"))

# Main UI
ui <- dashboardPage(
  title = "FEA-ther",
  
  # Header with custom branding
  custom_dashboard_header(),
  
  # Sidebar navigation
  dashboardSidebar(
    sidebarMenu(
      custom_home(),
      fileInput("file", "Choose a File", width = "100%", 
                placeholder = "Your CSV", buttonLabel = "Import"),
      tags$hr(style = "border: 1.5px solid #5c2a5c;"),
      selectInput("organism", "Select an organism name", 
                  choices = c("Mus musculus", "Homo sapiens")),
      tags$hr(style = "border: 1.5px solid #5c2a5c;"),
      menuItem("About", tabName = "about", icon = icon("info-circle"), selected = TRUE),
      menuItem("  Whole Data Inspection", tabName = "whole_data_inspection_mitem", icon = icon("eye")),
      menuItem("  Go Term Enrichment", tabName = "go_term_enrichment_mitem", icon = icon("database")),
      menuItem("  Pathway Enrichment", tabName = "pathway_enrichment_mitem", icon = icon("repeat"))
    )
  ),
  
  # Main content area
  dashboardBody(
    shinyjs::useShinyjs(),
    add_busy_gif(
      src = "load.gif", # Add a cool loading gif when server is bisy
      height = 90,
      width = 90,
      position = "bottom-right",
      margins = c(20, 20) 
    ), 
    customTheme,
    tags$head(tags$style(HTML(".box { border-top: 3px solid #61b644; }"))),
    
    tabItems(
      # Data Inspection Tab
      tabItem(
        tabName = "whole_data_inspection_mitem",
        h2("Whole Data Inspection"),
        
        fluidRow(
          # Volcano plot with info tooltip
          box(
            title = div("Volcano Plot",
                        tags$span(icon("info-circle"), id = "volcano_plot_info",
                                  style = "cursor: pointer; margin-left: 10px; font-size: 0.8em;")),
            width = 7,
            withSpinner(plotlyOutput("volcano_plot")),
            bsTooltip(id = "volcano_plot_info",
                      title = "Use this plot to visualise the data. Points represent genes, with significance on Y-axis and fold change on X-axis.",
                      placement = "right", trigger = "hover")
          ),
          
          # Filtering controls
          box(
            title = "Options", width = 5,
            sliderInput("p_val_slider", "P-value cutoff from input", 
                        min = 0, max = 1, value = 0.05, step = 0.01),
            div(style = "display: flex; align-items: center;",
                sliderInput("log2FC_slider", "log2 FoldChange cutoff from input:", 
                            min = 0, max = 5, value = 0, step = 0.01),
                tags$span(icon("info-circle"), id = "log2fc_info",
                          style = "cursor: pointer; margin-left: 5px; margin-top: -20px;")),
            bsTooltip(id = "log2fc_info",
                      title = "Avoid changing this value from 0 and prefer using the more powerful p-value filter for statistical significance.",
                      placement = "right", trigger = "hover"),
            fluidRow(column(12, downloadButton("download", label = "Download Table (CSV)"))),
            fluidRow(column(12, tags$p("The table is filtered based on the pan/zoom of the plot AND the sliders.")))
          )
        ),
        
        # Filtered data table
        fluidRow(
          box(
            title = div("Filtered table",
                        tags$span(icon("info-circle"), id = "filtered_table_info",
                                  style = "cursor: pointer; margin-left: 10px; font-size: 0.8em;")),
            width = 12,
            withSpinner(dataTableOutput("table")),
            bsTooltip(id = "filtered_table_info",
                      title = "This table is filtered using the sliders and the plot current view. Zoom in the volcano plot to filter further.",
                      placement = "top", trigger = "hover")
          )
        )
      ),
      
      # GO Term Enrichment Tab
      tabItem(
        tabName = "go_term_enrichment_mitem",
        h2("GO Term Enrichment"),
        
        fluidRow(
          column(width = 12, 
                 tabsetPanel(id = "go_mode_tabs", type = "pills",
                             
                             # ORA Tab
                             tabPanel(
                               title = div(
                                 icon("chart-bar", style = "color: black;"),
                                 strong(" Over-Representation Analysis (ORA)", style = "color: black;"),
                                 tags$span(icon("info-circle"), id = "ora_method_info",
                                           style = "cursor: pointer; margin-left: 10px; font-size: 0.8em; color: black;")),
                               br(),
                               bsTooltip(id = "ora_method_info",
                                         title = "ORA tests if your significant genes, selected form the whole data inspection are enriched in specific GO terms.",
                                         placement = "bottom", trigger = "hover"),
                               
                               # ORA configuration
                               box(
                                 title = "ORA Configuration", width = 12,
                                 status = "primary", solidHeader = TRUE,
                                 enrichmentControlsUI(prefix = "ora", button_id = "ora_enrich_button", 
                                                      button_label = " Start ORA"),
                                 tags$hr(),
                                 fluidRow(column(7, sliderInput("ora_show_category", "Number of Terms to Plot:", 
                                                                min = 5, max = 50, value = 15, step = 1)))
                               ),
                               
                               # ORA outputs
                               oraPlotsUI(),
                               resultsTableUI(title = "ORA Results Table", output_id = "ego_table", 
                                              include_mode_switch = TRUE, mode_input_id = "ora_table_mode")
                             ),
                             
                             # GSEA Tab
                             tabPanel(
                               title = div(
                                 icon("dna", style = "color: black;"),
                                 strong(" Gene Set Enrichment Analysis (GSEA)", style = "color: black;"),
                                 tags$span(icon("info-circle"), id = "gsea_method_info",
                                           style = "cursor: pointer; margin-left: 10px; font-size: 0.8em; color: black;")),
                               br(),
                               bsTooltip(id = "gsea_method_info",
                                         title = "GSEA uses all genes ranked by expression change. Use when changes are subtle or spread across many genes, or when you want to avoid arbitrary cutoffs.",
                                         placement = "bottom", trigger = "hover"),
                               
                               # GSEA configuration
                               box(
                                 title = "GSEA Configuration", width = 12,
                                 status = "primary", solidHeader = TRUE,
                                 enrichmentControlsUI(prefix = "gsea", button_id = "gsea_enrich_button", 
                                                      button_label = " Start GSEA"),
                                 tags$hr(),
                                 fluidRow(column(7, sliderInput("gsea_show_category", "Number of Terms to Plot:", 
                                                                min = 5, max = 50, value = 15, step = 1)))
                               ),
                               
                               # GSEA outputs
                               gseaPlotsUI(),
                               resultsTableUI(title = "GSEA Results Table", output_id = "gsea_table")
                             )
                 )
          )
        )
      ),
      
      # Pathway Enrichment Tab
      tabItem(
        tabName = "pathway_enrichment_mitem",
        h2("Pathway Enrichment Analysis"),
        
        # Pathway configuration box
        box(
          title = "Pathway Analysis Configuration", width = 12,
          status = "primary", solidHeader = TRUE,
          
          fluidRow(
            column(3,
                   # Database selection
                   div(style = "display: flex; align-items: center;",
                       selectInput("pathway_database", "Select Database:",
                                   choices = c("KEGG ⭐" = "KEGG", "Reactome" = "Reactome"),
                                   selected = "KEGG"),
                       tags$span(icon("info-circle"), id = "pathway_database_info",
                                 style = "cursor: pointer; margin-left: 5px;")),
                   bsTooltip(id = "pathway_database_info",
                             title = "KEGG: Focuses on metabolic & signaling pathways with visual pathway maps (⭐ recommended). Reactome: More detailed molecular interactions and reactions.",
                             placement = "right", trigger = "hover"),
                   
                   # Method selection
                   tags$hr(style = "margin: 10px 0;"),
                   div(style = "display: flex; align-items: center;",
                       radioButtons("pathway_method", "Enrichment Method:",
                                    choices = c("ORA" = "ORA", "GSEA" = "GSEA"),
                                    selected = "ORA", inline = FALSE),
                       tags$span(icon("info-circle"), id = "pathway_enrichment_method_info",
                                 style = "cursor: pointer; margin-left: 5px;")),
                   bsTooltip(id = "pathway_enrichment_method_info",
                             title = "ORA: Tests enrichment in your significant genes only. GSEA: Uses all genes ranked by fold change. Same principles as GO enrichment.",
                             placement = "right", trigger = "hover")
            ),
            
            column(9,
                   enrichmentControlsUI(prefix = "pathway", button_id = "pathway_enrich_button",
                                        button_label = " Start Pathway Analysis")
            )
          ),
          
          tags$hr(),
          
          fluidRow(
            column(7,
                   sliderInput("pathway_show_category", "Number of Pathways to Plot:",
                               min = 5, max = 50, value = 15, step = 1)),
            column(5,
                   tags$p(icon("lightbulb"),
                          "Tip: Start with default settings, then adjust based on results",
                          style = "color: #666; font-style: italic; margin-top: 20px;"))
          )
        ),
        
        # Pathway outputs
        pathwayPlotsUI(),
        resultsTableUI(title = "Pathway Enrichment Results", output_id = "pathway_table",
                       include_mode_switch = TRUE, mode_input_id = "pathway_table_mode")
      ),
      
      # About Tab
      aboutTab()
    )
  )
)