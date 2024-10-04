# Install the required packages
list.of.packages <- c("shinycssloaders", "shinyalert", "shinydashboard", "dashboardthemes", "DT")
new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[,"Package"])]
if(length(new.packages)) install.packages(new.packages)

# Load the packages
library(shinycssloaders)
library(shinyalert)
library(shinydashboard)
library(dashboardthemes)
library(DT)


customMenuItem <- function(label, tabName, imgSrc, imgHeight = "30px", imgWidth = "30px") {
  tags$li(class = "nav-item", 
          tags$a(href = "#", class = "nav-link", 
                 tags$img(src = imgSrc, height = imgHeight, width = imgWidth),
                 label, 
                 `data-toggle` = "tab", `data-value` = tabName
          )
  )
}

customTheme <- shinyDashboardThemeDIY(
  ### general
  appFontFamily = "Helvetica",
  appFontColor = "rgb(31,59,100)",
  primaryFontColor = "rgb(31,59,100)",
  infoFontColor = "rgb(31,59,100)",
  successFontColor = "rgb(31,59,100)",
  warningFontColor = "rgb(31,59,100)",
  dangerFontColor = "rgb(31,59,100)",
  bodyBackColor = "rgb(189,196,209)",
  
  ### header
  logoBackColor = "rgb(35,114,117)",
  
  headerButtonBackColor = "rgb(34,117,53)",
  headerButtonIconColor = "rgb(255,255,255)",
  headerButtonBackColorHover = "rgb(209,219,39)",
  headerButtonIconColorHover = "rgb(0,0,0)",
  
  headerBackColor = "rgb(238,238,238)",
  headerBoxShadowColor = "#aaaaaa",
  headerBoxShadowSize = "2px 2px 2px",
  
  ### sidebar
  sidebarBackColor = "rgb(64,147,83)",
  sidebarPadding = 0,
  
  sidebarMenuBackColor = "rgb(34,117,53)",
  sidebarMenuPadding = 0,
  sidebarMenuBorderRadius = 0,
  
  sidebarShadowRadius = "3px 5px 5px",
  sidebarShadowColor = "#aaaaaa",
  
  sidebarUserTextColor = "rgb(255,255,255)",
  
  sidebarSearchBackColor = "rgb(55,72,80)",
  sidebarSearchIconColor = "rgb(153,153,153)",
  sidebarSearchBorderColor = "rgb(55,72,80)",
  
  sidebarTabTextColor = "rgb(255,255,255)",
  sidebarTabTextSize = 18,
  sidebarTabBorderStyle = "none none solid none",
  sidebarTabBorderColor = "rgb(100,60,100)",
  sidebarTabBorderWidth = 3,
  
  sidebarTabBackColorSelected = "rgb(209,219,39)",
  sidebarTabTextColorSelected = "rgb(31,59,100)",
  sidebarTabRadiusSelected = "30px 30px 30px 30px",
  
  sidebarTabBackColorHover ="rgb(209,219,39)",
  sidebarTabTextColorHover = "rgb(31,59,100)",
  sidebarTabBorderStyleHover = "none none solid none",
  sidebarTabBorderColorHover = "rgb(100,60,100)",
  sidebarTabBorderWidthHover = 3,
  sidebarTabRadiusHover = "30px 30px 30px 30px",
  
  ### boxes
  boxBackColor = "rgb(255,255,255)",
  boxBorderRadius = 5,
  boxShadowSize = "0px 5px 5px",
  boxShadowColor = "rgba(0,0,0,.1)",
  boxTitleSize = 16,
  boxDefaultColor = "rgb(210,214,220)",
  boxPrimaryColor = "rgba(44,222,235,1)",
  boxInfoColor = "rgb(210,214,220)",
  boxSuccessColor = "rgba(0,255,213,1)",
  boxWarningColor = "rgb(244,156,104)",
  boxDangerColor = "rgb(255,88,55)",
  
  tabBoxTabColor = "rgb(255,255,255)",
  tabBoxTabTextSize = 14,
  tabBoxTabTextColor = "rgb(0,0,0)",
  tabBoxTabTextColorSelected = "rgb(0,0,0)",
  tabBoxBackColor = "rgb(255,255,255)",
  tabBoxHighlightColor = "rgba(44,222,235,1)",
  tabBoxBorderRadius = 5,
  
  ### inputs
  buttonBackColor = "rgb(245,245,245)",
  buttonTextColor = "rgb(31,59,100)",
  buttonBorderColor = "rgb(31,59,100)",
  buttonBorderRadius = 5,
  
  buttonBackColorHover = "rgb(235,235,235)",
  buttonTextColorHover = "rgb(100,100,100)",
  buttonBorderColorHover = "rgb(200,200,200)",
  
  textboxBackColor = "rgb(255,255,255)",
  textboxBorderColor = "rgb(200,200,200)",
  textboxBorderRadius = 5,
  textboxBackColorSelect = "rgb(245,245,245)",
  textboxBorderColorSelect = "rgb(200,200,200)",
  
  ### tables
  tableBackColor = "rgb(144,227,153)",
  tableBorderColor = "rgb(114,197,133)",
  tableBorderTopSize = 1,
  tableBorderRowSize = 1
)

