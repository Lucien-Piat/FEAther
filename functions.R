# -----------------------------------------
# Project: FEA-ther (Functional Enrichment Analysis Tool)
# Author: Maël Louis, Antoine Malet and Lucien Piat 
# Affiliation: Rouen Normandie University
# Creation: 04/10/2024
# Last update : 18/11/2024
# -----------------------------------------

# -----------------------------------------
# Graphic functions
# -----------------------------------------

# Function to create a custom header with an image
custom_dashboard_header <- function() {
    dashboardHeader(
        title = tags$div(
            style = "display: flex; align-items: center;",
            tags$img(src = "logo.png", height = "50px"),
            tags$span(style = "margin-left: 20px;", "FEA-ther")
        ),
        titleWidth = 230
    )
}

# Function to create a custom unclickable home button with an image
custom_home <- function() {
    tags$li(
        class = "nav-item",
        tags$a(
            href = "#",
            class = "nav-link",
            "Home, select your analysis ↓",
            style = "font-size: 14px;",
            tags$img(src = "item.png", height = "30px", style = "margin-left: 0px;")
        )
    )
}

# Function to create the about tab with useful infos
aboutTab <- function() {
  tabItem(
    tabName = "about",
    h2("FEA-ther: Functional Enrichment Analysis Tool"),
    p(
      "Welcome to the ", strong("FEA-ther"), " tool. This application was developed by ", strong("Maël Louis, Antoine Malet, and Lucien Piat"),
      " as part of the M2.1 ", strong("Bioinformatics (BIMS) master"), " at ", strong("Rouen Normandie University"), "."
    ),
    p(
      "FEA-ther allows users to perform ", strong("functional enrichment analysis"), " on biological data.",
      " By using this tool, users can analyze and interpret biological data, identifying significantly enriched ",
      strong("GO terms"), " and ", strong("pathways"), " associated with their datasets."
    ),
    p("The tool offers:", tags$ul(
      tags$li(
        "Interactive data upload with flexible file format support (", strong(".csv"), ", ", strong(".txt"),
        ", ", strong(".tsv"), ", ", strong(".dat"), ")."
      ),
      tags$li(
        "Data inspection with customizable ", strong("volcano plots"), " and ", strong("filtering options"),
        " for fine-tuned analysis."
      ),
      tags$li("Output of the plot and table"),
      tags$li("More to come...")
    )),
    tags$div(
      style = "text-align: center;",
      tags$img(src = "logo.png", height = "200px", alt = "FEA-ther logo")
    ),
    h3("P-Value Adjustment Methods"),
    p(
      "When performing multiple statistical tests, the chance of obtaining false-positive results increases.",
      " To address this, several p-value adjustment methods have been developed to control error rates."
    ),
    tags$ul(
      tags$li(
        strong("Bonferroni Correction:"),
        "Bonferroni Correction: This method adjusts p-values by multiplying them by the number of comparisons, offering a straightforward approach to control the family-wise error rate.",
      ),
      tags$li(
        strong("False Discovery Rate (FDR)"),
        "The False Discovery Rate (FDR) is the expected proportion of incorrect rejections (false positives) among all rejected null hypotheses in multiple testing scenarios. It helps balance identifying significant results and limiting false positives. ",
      )
    ),
    p(
      "For more information, please visit the project's ",
      a(href = "https://github.com/Lucien-Piat/FEAther", "GitHub repository"), "."
    )
  )
}


# Function to trigger shinyalert error with a custom message
# @title Title of the popup
# @message Printed message of the popup
show_shiny_error <- function(title, message) {
    shinyalert::shinyalert(
        title = title,
        text = tags$div(tags$img(src = "dodo.png", height = "50px"), tags$p(message)),
        type = "error",
        html = TRUE
    )
}

# Function to generate enrichment plots for GO analysis
# 
# @param plot_func The plotting function to use (e.g., dotplot, barplot, heatplot, emapplot)
# @param ego The result of GO enrichment analysis (ORA)
# @param show_category Number of categories to display in the plot (if applicable)
# @param custom_theme (Optional) Custom ggplot2 theme to apply
# @param use_pairwise_sim (Optional) If TRUE, computes pairwise term similarity before plotting (for emapplot)
#
# @details
# This function first checks if `ego` contains significant GO terms.
# If not, it displays a message indicating that no enrichment was found.
# If `use_pairwise_sim = TRUE`, it computes term similarity before plotting.
# Otherwise, it directly generates the plot using `plot_func`.

render_go_plot <- function(plot_func, ego, show_category = NULL, custom_theme = NULL, use_pairwise_sim = FALSE) {
  # Check if the enrichment object exists and contains results
  if (is.null(ego) || nrow(ego@result) == 0) {
    plot(1, type = "n", axes = FALSE, xlab = "", ylab = "")
    text(1, 1, "No significant GO terms found", col = "red", cex = 1.5)
    return()
  }
  
  # Compute pairwise similarity if needed (for emapplot)
  if (use_pairwise_sim) {
    ego <- enrichplot::pairwise_termsim(ego)
    if (is.null(ego) || nrow(ego@termsim) == 0) {
      plot(1, type = "n", axes = FALSE, xlab = "", ylab = "")
      text(1, 1, "No term similarity available", col = "red", cex = 1.5)
      return()
    }
  }
  
  # Generate the plot
  p <- if (!is.null(show_category)) {
    plot_func(ego, showCategory = show_category)
  } else {
    plot_func(ego)  # Some plots do not require showCategory
  }
  
  # Apply custom theme or default minimal theme
  p <- p + (custom_theme %||% theme_minimal())
  
  # Ensure plot is rendered
  print(p)
}

  
