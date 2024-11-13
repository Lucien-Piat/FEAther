# -----------------------------------------
# Project: FEA-ther (Functional Enrichment Analysis Tool)
# Author: Lucien Piat
# Affiliation: Rouen Normandie University
# Date: 04/10/2024
# Description: Functions for the project
# -----------------------------------------


check_and_install_packages <- function(packages) {
  # Identify packages that are not installed
  new_packages <- packages[!(packages %in% installed.packages()[, "Package"])]
  
  # Install missing packages
  if (length(new_packages)) {
    install.packages(new_packages)
  }
  
  # Load all required packages
  lapply(packages, require, character.only = TRUE)
}


create_dashboard_header <- function() {
  dashboardHeader(
    title = tags$div(style = "display: flex; align-items: center;",
                     tags$img(src = "logo.png", height = "50px"),
                     tags$span(style = "margin-left: 20px;", "FEA-ther")
    ),
    titleWidth = 230
  )
}

# Function to create a custom sidebar menu item with an image
#
#@return a tabItem for the about section
aboutTab <- function() {
  tabItem(tabName = "about", 
          h2("FEA-ther: Functional Enrichment Analysis Tool"),
          
          # Adding a brief description with bold keywords
          p("Welcome to the ", strong("FEA-ther"), " tool. This application was developed by ", strong("Lucien Piat"), 
            " as part of the M2.1 ", strong("Bioinformatics (BIMS) master"), 
            " at ", strong("Rouen Normandie University"), "."),
          
          p("FEA-ther allows users to perform ", strong("functional enrichment analysis"), " on ", 
            strong("biological data"), ". By using this tool, users can analyze and interpret biological data, ",
            "identifying significantly enriched ", strong("GO terms"), " and ", strong("pathways"), " associated with their datasets."),
          
          # Adding more details about the tool's capabilities
          p("The tool offers:", 
            tags$ul(
              tags$li("Interactive data upload with flexible file format support (", strong(".csv"), ", ", strong(".txt"), ", ", strong(".tsv"), ", ", strong(".dat"), ")."),
              tags$li("Data inspection with customizable ", strong("volcano plots"), " and ", strong("filtering options"), " for fine-tuned analysis."),
              tags$li("More to come..."),
            )),
          
          # Including an image (e.g., logo or illustrative image for context)
          tags$div(style = "text-align: center;",
                   tags$img(src = "logo.png", height = "200px", alt = "FEA-ther logo")
          ),
          
          # GitHub and contribution information
          p("For more information or to contribute to the project, please visit the project's ", 
            a(href = "https://github.com/Lucien-Piat/FEAther", "GitHub repository"), "."),
  )
}

# Function to trigger shinyalert error with a custom message
show_shiny_error <- function(title, message) {
  shinyalert::shinyalert(
    title = title,
    text = tags$div(
      tags$img(src = "dodo.png", height = "50px"),
      tags$p(message)
    ),
    type = "error",
    html = TRUE
  )
}