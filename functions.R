# -----------------------------------------
# Project: FEA-ther (Functional Enrichment Analysis Tool)
# Author: Lucien Piat
# Affiliation: Rouen Normandie University
# Creation: 04/10/2024
# Last update : 13/11/2024
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
            "Welcome to the ", strong("FEA-ther"), " tool. This application was developed by ", strong("Lucien Piat"),
            " as part of the M2.1 ", strong("Bioinformatics (BIMS) master"), " at ", strong("Rouen Normandie University"), "."
        ),
        p(
            "FEA-ther allows users to perform ", strong("functional enrichment analysis"), " on ", strong("biological data"),
            ". By using this tool, users can analyze and interpret biological data, identifying significantly enriched ",
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

# -----------------------------------------
# Logic functions
# -----------------------------------------

# Function to create volcanoplot with ggplot, coloring values within a threshold
# @df The input data
# @log2FC_cutoff The threshold for log2fc
# @pval_cutoff The threshold for p-value
# @return A ggplot
filtered_plot <- function(df, log2FC_cutoff, pval_cutoff) {
    df$log10_pval <- -log10(df$pval)
    df$color <- ifelse(df$pval >= pval_cutoff, "grey",
        ifelse(df$log2FC < -log2FC_cutoff, "red", ifelse(df$log2FC > log2FC_cutoff, "green", "grey"))
    )
    plot <- ggplot(df, aes(
        x = log2FC,
        y = log10_pval,
        tooltip = paste("Gene:", GeneName, "<br>ID:", ID, "<br>log2FC:", log2FC, "<br>-log10(pval):", log10_pval)
    )) +
        geom_point_interactive(aes(color = color), size = 1) +
        labs(x = "log2 Fold Change (log2FC)", y = "-log10(p-value)") +
        ylim(0, 10) +
        scale_color_identity() +
        theme_minimal() +
        theme(legend.position = "none")
    return(plot)
}
