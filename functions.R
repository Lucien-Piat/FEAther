# -----------------------------------------
# Project: FEA-ther (Functional Enrichment Analysis Tool)
# Author: Lucien Piat
# Affiliation: Rouen Normandie University
# Date: 04/10/2024
# Description: Functions for the project
# -----------------------------------------

# Function to create a custom sidebar menu item with an image
#
#@return a tabItem for the about section
homeTab <- function() {
  tabItem(tabName = "home_mitem", 
          h2("FEA-ther, Functional Enrichment Analysis"),
          p("This tool was coded by Lucien Piat for the M2.1 BIMS program at Rouen Normandie University."),
          p("The FEA-ther tool allows users to perform functional enrichment analysis on biological data."),
          p("Users can visualize the results through interactive plots and tables."),
          p("For more information or to contribute to the project, visit the GitHub repository:"),
          a(href = "https://github.com/Lucien-Piat/FEAther", 
            "https://github.com/Lucien-Piat/FEAther")
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