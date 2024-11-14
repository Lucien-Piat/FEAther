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

library("shiny")
library("shinycssloaders")
library("shinyalert")
library("shinydashboard")
library("DT")
library("dashboardthemes")
library("ggiraph")
library("ggplot2")
library("data.table")

# Import the custom theme
# Import the functions
source("functions.R")
source("server.R")
source("ui.R")
source("www/custom_theme.R")

shinyApp(ui, server)
