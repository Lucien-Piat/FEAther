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

# Load required libraries
library("shiny")
library("shinycssloaders")
library("shinyalert")
library("shinydashboard")
library("DT")
library("dashboardthemes")
library("ggiraph")
library("ggplot2")
library("data.table")
library("dplyr")

# Source external functions, server, UI, and custom theme before calling shinyApp
source("functions.R")     # Functions for your app
source("server.R")        # Server logic
source("ui.R")            # UI layout
source(file.path("www", "custom_theme.R"))  # Custom theme for your app

# Call shinyApp after everything is sourced
shinyApp(ui, server)
