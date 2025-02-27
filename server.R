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
library("DT")
library("dashboardthemes")
library("plotly")
library("data.table")
source("functions.R")
library("shinyjs")  
library('clusterProfiler')
library("org.Mm.eg.db") 

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
    df # Return the dataframe
  })
  
  
  # -----------------------------------------
  # Filtered data 
  # -----------------------------------------
  
  filtered_data <- reactive({
    df <- req(data())  # Ensure data is available
    
    # Filter data based on slider inputs (log2FC and p-value)
    filtered_df <- df %>% dplyr::filter(abs(log2FC) >= input$log2FC_slider, pval <= input$p_val_slider)
    
    # Check if plotly zoom/pan event data is available
    plotly_event <- event_data("plotly_relayout", priority = "event")
    
    if (!is.null(plotly_event) && length(plotly_event) > 0) {
      # Ensure plotly_event contains valid ranges for x and y axes
      x_range_valid <- !is.null(plotly_event$`xaxis.range[0]`) && !is.null(plotly_event$`xaxis.range[1]`)
      y_range_valid <- !is.null(plotly_event$`yaxis.range[0]`) && !is.null(plotly_event$`yaxis.range[1]`)
      
      if (x_range_valid && y_range_valid) {
        # Apply zoom/pan filter based on plotly event data (x-axis and y-axis ranges)
        filtered_df <- filtered_df %>%
          dplyr::filter(log2FC >= plotly_event$`xaxis.range[0]` & log2FC <= plotly_event$`xaxis.range[1]` & 
                          -log10(pval) >= plotly_event$`yaxis.range[0]` & -log10(pval) <= plotly_event$`yaxis.range[1]`)
      }
    }
    filtered_df  # Return the final filtered data
  })
  
  # -----------------------------------------
  # Volcano plot (created once with full data)
  # -----------------------------------------
  volcano_plot <- reactive({
    df <- req(data())  # Full dataset for plotting
    
    # Create a color column based on the filtering conditions (for coloring only)
    df$color <- ifelse(df$pval <= input$p_val_slider & abs(df$log2FC) >= input$log2FC_slider, 
                       ifelse(df$log2FC > 0, "green", "red"), "grey")
    
    # Create the volcano plot using plotly
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
    volcano_plot()  # Simply call the reactive volcano plot
  })
  
  # -----------------------------------------
  # Render the Table (using filtered data)
  # -----------------------------------------
  
  output$table <- DT::renderDataTable({
    data <- filtered_data()
    req(data)  # Ensure data is available
    datatable(data)  # Render table without additional options
  })
  
  # -----------------------------------------
  # Enrich
  # -----------------------------------------
  
  # Compute GO enrichment only when the "Enrich" button is clicked
  # Compute GO enrichment only when "Enrich" is clicked
  enriched_go <- eventReactive(input$enrich_button, {
    df <- req(filtered_data())  # Get filtered data
    ensembl_ids <- df$ID        # Assuming "ID" column contains Ensembl Gene IDs
    
    # Convert Ensembl IDs to Entrez IDs
    id_mapping <- tryCatch(
      bitr(
        ensembl_ids,
        fromType = "ENSEMBL",
        toType = "ENTREZID",
        OrgDb = org.Mm.eg.db  # Use the correct OrgDb for Mus musculus
      ),
      error = function(e) {
        show_shiny_error("GO enrichment failed", e)
        return(NULL)
      }
    )
    
    if (is.null(id_mapping) || nrow(id_mapping) == 0) {
      show_shiny_error("GO enrichment failed", "No valid ID mappings found.")
      return(NULL)
    }
    
    # Merge to retain only mapped genes
    mapped_df <- merge(df, id_mapping, by.x = "ID", by.y = "ENSEMBL", all.x = FALSE)
    
    gene_list <- unique(mapped_df$ENTREZID)
    if (length(gene_list) == 0) {
      show_shiny_error("GO enrichment failed", "No valid Entrez IDs for enrichment analysis.")
      return(NULL)
    }
    
    # Perform GO enrichment analysis with user-selected options
    ego <- tryCatch(
      enrichGO(
        gene          = gene_list,
        OrgDb         = org.Mm.eg.db,
        keyType       = "ENTREZID",
        ont           = input$ontology,  # Use selected ontology
        pAdjustMethod = input$p_adjust_method,  # Use selected p-adjustment method
        readable      = TRUE
      ),
      error = function(e) {
        show_shiny_error("GO enrichment failed", e)
        return(NULL)
      }
    )
    
    if (is.null(ego) || nrow(ego@result) == 0) {
      show_shiny_error("GO enrichment failed", "No significant GO terms found.")
      return(NULL)
    }
    return(ego)
  })
  
  
  # Render GO enrichment plot
  output$go_plot <- renderPlot({
    ego <- enriched_go()
    req(ego)
    
    if (nrow(ego@result) == 0) {
      plot(1, type = "n", axes = FALSE, xlab = "", ylab = "")
      text(1, 1, "No significant GO terms found", col = "red", cex = 1.5)
    } else {
      dotplot(ego, showCategory = input$show_category,font.size = 12) +  # Uses slider value
        ggtitle(paste("GO Term Enrichment:", input$ontology)) + theme_minimal()
    }
  })
  

  # -----------------------------------------
  # Download handler for filtered data
  # -----------------------------------------
  
  output$download <- downloadHandler(
    filename = function() {
      paste("filtered_data_", Sys.Date(), ".csv", sep = "")
    },
    content = function(file) {
      df <- filtered_data()  # Get filtered data
      write.csv(df, file, row.names = FALSE)  # Download CSV
    }
  )
}
