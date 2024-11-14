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
source("ui.R")

# Install the packages
required_packages <- c("shiny", "shinycssloaders", "shinyalert", "shinydashboard",
                       "dashboardthemes", "DT", "ggiraph", "zip", "ggplot2", "data.table")
load_required_packages(required_packages)

# Import the custom theme
source("custom_theme.R")

shinyApp(ui, server)
