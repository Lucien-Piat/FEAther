# -----------------------------------------
# Project: FEA-ther (Functional Enrichment Analysis Tool)
# Author: Maël Louis, Antoine Malet and Lucien Piat 
# Affiliation: Rouen Normandie University
# Creation: 04/10/2024 | Last update: 09/05/2025
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
library("ggplot2")

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
  # Filtered data (based on user inputs and plot zoom)
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
  # Volcano plot creation and rendering
  # -----------------------------------------
  
  volcano_plot <- reactive({
    df <- req(data()) # Take full data set
    
    # Create a color column based on the filtering conditions (for coloring only)
    df$color <- ifelse(df$pval <= input$p_val_slider & abs(df$log2FC) >= input$log2FC_slider, 
                       ifelse(df$log2FC > 0, "green", "red"), "grey")
    
    # Generate the volcano plot
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
  
  # Allow user to download the filtered data table as CSV
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
  # Over-Representation Analysis (ORA)
  # -----------------------------------------
  
  OrgDb_selected <- reactive({
    if (input$organism == "Homo sapiens") {
      org.Hs.eg.db
    } else {
      org.Mm.eg.db
    }
  })
  
  # Compute GO enrichment only when "Enrich" is clicked
  ora_results <- eventReactive(input$ora_enrich_button, {
    df <- req(filtered_data())  
    ensembl_ids <- df$ID
    
    # Convert Ensembl IDs to Entrez IDs using clusterProfiler
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
    
    # Apply user selection for over/under/both representation
    if (input$ora_representation_filter == "over") {
      df <- df[df$log2FC > 0, ]
    } else if (input$ora_representation_filter == "under") {
      df <- df[df$log2FC < 0, ]
    } 
    
    # Extract unique Entrez IDs for enrichment analysis
    gene_list <- unique(df$ENTREZID)
    if (length(gene_list) == 0) return(NULL)
    
    # Perform GO enrichment analysis
    ego <- tryCatch(
      enrichGO(
        gene          = gene_list,
        OrgDb         = OrgDb_selected(),
        keyType       = "ENTREZID",
        ont           = input$ora_ontology,
        pAdjustMethod = input$ora_p_adjust_method,
        readable      = TRUE
      ),
      error = function(e) return(NULL)
    )
    
    if (is.null(ego) || nrow(ego@result) == 0) return(NULL)
    return(ego)
  })
  
  # Render enrichment plots for ORA results
  output$go_plot <- renderPlot({
    render_go_plot(dotplot, ora_results(), input$ora_show_category)
  })
  
  output$barplot <- renderPlot({
    render_go_plot(barplot, ora_results(), input$ora_show_category)
  })
  
  output$treeplot <- renderPlot({
    render_go_plot(enrichplot::treeplot, ora_results(), input$ora_show_category,  use_pairwise_sim = TRUE)
  })
  
  output$emapplot <- renderPlot({
    render_go_plot(enrichplot::emapplot, ora_results(), input$ora_show_category, use_pairwise_sim = TRUE)
  })
  
  # Render ORA results table with selectable columns
  output$ego_table <- DT::renderDataTable({
    req(ora_results())
    df <- as.data.frame(ora_results()@result)
    selected_cols <- switch(input$ora_table_mode,
                            "detailed" = c("Description", "GeneRatio", "BgRatio", "p.adjust", "pvalue"),
                            "genes"    = c("Description", "GeneRatio", "geneID" )
    )
    datatable(
      df[, selected_cols, drop = FALSE], extensions = 'Buttons',
      options = list(
        pageLength = 10,
        scrollX = TRUE,
        dom = 'Bfrtip',
        buttons = c('copy', 'csv', 'pdf')
      )
    )
  })
  
  gsea_result <- eventReactive(input$gsea_enrich_button, {
    df <- req(data())  # Use full dataset for GSEA
    
    # Convert Ensembl IDs to Entrez IDs
    id_mapping <- tryCatch(
      bitr(
        df$ID,
        fromType = "ENSEMBL",
        toType = "ENTREZID",
        OrgDb = OrgDb_selected()
      ),
      error = function(e) return(NULL)
    )
    
    if (is.null(id_mapping) || nrow(id_mapping) == 0) return(NULL)
    
    # Merge IDs
    df <- merge(df, id_mapping, by.x = "ID", by.y = "ENSEMBL")
    
    # Create a ranked named vector (EntrezID as names, log2FC as values)
    gene_list <- df$log2FC
    names(gene_list) <- df$ENTREZID
    gene_list <- sort(gene_list, decreasing = TRUE)  # Required for GSEA
    
    # Remove duplicates (GSEA requires unique gene IDs)
    gene_list <- gene_list[!duplicated(names(gene_list))]
    
    # Run GSEA
    gsea <- tryCatch(
      gseGO(
        geneList     = gene_list,
        OrgDb        = OrgDb_selected(),
        keyType      = "ENTREZID",
        ont          = input$gsea_ontology,
        pAdjustMethod= input$gsea_p_adjust_method,
        verbose      = FALSE
      ),
      error = function(e) return(NULL)
    )
    
    if (is.null(gsea) || nrow(gsea@result) == 0) return(NULL)
    return(gsea)
  })

  
  output$gsea_table <- DT::renderDataTable({
    gsea <- gsea_result()
    req(gsea)
    
    df <- as.data.frame(gsea@result)
    
    # Select useful columns to display
    selected_cols <- c("Description","enrichmentScore", "NES", "pvalue", "p.adjust")
    
    datatable(
      df[, selected_cols, drop = FALSE],
      extensions = 'Buttons',
      options = list(
        pageLength = 10,
        scrollX = TRUE,
        dom = 'Bfrtip',
        buttons = c('copy', 'csv', 'pdf')
      )
    )
  })
  
  output$gsea_dotplot <- renderPlot({
    render_gsea_dotplot(gsea_result(), input$gsea_show_category)
  })
  
  output$gsea_emapplot <- renderPlot({
    render_gsea_emapplot(gsea_result(), input$gsea_show_category)
  })
  
  output$gsea_ridgeplot <- renderPlot({
    render_gsea_ridgeplot(gsea_result(), input$gsea_show_category)
  })
  
  # Update pathway choices when GSEA results change
  observe({
    gsea <- gsea_result()
    if (!is.null(gsea) && nrow(gsea@result) > 0) {
      # Create named choices: Description as label, ID as value
      pathway_choices <- setNames(
        gsea@result$ID,
        paste0(gsea@result$Description, 
               " (NES: ", round(gsea@result$NES, 2), 
               ", p.adj: ", format(gsea@result$p.adjust, digits = 2), ")")
      )
      
      updateSelectInput(session, "gsea_pathway_select",
                        choices = pathway_choices,
                        selected = gsea@result$ID[1])
    }
  })
  
  # Store the current GSEA plot for downloading
  gsea_plot_reactive <- reactive({
    results <- req(gsea_result())
    selected_id <- req(input$gsea_pathway_select)
    
    # Find the selected pathway info
    pathway_info <- results@result[results@result$ID == selected_id, ]
    
    if (nrow(pathway_info) == 0) return(NULL)
    
    gene_set_name <- pathway_info$Description[1]
    nes <- round(pathway_info$NES[1], 3)
    pval <- format(pathway_info$p.adjust[1], digits = 3)
    
    # Create the plot with base_size parameter for larger text
    enrichplot::gseaplot2(
      results, 
      geneSetID = selected_id,
      title = paste0(gene_set_name, "\nNES = ", nes, ", Adjusted p-value = ", pval),
      base_size = 14  # This will make all text larger proportionally
    )
  })
  
  # Update the output for gsea_gseaplot
  output$gsea_gseaplot <- renderPlot({
    gsea_plot_reactive()
  })
  
  # Add download handler for GSEA plot
  output$download_gsea_plot <- downloadHandler(
    filename = function() {
      paste0("gsea_plot_", gsub("[^[:alnum:]]", "_", input$gsea_pathway_select), "_", Sys.Date(), ".png")
    },
    content = function(file) {
      # Save the plot
      ggsave(file, plot = gsea_plot_reactive(), 
             width = 10, height = 8, dpi = 300, units = "in")
    }
  )
}