# Create the dashboard
dashboardPage(
  dashboardHeader(
    title = tags$div(
      style = "display: flex; align-items: center;",  
      tags$img(src = "logo.png", height = "50px"),   
      tags$span(style = "margin-left: 20px;", "FEA-ther") 
    ),
    titleWidth = 230
  ),
  
  dashboardSidebar(
    sidebarMenu(
      menuItem("Home", tabName = "home", icon = icon("dashboard"), selected = TRUE),

      fileInput("file", "Chosir un Fichier", width = '100%', 
                placeholder = "Your CSV", buttonLabel = 'Import'),
      fluidRow(
        column(4, checkboxInput("header", "Header", TRUE)),
        column(8, selectInput("separator", 'Separator', 
                              choices = c('Comma', 'Tab', 'Space', 'Dot')))
      ),
      tags$hr(style = "border: 1.5px solid #5c2a5c;"),
      selectInput("organism", 'Select an organism name', 
                  choices = c('Homo sapiens', "Quercus robur")),
      tags$hr(style = "border: 1.5px solid #5c2a5c;"), 
      sidebarMenu(
        customMenuItem("  Item 1", "item_1", "item.png"),
        customMenuItem("  Item 2", "item_2", "item.png"),
        customMenuItem("  Item 3", "item_3", "item.png"),
        customMenuItem("  Item 4", "item_4", "item.png")
        
      )
    ),
    # Separate section for About at the bottom
    sidebarMenu(
      menuItem("About", tabName = "about", icon = icon("info-circle"))
    )
  ),
  
  dashboardBody(
    customTheme,
    tags$head(
      tags$style(HTML("
        .box { 
          border-top: 3px solid #61b644; 
        }
      "))
    ),
    
    # Define tab items
    tabItems(
      tabItem(tabName = "home",
              
              h2("Functional Enrichment Analysis"),
              
              fluidRow(
                box(title = "Box 1", plotOutput("plot_1", height = 250)),
                box(title = "Box 2", plotOutput("plot_2", height = 250))
              ),
              fluidRow(
                box(width = 9, 
                    sliderInput("slider", "Slider", 1, 100, 50)),
                
                downloadButton("download", label = "Download")
              ),
              fluidRow(
                box(width = 12, 
                    dataTableOutput("table"))
              )
      ),
      tabItem(tabName = "about",
              h2("FEA-ther, Functional Enrichement Analysis"),
              p("Is a tool coded by Lucien PIAT for M2.1 BIMS à Rouen Normandie University"),
              p(), 
              p(), 
              p(), 
              p("Go to the github : https://github.com/Lucien-Piat/FEAther"),
              
      )
    )
  )
)