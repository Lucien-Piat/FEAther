# -----------------------------------------
# Project: FEA-ther (Functional Enrichment Analysis Tool)
# Author: Lucien Piat
# Affiliation: Rouen Normandie University
# Creation: 04/10/2024
# Last update : 18/11/2024
# Description: This Shiny application allows users to perform functional enrichment analysis
#              on biological data. Users can upload CSV files, select options for analysis, and
#              visualize the results through interactive plots and tables.
#
# Usage: Load the required packages, upload your data, and follow the on-screen instructions.
# -----------------------------------------

# Load required libraries
library("shiny")

# Source external functions, server, UI, and custom theme before calling shinyApp
source("server.R")        # Server logic
source("ui.R")            # UI layout

# Call shinyApp after everything is sourced
shinyApp(ui, server)
