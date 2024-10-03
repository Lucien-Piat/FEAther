# Install the required packages
list.of.packages <- c("shinycssloaders", "shinyalert", "shinydashboard")
new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[,"Package"])]
if(length(new.packages)) install.packages(new.packages)

# Load the packages
library("shinycssloaders")
library("shinyalert")
library("shinydashboard")




dashboardPage(
  dashboardHeader(title = "FEA"),
  dashboardSidebar(
        fileInput("file", "Chosir un Fichier", width= '100%', placeholder = "Your CSV", buttonLabel = 'Import'),
        selectInput("organism", 'Select a organism name', choices = c('Homo sapiens',"Quercus robur")), 
        
  ),
  
  
  
  
  dashboardBody(
    fluidRow(
      box(
        title = "Box 1", plotOutput("plot_1", height = 250), solidHeader= TRUE, background = "fuchsia"
        ),
      box(
        title = "Box 2", plotOutput("plot_2", height = 250), background = "fuchsia"
        )
    ), 
    fluidRow(
      box(width = 7, 
        sliderInput("slider", "Slider", 1, 100, 50)
      ),
      box(width = 3, 
        downloadButton("download", label = "Download", class = NULL)
      )
    ),
    fluidRow(
      box(width = 12, 
          dataTableOutput("table")
      )
    )
  )
)