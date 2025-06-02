# -----------------------------------------
# Project: FEA-ther (Functional Enrichment Analysis Tool)
# Author: Maël Louis, Antoine Malet and Lucien Piat 
# Affiliation: Rouen Normandie University
# Creation: 04/10/2024 | Last update : 18/11/2024
# -----------------------------------------

# ========== UI COMPONENT FUNCTIONS ==========

# Create custom dashboard header with logo
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

# Create custom home navigation item
custom_home <- function() {
  tags$li(
    class = "nav-item",
    tags$a(
      href = "#", class = "nav-link",
      "Home, select your analysis ↓",
      style = "font-size: 14px;",
      tags$img(src = "item.png", height = "30px", style = "margin-left: 0px;")
    )
  )
}

# UI component for ORA visualization tabs
oraPlotsUI <- function() {
  tabsetPanel(
    tabPanel("Dot Plot", withSpinner(plotOutput("go_plot", height = 600))),
    tabPanel("Bar Plot", withSpinner(plotOutput("barplot", height = 600))),
    tabPanel("Net Plot", withSpinner(plotOutput("emapplot", height = 600))),
    tabPanel("Tree Plot", withSpinner(plotOutput("treeplot", height = 600)))
  )
}

# UI component for GSEA visualization tabs
gseaPlotsUI <- function() {
  tabsetPanel(
    type = "tabs",
    tabPanel("Dot Plot", withSpinner(plotOutput("gsea_dotplot", height = 600))),
    tabPanel("Emap Plot", withSpinner(plotOutput("gsea_emapplot", height = 600))),
    tabPanel("Ridge Plot", withSpinner(plotOutput("gsea_ridgeplot", height = 600))),
    tabPanel("GSEA Plot ⭐", 
             fluidRow(
               column(12,
                      fluidRow(
                        column(9,
                               selectInput("gsea_pathway_select", "Choose pathway to visualize:", 
                                           choices = NULL, width = "100%")),
                        column(3,
                               tags$label("Download", style = "display: block; margin-bottom: 5px;"),
                               downloadButton("download_gsea_plot", "Download Plot", 
                                              style = "width: 100%;"))
                      ),
                      hr(),
                      withSpinner(plotOutput("gsea_gseaplot", height = 600))
               )
             )
    )
  )
}

# Generic results table UI component
resultsTableUI <- function(title, output_id, include_mode_switch = FALSE, mode_input_id = NULL) {
  fluidRow(
    box(
      title = title, width = 12,
      if (include_mode_switch) {
        radioButtons(
          inputId = mode_input_id, label = "Display Mode:",
          choices = c("Show stats" = "detailed", "Show genes" = "genes"),
          selected = "detailed", inline = TRUE
        )
      },
      DTOutput(output_id) %>% withSpinner()
    )
  )
}

