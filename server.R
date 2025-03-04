# -----------------------------------------
# Project: FEA-ther (Functional Enrichment Analysis Tool)
# Author: Maël Louis, Antoine Malet and Lucien Piat 
# Affiliation: Rouen Normandie University
# Creation: 04/10/2024
# Last update: 18/11/2024
# -----------------------------------------

library("shiny")
library("shinycssloaders")
library("shinyalert")
library("shinydashboard")
library("dashboardthemes")
library("plotly")
library("DT")
library("data.table")
source("functions.R")
library("shinyjs")  
library('clusterProfiler')
library("org.Mm.eg.db") 
library("org.Hs.eg.db")

server <- function(input, output, session) {
  

  # -----------------------------------------
  # Data input (using fread)
  # -----------------------------------------
  data <- reactive({
    req(input$file) # Ensure file input is available
    
    # Check if the uploaded file has a valid extension (CSV, TXT, TSV, or DAT)
    file_ext <- tools::file_ext(input$file$name)
    if (!(file_ext %in% c("csv", "txt", "tsv", "dat"))) {
      show_shiny_error("File upload error", "Please upload a tabular data file with one of the following extensions: .csv, .txt, .tsv, or .dat.")
      return(NULL)
    }
    
    # Define the desired column names
    column_names <- c("GeneName", "ID", "baseMean", "log2FC", "pval", "padj")
    
    # Read data
    df <- tryCatch(
      {
        fread(input$file$datapath, header = TRUE, col.names = column_names)
      },
      error = function(e) {
        show_shiny_error("File upload error", HTML("There was an error reading the file.<br><br>Provide a file with exactly 6 columns:<br>'GeneName', 'ID', 'baseMean', 'log2FC', 'pval', and 'padj'.<br><br>A header row is optional."))
        return(NULL)
      }
    )
    req(nrow(df) > 0) # Ensure the data frame is not empty
    df
  })
  
  
  # -----------------------------------------
  # Filtered data 
  # -----------------------------------------
  filtered_data <- reactive({
    df <- req(data())  # Ensure data is available
    
    # Filter data based on slider inputs (log2FC and p-value)
    filtered_df <- df %>% dplyr::filter(abs(log2FC) >= input$log2FC_slider, pval <= input$p_val_slider)
    
    # Filter again based on the plotly Zoom
    plotly_event <- event_data("plotly_relayout", priority = "event")
    if (!is.null(plotly_event) && length(plotly_event) > 0) {
      x_range_valid <- !is.null(plotly_event$`xaxis.range[0]`) && !is.null(plotly_event$`xaxis.range[1]`)
      y_range_valid <- !is.null(plotly_event$`yaxis.range[0]`) && !is.null(plotly_event$`yaxis.range[1]`)
      if (x_range_valid && y_range_valid) {
        filtered_df <- filtered_df %>%
          dplyr::filter(log2FC >= plotly_event$`xaxis.range[0]` & log2FC <= plotly_event$`xaxis.range[1]` & 
                          -log10(pval) >= plotly_event$`yaxis.range[0]` & -log10(pval) <= plotly_event$`yaxis.range[1]`)
      }
    }
    filtered_df 
  })
  
  # -----------------------------------------
  # Volcano plot and table
  # -----------------------------------------
  volcano_plot <- reactive({
    df <- req(data()) # Take full data set
    
    # Create a color column based on the filtering conditions (for coloring only)
    df$color <- ifelse(df$pval <= input$p_val_slider & abs(df$log2FC) >= input$log2FC_slider, 
                       ifelse(df$log2FC > 0, "green", "red"), "grey")
    
    plot_ly(df, x = ~log2FC, y = -log10(df$pval), type = 'scatter', mode = 'markers',
            text = ~GeneName, hoverinfo = 'text', 
            marker = list(color = ~color, size = 3)) %>%
      layout(title = "Volcano Plot",
             xaxis = list(title = "Log2 Fold Change"),
             yaxis = list(title = "-Log10 P-value", range = c(-1, 15)),  # Set y-axis range from 0 to 30
             showlegend = FALSE)
  })
  
  # Render the volcano plot using plotly
  output$volcano_plot <- renderPlotly({
    volcano_plot()
  })
  
  # Render the Table (using filtered data)
  output$table <- DT::renderDataTable({
    datatable(filtered_data(), options = list(pageLength = 10, scrollX = TRUE))
  })
  
  # Allow user to download the table
  output$download <- downloadHandler(
    filename = function() {
      paste("filtered_data_", Sys.Date(), ".csv", sep = "")
    },
    content = function(file) {
      df <- filtered_data()  # Get filtered data
      write.csv(df, file, row.names = FALSE)  # Download CSV
    }
  )
  
  # -----------------------------------------
  # ORA
  # -----------------------------------------
  
  # Define a reactive expression for selecting the correct organism database
  OrgDb_selected <- reactive({
    if (input$organism == "Homo sapiens") {
      library("org.Hs.eg.db")  # Load Human database
      return(org.Hs.eg.db)
    } else {
      library("org.Mm.eg.db")  # Load Mouse database
      return(org.Mm.eg.db)
    }
  })
  
  # Compute GO enrichment only when "Enrich" is clicked
  ego_ora <- eventReactive(input$enrich_button, {
    df <- req(filtered_data())  
    ensembl_ids <- df$ID
    
    # Convert Ensembl IDs to Entrez IDs
    id_mapping <- tryCatch(
      bitr(
        ensembl_ids,
        fromType = "ENSEMBL",
        toType = "ENTREZID",
        OrgDb = OrgDb_selected()
      ),
      error = function(e) return(NULL)
    )
    
    if (is.null(id_mapping) || nrow(id_mapping) == 0) return(NULL)
    
    # Merge mapped IDs with original data
    df <- merge(df, id_mapping, by.x = "ID", by.y = "ENSEMBL")
    print(head(df))
    # Apply user selection for over/under/both representation
    if (input$representation_filter == "over") {
      df <- df[df$log2FC > 0, ]
    } else if (input$representation_filter == "under") {
      df <- df[df$log2FC < 0, ]
    } 
    
    gene_list <- unique(df$ENTREZID)
    if (length(gene_list) == 0) return(NULL)
    
    # Perform GO enrichment analysis
    ego <- tryCatch(
      enrichGO(
        gene          = gene_list,
        OrgDb         = OrgDb_selected(),
        keyType       = "ENTREZID",
        ont           = input$ontology,
        pAdjustMethod = input$p_adjust_method,
        readable      = TRUE
      ),
      error = function(e) return(NULL)
    )
    
    if (is.null(ego) || nrow(ego@result) == 0) return(NULL)
    return(ego)
  })
  
  
  # Enrichment plots using ORA result (we use a generic function from function.R)
  output$go_plot <- renderPlot({
    render_go_plot(dotplot, ego_ora(), input$show_category)
  })
  
  output$barplot <- renderPlot({
    render_go_plot(barplot, ego_ora(), input$show_category)
  })
  
  output$treeplot <- renderPlot({
    render_go_plot(enrichplot::treeplot, ego_ora(), input$show_category,  use_pairwise_sim = TRUE)
  })
  
  output$emapplot <- renderPlot({
    render_go_plot(enrichplot::emapplot, ego_ora(), input$show_category, use_pairwise_sim = TRUE)
  })
}
