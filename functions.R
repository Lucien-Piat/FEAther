# -----------------------------------------
# Project: FEA-ther (Functional Enrichment Analysis Tool)
# Author: Maël Louis, Antoine Malet and Lucien Piat 
# Affiliation: Rouen Normandie University
# Creation: 04/10/2024
# Last update : 18/11/2024
# -----------------------------------------

# -----------------------------------------
# UI functions
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

# Function for the UI Ora plots
oraPlotsUI <- function() {
  tabsetPanel(
    tabPanel("Dot Plot", withSpinner(plotOutput("go_plot", height = 600))),
    tabPanel("Bar Plot", withSpinner(plotOutput("barplot", height = 600))),
    tabPanel("Net Plot", withSpinner(plotOutput("emapplot", height = 600))),
    tabPanel("Tree Plot", withSpinner(plotOutput("treeplot", height = 600)))
  )
}

#Function to display a table ORA + GSEA
resultsTableUI <- function(title, output_id, include_mode_switch = FALSE, mode_input_id = NULL) {
  fluidRow(
    box(
      title = title,
      width = 12,
      if (include_mode_switch) {
        radioButtons(
          inputId = mode_input_id,
          label = "Display Mode:",
          choices = c("Show stats" = "detailed", "Show genes" = "genes"),
          selected = "detailed",
          inline = TRUE
        )
      },
      DTOutput(output_id) %>% withSpinner()
    )
  )
}

enrichmentControlsUI <- function(prefix, button_id, button_label, tooltip_id = NULL) {
  tooltip_id <- tooltip_id %||% paste0(prefix, "_p_adjust_info")
  
  fluidRow(
    column(2, selectInput(paste0(prefix, "_ontology"), "Ontology:",
                          choices = c("Biological Process" = "BP",
                                      "Molecular Function" = "MF",
                                      "Cellular Component" = "CC",
                                      "All" = "ALL"),
                          selected = "BP")),
    
    column(3, div(style = "display: flex; align-items: center;",
                  selectInput(paste0(prefix, "_p_adjust_method"), "P-Adjust Method:",
                              choices = c("Bonferroni" = "BH",
                                          "False Discovery Rate (FDR)" = "fdr"),
                              selected = "BH"),
                  tags$span(icon("info-circle"), id = tooltip_id,
                            style = "cursor: pointer; margin-left: 5px;")
    )),
    
    bsTooltip(id = tooltip_id,
              title = "P.value adjustment method, for more information click on the about tab",
              placement = "right", trigger = "hover"),
    
    if (prefix != "gsea") {
      column(3, radioButtons(paste0(prefix, "_representation_filter"), "Select Representation Type:",
                             choices = c("⬆️ Over-represented" = "over",
                                         "⬇️ Under-represented" = "under",
                                         "🔀 Both" = "both"),
                             selected = "both", inline = FALSE))
    },
    
    column(4, tags$div(
      style = "background-color: rgb(64,147,83); padding: 3px; border-radius: 30px; text-align: center; color: white;
               display: inline-block; border: 8px solid rgb(64,147,83); box-sizing: border-box;",
      actionButton(button_id, label = button_label, icon = icon("rocket"),
                   style = "background-color:rgb(209,219,39); color: black; border: none; 
                            border-radius: 30px; padding: 10px 30px; font-size: 15px; text-align: center;")
    ))
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

# -----------------------------------------
# Server functions
# -----------------------------------------

# Create custom operator 
`%||%` <- function(a, b) if (!is.null(a)) a else b

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
  
  # Adjust show_category to avoid exceeding available terms
  n_terms <- nrow(ego@result)
  adjusted_category <- if (!is.null(show_category)) min(show_category, n_terms) else NULL
  
  # Generate the plot
  p <- if (!is.null(adjusted_category)) {
    plot_func(ego, showCategory = adjusted_category)
  } else {
    plot_func(ego)
  }
  
  # Apply custom theme or default minimal theme
  p <- p + (custom_theme %||% theme_minimal())
  
  # Ensure plot is rendered
  print(p)
}




