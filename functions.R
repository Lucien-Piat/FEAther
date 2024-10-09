# -----------------------------------------
# Project: FEA-ther (Functional Enrichment Analysis Tool)
# Author: Lucien Piat
# Affiliation: Rouen Normandie University
# Date: 04/10/2024
# Description: Functions for the project
# -----------------------------------------


# Function to create a custom sidebar menu item with an image
# 
# @param label A string representing the text label for the menu item.
# @param tabName A string representing the tab name that this menu item will navigate to.
# @param imgSrc A string representing the source URL or path of the image to display next to the label.
# @param imgHeight A string specifying the height of the image (default is "20px").
# @param imgWidth A string specifying the width of the image (default is "20px").
#
# @return A tag list representing the custom sidebar menu item, which includes an image and a label.
#
# @examples
# # Example of creating a custom menu item
# customMenuItem("Item 1", "item_1", "item.png")
# 
customMenuItem <- function(label,
                           tabName,
                           imgSrc,
                           imgHeight = "20px",
                           imgWidth = "20px") {
  tags$li(
    class = "nav-item",
    tags$a(
      href = "#",
      class = "nav-link",
      tags$img(
        src = imgSrc,
        height = imgHeight,
        width = imgWidth
      ),
      label,
      `data-toggle` = "tab",
      `data-value` = tabName
    )
  )
}

# Function to create a custom sidebar menu item with an image
#
#@return a tabItem for the about section
aboutTab <- function() {
  tabItem(tabName = "about", 
          h2("FEA-ther, Functional Enrichment Analysis"),
          p("This tool was coded by Lucien Piat for the M2.1 BIMS program at Rouen Normandie University."),
          p("The FEA-ther tool allows users to perform functional enrichment analysis on biological data."),
          p("Users can visualize the results through interactive plots and tables."),
          p("For more information or to contribute to the project, visit the GitHub repository:"),
          a(href = "https://github.com/Lucien-Piat/FEAther", 
            "https://github.com/Lucien-Piat/FEAther")
  )
}   