# Generic enrichment controls UI component
enrichmentControlsUI <- function(prefix, button_id, button_label, tooltip_id = NULL) {
  tooltip_id <- tooltip_id %||% paste0(prefix, "_p_adjust_info")
  
  fluidRow(
    column(5,
           # P-value adjustment method selector
           div(style = "display: flex; align-items: center;",
               selectInput(paste0(prefix, "_p_adjust_method"), "P-Adjust Method:",
                           choices = c("Bonferroni" = "BH", "False Discovery Rate (FDR)" = "fdr"),
                           selected = "BH"),
               tags$span(icon("info-circle"), id = tooltip_id,
                         style = "cursor: pointer; margin-left: 5px;")),
           bsTooltip(id = tooltip_id,
                     title = "P-value adjustment method corrects for multiple testing. FDR is less stringent than Bonferroni. See About tab for details.",
                     placement = "right", trigger = "hover"),
           
           # Ontology selector
           tags$hr(style = "margin: 15px 0;"),
           div(style = "display: flex; align-items: center;",
               selectInput(paste0(prefix, "_ontology"), "Ontology:",
                           choices = c("Biological Process  " = "BP", "Molecular Function  " = "MF",
                                       "Cellular Component  " = "CC", "All" = "ALL"),
                           selected = "BP"),
               tags$span(icon("info-circle"), id = paste0(prefix, "_ontology_info"),
                         style = "cursor: pointer; margin-left: 5px;")),
           bsTooltip(id = paste0(prefix, "_ontology_info"),
                     title = "Gene Ontology categories: BP (what biological goals are accomplished), MF (molecular activities), CC (where in the cell it happens)",
                     placement = "right", trigger = "hover")
    ),
    
    # Representation filter (ORA only)
    if (prefix != "gsea") {
      column(3, radioButtons(paste0(prefix, "_representation_filter"), "Select Representation Type:",
                             choices = c("⬆️ Over-represented" = "over", "⬇️ Under-represented" = "under",
                                         "🔀 Both" = "both"),
                             selected = "both", inline = FALSE))
    } else {
      column(3)  # Empty column for layout consistency
    },
    
    # Action button
    column(6, tags$div(
      style = "background-color: rgb(64,147,83); padding: 3px; border-radius: 30px; text-align: center; color: white;
               display: inline-block; border: 8px solid rgb(64,147,83); box-sizing: border-box; float: right;",
      actionButton(button_id, label = button_label, icon = icon("rocket"),
                   style = "background-color:rgb(209,219,39); color: black; border: none; 
                            border-radius: 30px; padding: 10px 30px; font-size: 15px; text-align: center;")
    ))
  )
}

# Create comprehensive about tab
aboutTab <- function() {
  tabItem(
    tabName = "about",
    h2("FEA-ther: Functional Enrichment Analysis Tool"),
    
    # Introduction section
    fluidRow(
      box(
        title = "Welcome to FEA-ther", width = 12,
        status = "primary", solidHeader = TRUE,
        fluidRow(
          column(8,
                 p("FEA-ther is a comprehensive tool for ", strong("functional enrichment analysis"), " of biological data.",
                   " Developed by ", strong("Maël Louis, Antoine Malet, and Lucien Piat"),
                   " as part of the M2.1 ", strong("Bioinformatics (BIMS) master"), " at ", strong("Rouen Normandie University"), "."),
                 p("This application helps researchers identify significantly enriched biological functions, pathways, and processes",
                   " in their gene expression data, making it easier to understand the biological meaning behind experimental results.")
          ),
          column(4,
                 tags$div(style = "text-align: center;",
                          tags$img(src = "logo.png", height = "150px", alt = "FEA-ther logo"))
          )
        )
      )
    ),
    
    # Features and workflow
    fluidRow(
      box(
        title = icon("star", style = "color: #f39c12;", "Key Features"),
        width = 6, status = "warning",
        tags$ul(
          tags$li(icon("upload"), "Flexible file upload (CSV, TSV, TXT, DAT)"),
          tags$li(icon("chart-line"), "Interactive volcano plot visualization"),
          tags$li(icon("filter"), "Dynamic data filtering and exploration"),
          tags$li(icon("dna"), "GO term enrichment analysis"),
          tags$li(icon("project-diagram"), "Pathway enrichment (KEGG & Reactome)"),
          tags$li(icon("download"), "Exportable results and visualizations"),
          tags$li(icon("chart-bar"), "Multiple enrichment methods (ORA & GSEA)")
        )
      ),
      
      box(
        title = icon("route", style = "color: #27ae60;", "Analysis Workflow"),
        width = 6, status = "success",
        tags$ol(
          tags$li("Upload your differential expression data"),
          tags$li("Explore data with interactive volcano plot"),
          tags$li("Filter genes by significance thresholds"),
          tags$li("Choose enrichment analysis type"),
          tags$li("Select database and parameters"),
          tags$li("Visualize and export results")
        )
      )
    ),
    
    # Methods comparison
    fluidRow(
      box(
        title = icon("balance-scale", "Enrichment Methods: ORA vs GSEA"),
        width = 12, status = "info", solidHeader = TRUE,
        fluidRow(
          column(6,
                 h4(icon("chart-bar"), "Over-Representation Analysis (ORA)"),
                 tags$div(class = "well",
                          p(strong("How it works:"), "Tests if genes in a pathway/GO term are over-represented in your significant gene list"),
                          p(strong("Input:"), "List of significant genes (e.g., p < 0.05, |log2FC| > 1)"),
                          p(strong("Best for:"), "Clear-cut results with strong differential expression"),
                          p(strong("Limitation:"), "Arbitrary threshold selection may miss subtle effects")
                 )
          ),
          column(6,
                 h4(icon("dna"), "Gene Set Enrichment Analysis (GSEA)"),
                 tags$div(class = "well",
                          p(strong("How it works:"), "Tests if genes in a pathway are enriched at the extremes of a ranked gene list"),
                          p(strong("Input:"), "All genes ranked by expression change (log2FC)"),
                          p(strong("Best for:"), "Detecting coordinated changes across many genes"),
                          p(strong("Advantage:"), "No arbitrary cutoffs; captures subtle effects")
                 )
          )
        )
      )
    ),
    
    # Databases and ontologies
    fluidRow(
      box(
        title = icon("database", "Databases & Ontologies"),
        width = 12, status = "primary",
        
        h4("Gene Ontology (GO)"),
        fluidRow(
          column(4,
                 tags$div(class = "well",
                          strong(icon("cogs"), "Molecular Function (MF)"),
                          p("The biochemical activities of gene products"),
                          tags$small("Examples: kinase activity, DNA binding")
                 )
          ),
          column(4,
                 tags$div(class = "well",
                          strong(icon("sitemap"), "Biological Process (BP)"),
                          p("Larger biological goals accomplished by gene products"),
                          tags$small("Examples: cell division, immune response")
                 )
          ),
          column(4,
                 tags$div(class = "well",
                          strong(icon("building"), "Cellular Component (CC)"),
                          p("Where in the cell gene products are active"),
                          tags$small("Examples: nucleus, mitochondria")
                 )
          )
        ),
        
        tags$hr(),
        
        h4("Pathway Databases"),
        fluidRow(
          column(6,
                 tags$div(class = "well",
                          strong(icon("star", style = "color: gold;"), "KEGG"),
                          p("Kyoto Encyclopedia of Genes and Genomes"),
                          tags$ul(
                            tags$li("Focus on metabolic and signaling pathways"),
                            tags$li("Visual pathway maps with expression overlay"),
                            tags$li("Disease and drug information"),
                            tags$li("Recommended for general pathway analysis")
                          )
                 )
          ),
          column(6,
                 tags$div(class = "well",
                          strong(icon("atom"), "Reactome"),
                          p("Curated database of biological pathways"),
                          tags$ul(
                            tags$li("Detailed molecular interactions"),
                            tags$li("Expert-curated reaction mechanisms"),
                            tags$li("Cross-species pathway comparison"),
                            tags$li("More granular than KEGG")
                          )
                 )
          )
        )
      )
    ),
    
    # Statistical corrections
    fluidRow(
      box(
        title = icon("calculator", "Statistical Corrections"),
        width = 12, status = "warning",
        
        p("When testing multiple hypotheses simultaneously, the probability of false positives increases. ",
          "P-value adjustment methods control this issue:"),
        
        fluidRow(
          column(6,
                 h4("Bonferroni Correction"),
                 tags$div(class = "well",
                          p(strong("Method:"), "Multiplies p-values by the number of tests"),
                          p(strong("Control:"), "Family-wise error rate (FWER)"),
                          p(strong("Character:"), "Very conservative, may miss true positives"),
                          p(strong("Use when:"), "You need high confidence in results")
                 )
          ),
          column(6,
                 h4("False Discovery Rate (FDR)"),
                 tags$div(class = "well",
                          p(strong("Method:"), "Controls the proportion of false positives"),
                          p(strong("Control:"), "Expected false discovery rate"),
                          p(strong("Character:"), "Less conservative than Bonferroni"),
                          p(strong("Use when:"), "You want to balance sensitivity and specificity")
                 )
          )
        )
      )
    ),
    
    # Resources and tips
    fluidRow(
      box(
        title = icon("book", "Resources & Support"),
        width = 6, status = "success",
        tags$ul(
          tags$li(a(href = "https://github.com/Lucien-Piat/FEAther", target = "_blank", 
                    icon("github"), "GitHub Repository")),
          tags$li(a(href = "https://www.bioconductor.org/packages/release/bioc/html/clusterProfiler.html", 
                    target = "_blank", icon("external-link"), "clusterProfiler Documentation")),
          tags$li(a(href = "https://www.genome.jp/kegg/", target = "_blank", 
                    icon("external-link"), "KEGG Database")),
          tags$li(a(href = "https://reactome.org/", target = "_blank", 
                    icon("external-link"), "Reactome Database")),
          tags$li(a(href = "http://geneontology.org/", target = "_blank", 
                    icon("external-link"), "Gene Ontology"))
        )
      ),
      
      box(
        title = icon("info-circle", "Tips for Best Results"),
        width = 6, status = "info",
        tags$ul(
          tags$li("Ensure your gene IDs are in Ensembl format"),
          tags$li("Use appropriate significance thresholds for your experiment"),
          tags$li("Start with default parameters, then refine"),
          tags$li("Compare ORA and GSEA results for comprehensive insights"),
          tags$li("Export significant results for downstream analysis")
        )
      )
    ),
    
    # Footer
    fluidRow(
      box(
        width = 12, background = "black",
        tags$div(
          style = "text-align: center; color: white;",
          tags$p(
            icon("university"), "Université de Rouen Normandie | ",
            icon("calendar"), "2025 | ",
            icon("envelope"), "Contact via GitHub"
          )
        )
      )
    )
  )
}

# ========== SERVER HELPER FUNCTIONS ==========

# Create custom null-coalescing operator
`%||%` <- function(a, b) if (!is.null(a)) a else b

# Display error popup with custom dodo image
show_shiny_error <- function(title, message) {
  shinyalert::shinyalert(
    title = title,
    text = tags$div(tags$img(src = "dodo.png", height = "50px"), tags$p(message)),
    type = "error", html = TRUE
  )
}

# ========== PLOT RENDERING FUNCTIONS ==========

# Generic GO plot renderer with error handling
render_go_plot <- function(plot_func, ego, show_category = NULL, custom_theme = NULL, use_pairwise_sim = FALSE) {
  # Check for empty results
  if (is.null(ego) || nrow(ego@result) == 0) {
    plot(1, type = "n", axes = FALSE, xlab = "", ylab = "")
    text(1, 1, "No significant GO terms found", col = "red", cex = 1.5)
    return()
  }
  
  # Compute pairwise similarity if needed
  if (use_pairwise_sim) {
    ego <- enrichplot::pairwise_termsim(ego)
    if (is.null(ego) || nrow(ego@termsim) == 0) {
      plot(1, type = "n", axes = FALSE, xlab = "", ylab = "")
      text(1, 1, "No term similarity available", col = "red", cex = 1.5)
      return()
    }
  }
  
  # Adjust category count to available terms
  n_terms <- nrow(ego@result)
  adjusted_category <- if (!is.null(show_category)) min(show_category, n_terms) else NULL
  
  # Generate plot
  p <- if (!is.null(adjusted_category)) {
    plot_func(ego, showCategory = adjusted_category)
  } else {
    plot_func(ego)
  }
  
  # Apply theme and render
  p <- p + (custom_theme %||% theme_minimal())
  print(p)
}

# GSEA-specific plot renderers
render_gsea_dotplot <- function(gsea_result, showCategory = 10) {
  if (is.null(gsea_result) || nrow(gsea_result@result) == 0) return(NULL)
  enrichplot::dotplot(gsea_result, showCategory = showCategory, split = ".sign") +
    ggplot2::facet_grid(. ~ .sign)
}

render_gsea_emapplot <- function(gsea_result, showCategory = 30) {
  if (is.null(gsea_result) || nrow(gsea_result@result) == 0) return(NULL)
  gsea_result <- enrichplot::pairwise_termsim(gsea_result)
  enrichplot::emapplot(gsea_result, showCategory = showCategory)
}

render_gsea_ridgeplot <- function(gsea_result, showCategory = 10) {
  if (is.null(gsea_result) || nrow(gsea_result@result) == 0) return(NULL)
  enrichplot::ridgeplot(gsea_result, showCategory = 10)
}

render_gsea_gseaplot <- function(gsea_result, top_n = 3) {
  if (is.null(gsea_result) || nrow(gsea_result@result) == 0) return(NULL)
  
  # Get top pathways
  top_terms <- head(gsea_result@result$ID, top_n)
  plots <- lapply(top_terms, function(term_id) {
    enrichplot::gseaplot2(gsea_result, geneSetID = term_id, title = term_id)
  })
  
  # Combine plots if patchwork available
  if (requireNamespace("patchwork", quietly = TRUE)) {
    return(Reduce(`+`, plots))
  } else {
    return(plots[[1]])
  }
}

# UI component for pathway visualization tabs
pathwayPlotsUI <- function() {
  tabsetPanel(
    tabPanel("Pathway View",
             fluidRow(
               column(12,
                      fluidRow(
                        column(6,
                               selectInput("pathview_pathway_select", "Select pathway to visualize:",
                                           choices = NULL, width = "100%")),
                        column(3,
                               br(),
                               downloadButton("download_pathview", "Download Pathway View",
                                              style = "width: 100%;"))
                      ),
                      hr(),
                      withSpinner(imageOutput("pathway_view", height = "auto"))
               )
             )
    ),
    tabPanel("Network Plot", withSpinner(plotOutput("pathway_emapplot", height = 600))),
    tabPanel("Cnet Plot", withSpinner(plotOutput("pathway_cnetplot", height = 600)))
  )
}

# Generic pathway plot renderer with error handling
render_pathway_plot <- function(plot_func, pathway_result, show_category = NULL, custom_theme = NULL, use_pairwise_sim = FALSE) {
  # Check for empty results
  if (is.null(pathway_result) || nrow(pathway_result@result) == 0) {
    plot(1, type = "n", axes = FALSE, xlab = "", ylab = "")
    text(1, 1, "Impossible to plot, insufficient data to compute", col = "red", cex = 1.5)
    return()
  }
  
  # Network plots need at least 2 pathways
  if (use_pairwise_sim && nrow(pathway_result@result) < 2) {
    plot(1, type = "n", axes = FALSE, xlab = "", ylab = "")
    text(1, 1, "Impossible to plot, insufficient data to compute\n(Need at least 2 pathways for network plot)", 
         col = "red", cex = 1.2)
    return()
  }
  
  # Compute similarity if needed
  if (use_pairwise_sim) {
    pathway_result <- tryCatch({
      enrichplot::pairwise_termsim(pathway_result)
    }, error = function(e) { return(NULL) })
    
    if (is.null(pathway_result)) {
      plot(1, type = "n", axes = FALSE, xlab = "", ylab = "")
      text(1, 1, "Impossible to plot, insufficient data to compute", col = "red", cex = 1.5)
      return()
    }
  }
  
  # Adjust category count
  n_terms <- nrow(pathway_result@result)
  adjusted_category <- if (!is.null(show_category)) min(show_category, n_terms) else min(10, n_terms)
  
  # Generate plot with error handling
  p <- tryCatch({
    if (!is.null(adjusted_category)) {
      plot_func(pathway_result, showCategory = adjusted_category)
    } else {
      plot_func(pathway_result)
    }
  }, error = function(e) { return(NULL) })
  
  if (is.null(p)) {
    plot(1, type = "n", axes = FALSE, xlab = "", ylab = "")
    text(1, 1, "Impossible to plot, insufficient data to compute", col = "red", cex = 1.5)
    return()
  }
  
  # Apply theme and render
  p <- p + (custom_theme %||% theme_minimal())
  print(p)
}