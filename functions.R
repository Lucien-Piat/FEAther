# -----------------------------------------
# Project: FEA-ther (Functional Enrichment Analysis Tool)
# Author: Lucien Piat
# Affiliation: Rouen Normandie University
# Date: 04/10/2024
# Description: Functions for the project
# -----------------------------------------



# Function to load required packages
load_required_packages <- function(required_packages) {
  
  # Loop over each package and load it
  for (pkg in required_packages) {
    if (!requireNamespace(pkg, quietly = TRUE)) {
      install.packages(pkg)  # Install package if not already installed
    }
    library(pkg, character.only = TRUE)  # Load the package
  }
}


custom_dashboard_header <- function() {
  dashboardHeader(
    title = tags$div(style = "display: flex; align-items: center;",
                     tags$img(src = "logo.png", height = "50px"),
                     tags$span(style = "margin-left: 20px;", "FEA-ther")
    ),
    titleWidth = 230
  )
}

custom_home <- function(){
  tags$li(
    class = "nav-item",
    tags$a(
      href = "#",
      class = "nav-link",
      # Text first, then image on the right
      "Home, select your analysis ↓", style = "font-size: 14px;",  # Adjust font size as needed
      # Add image to the right of the text with some margin to the left
      tags$img(src = "item.png", height = "30px", style = "margin-left: 0px;")  # Adjust margin as needed
    )
  )
}



# Function to create a custom sidebar menu item with an image
#
#@return a tabItem for the about section
aboutTab <- function() {
  tabItem(tabName = "about", 
          h2("FEA-ther: Functional Enrichment Analysis Tool"),
          p("Welcome to the ", strong("FEA-ther"), " tool. This application was developed by ", strong("Lucien Piat"), 
            " as part of the M2.1 ", strong("Bioinformatics (BIMS) master"), 
            " at ", strong("Rouen Normandie University"), "."),
          p("FEA-ther allows users to perform ", strong("functional enrichment analysis"), " on ", 
            strong("biological data"), ". By using this tool, users can analyze and interpret biological data, ",
            "identifying significantly enriched ", strong("GO terms"), " and ", strong("pathways"), " associated with their datasets."),
          p("The tool offers:", 
            tags$ul(
              tags$li("Interactive data upload with flexible file format support (", strong(".csv"), ", ", strong(".txt"), ", ", strong(".tsv"), ", ", strong(".dat"), ")."),
              tags$li("Data inspection with customizable ", strong("volcano plots"), " and ", strong("filtering options"), " for fine-tuned analysis."),
              tags$li("More to come..."),
            )),
          tags$div(style = "text-align: center;",
                   tags$img(src = "logo.png", height = "200px", alt = "FEA-ther logo")
          ),
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