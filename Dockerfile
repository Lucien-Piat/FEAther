# -----------------------------------------
# Project: FEA-ther (Functional Enrichment Analysis Tool)
# Author: Maël Louis, Antoine Malet and Lucien Piat 
# Affiliation: Rouen Normandie University
# Creation: 04/10/2024
# Last update : 08/05/2025
# -----------------------------------------

# Use the Rocker Shiny image as the base
FROM rocker/shiny:latest

# Install system dependencies required for R packages
RUN apt-get update && apt-get install -y \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install CRAN packages required by the app
RUN R -e "install.packages(c('shiny', 'shinycssloaders', 'shinyalert', 'shinydashboard', \
    'dashboardthemes', 'DT', 'shinyjs', 'ggplot2', 'data.table', \
    'dplyr', 'plotly', 'shinyBS'), repos = 'https://cran.rstudio.com/')"

# Install Bioconductor packages
RUN R -e "install.packages('BiocManager', repos = 'https://cran.rstudio.com/')" \
    && R -e "BiocManager::install(c('clusterProfiler', 'org.Mm.eg.db', 'org.Hs.eg.db'), ask = FALSE)"

# Create a directory for the Shiny app
RUN mkdir -p /srv/shiny-server/FEAther

# Copy the Shiny app files into the Docker image
COPY . /srv/shiny-server/FEAther

# Copy custom Shiny Server configuration
COPY shiny-server.conf /etc/shiny-server/shiny-server.conf

# Expose the port that Shiny Server listens on
EXPOSE 3838

# Start Shiny Server
CMD ["/usr/bin/shiny-server"]
