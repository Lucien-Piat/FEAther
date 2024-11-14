# FEA-ther (Functional Enrichment Analysis Tool)

## Overview
FEA-ther is a Shiny application designed for functional enrichment analysis of biological data. It allows users to upload CSV files, select various analysis options, and visualize results through interactive plots and tables. This tool is particularly useful for researchers and biologists who wish to gain insights from their data.

## Author
**Lucien Piat**  
Affiliation: Rouen Normandie University  
Date: 04/10/2024

## Features
- Data Upload: Accepts CSV, TXT, TSV, and DAT files with flexible format support.
- Data Inspection: Visual inspection of whole datasets, including customizable volcano plots.
- Customizable Output: Downloadable plots and tables in CSV and PNG formats.
_ User-Friendly Interface: A clear, intuitive interface with custom themes and error handling.

## Repository Structure
The file structure of the repository is as follows:
```bash
FEAther/
├── app.R                # Main file to run the Shiny app
├── server.R             # Server logic
├── ui.R                 # UI components and layout
├── functions.R          # Helper functions for graphics and data handling
├── www/                 # Directory for additional resources
│   ├── custom_theme.R   # Custom theme settings
│   ├── logo.png         
│   └── dodo.png          
└── Dockerfile           # Dockerfile to containerize the app
```
## Dependencies

To run the application, you need to have R and the following R packages installed:

- `shiny`
- `shinydashboard`
- `shinycssloaders`
- `shinyalert`
- `dashboardthemes`
- `DT`
- `ggiraph`
- `ggplot2`
- `data.table`

You can install these packages in R with:
```R
install.packages(c("shiny", "shinydashboard", "shinycssloaders", "shinyalert", 
                   "dashboardthemes", "DT", "ggiraph", "zip", "ggplot2", "data.table"))
```

## Running the App
### With RStudio
To run FEA-ther in RStudio:

Clone this repository to your local machine:


```bash
git clone https://github.com/yourusername/FEAther.git
cd FEAther
```

Open app.R in RStudio and ensure all files in the repository are loaded.
Install any missing packages (see the Installation section above).
Click Run App in RStudio.

### Running with Docker
To run FEA-ther in a Docker container:

From the root of the FEA-ther directory, build the Docker image:

```bash
docker build -t feather_app .
```

Once the build is complete, run the container:

```bash
docker run -p 3838:3838 feather_app
```
Open a web browser and go to http://localhost:3838 to use the FEA-ther application.

