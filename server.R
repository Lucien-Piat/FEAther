# -----------------------------------------
# Project: FEA-ther (Functional Enrichment Analysis Tool)
# Author: Maël Louis, Antoine Malet and Lucien Piat 
# Affiliation: Rouen Normandie University
# Creation: 04/10/2024 | Last update: 02/06/2025
# -----------------------------------------

# Load required libraries
library("shiny"); library("shinycssloaders"); library("shinyalert"); library("shinydashboard")
library("dashboardthemes"); library("plotly"); library("DT"); library("data.table")
source("functions.R"); library("shinyjs"); library('clusterProfiler')
library("org.Mm.eg.db"); library("org.Hs.eg.db"); library("ggplot2")
library("ReactomePA"); library("enrichplot"); library("pathview"); library("GO.db")

server <- function(input, output, session) {
  
  # ========== DATA INPUT SECTION ==========
  # Read and validate uploaded file
  data <- reactive({
    req(input$file)
    
    # Validate file extension
    file_ext <- tools::file_ext(input$file$name)
    if (!(file_ext %in% c("csv", "txt", "tsv", "dat"))) {
      show_shiny_error("File upload error", 
                       "Please upload a tabular data file with one of the following extensions: .csv, .txt, .tsv, or .dat.")
      return(NULL)
    }
    
    # Define expected column structure
    column_names <- c("GeneName", "ID", "baseMean", "log2FC", "pval", "padj")
    
    # Read data with error handling
    df <- tryCatch({
      fread(input$file$datapath, header = TRUE, col.names = column_names)
    },
    error = function(e) {
      show_shiny_error("File upload error", 
                       HTML("There was an error reading the file.<br><br>Provide a file with exactly 6 columns:<br>'GeneName', 'ID', 'baseMean', 'log2FC', 'pval', and 'padj'.<br><br>A header row is optional."))
      return(NULL)
    })
    req(nrow(df) > 0)
    df
  })
  
  # ========== DATA FILTERING SECTION ==========
  # Apply user filters and plotly zoom
  filtered_data <- reactive({
    df <- req(data())
    
    # Apply slider filters
    filtered_df <- df %>% 
      dplyr::filter(abs(log2FC) >= input$log2FC_slider, pval <= input$p_val_slider)
    
    # Apply plotly zoom filters if present
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
  
  # ========== VISUALIZATION SECTION ==========
  # Create volcano plot
  volcano_plot <- reactive({
    df <- req(data())
    
    # Color code points based on significance
    df$color <- ifelse(df$pval <= input$p_val_slider & abs(df$log2FC) >= input$log2FC_slider, 
                       ifelse(df$log2FC > 0, "green", "red"), "grey")
    
    # Generate interactive plotly volcano plot
    plot_ly(df, x = ~log2FC, y = -log10(df$pval), type = 'scatter', mode = 'markers',
            text = ~GeneName, hoverinfo = 'text', 
            marker = list(color = ~color, size = 3)) %>%
      layout(title = "Volcano Plot",
             xaxis = list(title = "Log2 Fold Change"),
             yaxis = list(title = "-Log10 P-value", range = c(-1, 15)),
             showlegend = FALSE)
  })
  
  # Render volcano plot
  output$volcano_plot <- renderPlotly({ volcano_plot() })
  
  # Render filtered data table
  output$table <- DT::renderDataTable({
    datatable(filtered_data(), options = list(pageLength = 10, scrollX = TRUE))
  })
  
  # Download handler for filtered data
  output$download <- downloadHandler(
    filename = function() { paste("filtered_data_", Sys.Date(), ".csv", sep = "") },
    content = function(file) { write.csv(filtered_data(), file, row.names = FALSE) }
  )
  
  # ========== ORGANISM DATABASE SELECTION ==========
  OrgDb_selected <- reactive({
    if (input$organism == "Homo sapiens") org.Hs.eg.db else org.Mm.eg.db
  })
  
  # ========== ORA (OVER-REPRESENTATION ANALYSIS) SECTION ==========
  # Perform GO enrichment analysis when button clicked
  ora_results <- eventReactive(input$ora_enrich_button, {
    df <- req(filtered_data())
    ensembl_ids <- df$ID
    
    # Convert Ensembl to Entrez IDs
    id_mapping <- tryCatch(
      bitr(ensembl_ids, fromType = "ENSEMBL", toType = "ENTREZID", OrgDb = OrgDb_selected()),
      error = function(e) return(NULL)
    )
    
    if (is.null(id_mapping) || nrow(id_mapping) == 0) return(NULL)
    
    # Merge mapped IDs
    df <- merge(df, id_mapping, by.x = "ID", by.y = "ENSEMBL")
    
    # Filter by representation type
    if (input$ora_representation_filter == "over") {
      df <- df[df$log2FC > 0, ]
    } else if (input$ora_representation_filter == "under") {
      df <- df[df$log2FC < 0, ]
    }
    
    # Extract unique genes for enrichment
    gene_list <- unique(df$ENTREZID)
    if (length(gene_list) == 0) return(NULL)
    
    # Run GO enrichment
    ego <- tryCatch(
      enrichGO(gene = gene_list, OrgDb = OrgDb_selected(), keyType = "ENTREZID",
               ont = input$ora_ontology, pAdjustMethod = input$ora_p_adjust_method,
               readable = TRUE),
      error = function(e) return(NULL)
    )
    
    if (is.null(ego) || nrow(ego@result) == 0) return(NULL)
    
    # Apply GO level filtering
    ego <- filter_go_by_level(ego, 
                              min_level = input$ora_go_level[1], 
                              max_level = input$ora_go_level[2],
                              ontology = input$ora_ontology) 
    
    return(ego)
  })
  
  # Render ORA visualization plots
  output$go_plot <- renderPlot({
    render_go_plot(dotplot, ora_results(), input$ora_show_category)
  })
  
  output$barplot <- renderPlot({
    render_go_plot(barplot, ora_results(), input$ora_show_category)
  })
  
  output$treeplot <- renderPlot({
    render_go_plot(enrichplot::treeplot, ora_results(), input$ora_show_category, use_pairwise_sim = TRUE)
  })
  
  output$emapplot <- renderPlot({
    render_go_plot(enrichplot::emapplot, ora_results(), input$ora_show_category, use_pairwise_sim = TRUE)
  })
  
  # Render ORA results table with mode switching
  output$ego_table <- DT::renderDataTable({
    req(ora_results())
    df <- as.data.frame(ora_results()@result)
    
    # Select columns based on display mode
    selected_cols <- switch(input$ora_table_mode,
                            "detailed" = c("Description", "GeneRatio", "BgRatio", "p.adjust", "pvalue"),
                            "genes"    = c("Description", "GeneRatio", "geneID"))
    
    datatable(df[, selected_cols, drop = FALSE], extensions = 'Buttons',
              options = list(pageLength = 10, scrollX = TRUE, dom = 'Bfrtip',
                             buttons = c('copy', 'csv', 'pdf')))
  })
  
  # ========== GSEA (GENE SET ENRICHMENT ANALYSIS) SECTION ==========
  # Perform GSEA when button clicked
  gsea_result <- eventReactive(input$gsea_enrich_button, {
    df <- req(data())  # Use full dataset for GSEA
    
    # Convert IDs
    id_mapping <- tryCatch(
      bitr(df$ID, fromType = "ENSEMBL", toType = "ENTREZID", OrgDb = OrgDb_selected()),
      error = function(e) return(NULL)
    )
    
    if (is.null(id_mapping) || nrow(id_mapping) == 0) return(NULL)
    df <- merge(df, id_mapping, by.x = "ID", by.y = "ENSEMBL")
    
    # Create ranked gene list (required for GSEA)
    gene_list <- df$log2FC
    names(gene_list) <- df$ENTREZID
    gene_list <- sort(gene_list, decreasing = TRUE)
    gene_list <- gene_list[!duplicated(names(gene_list))]  # Remove duplicates
    
    # Run GSEA
    gsea <- tryCatch(
      gseGO(geneList = gene_list, OrgDb = OrgDb_selected(), keyType = "ENTREZID",
            ont = input$gsea_ontology, pAdjustMethod = input$gsea_p_adjust_method,
            verbose = FALSE),
      error = function(e) return(NULL)
    )
    
    if (is.null(gsea) || nrow(gsea@result) == 0) return(NULL)
    
    # Apply GO level filtering
    gsea <- filter_go_by_level(gsea, 
                               min_level = input$gsea_go_level[1], 
                               max_level = input$gsea_go_level[2],
                               ontology = input$gsea_ontology)
    
    return(gsea)
  })
  
  # Render GSEA results table
  output$gsea_table <- DT::renderDataTable({
    gsea <- gsea_result()
    req(gsea)
    
    df <- as.data.frame(gsea@result)
    selected_cols <- c("Description","enrichmentScore", "NES", "pvalue", "p.adjust")
    
    datatable(df[, selected_cols, drop = FALSE], extensions = 'Buttons',
              options = list(pageLength = 10, scrollX = TRUE, dom = 'Bfrtip',
                             buttons = c('copy', 'csv', 'pdf')))
  })
  
  # Render GSEA visualization plots
  output$gsea_dotplot <- renderPlot({
    render_gsea_dotplot(gsea_result(), input$gsea_show_category)
  })
  
  output$gsea_emapplot <- renderPlot({
    render_gsea_emapplot(gsea_result(), input$gsea_show_category)
  })
  
  output$gsea_ridgeplot <- renderPlot({
    render_gsea_ridgeplot(gsea_result(), input$gsea_show_category)
  })
  
  # Update pathway selection dropdown
  observe({
    gsea <- gsea_result()
    if (!is.null(gsea) && nrow(gsea@result) > 0) {
      # Create descriptive pathway choices
      pathway_choices <- setNames(
        gsea@result$ID,
        paste0(gsea@result$Description, " (NES: ", round(gsea@result$NES, 2), 
               ", p.adj: ", format(gsea@result$p.adjust, digits = 2), ")"))
      
      updateSelectInput(session, "gsea_pathway_select",
                        choices = pathway_choices, selected = gsea@result$ID[1])
    }
  })
  
  # Generate individual GSEA plot
  gsea_plot_reactive <- reactive({
    results <- req(gsea_result())
    selected_id <- req(input$gsea_pathway_select)
    
    # Get pathway information
    pathway_info <- results@result[results@result$ID == selected_id, ]
    if (nrow(pathway_info) == 0) return(NULL)
    
    gene_set_name <- pathway_info$Description[1]
    nes <- round(pathway_info$NES[1], 3)
    pval <- format(pathway_info$p.adjust[1], digits = 3)
    
    # Create detailed GSEA plot
    enrichplot::gseaplot2(
      results, geneSetID = selected_id,
      title = paste0(gene_set_name, "\nNES = ", nes, ", Adjusted p-value = ", pval),
      base_size = 14)
  })
  
  output$gsea_gseaplot <- renderPlot({ gsea_plot_reactive() })
  
  # Download handler for GSEA plot
  output$download_gsea_plot <- downloadHandler(
    filename = function() {
      paste0("gsea_plot_", gsub("[^[:alnum:]]", "_", input$gsea_pathway_select), "_", Sys.Date(), ".png")
    },
    content = function(file) {
      ggsave(file, plot = gsea_plot_reactive(), width = 10, height = 8, dpi = 300, units = "in")
    }
  )
  
  # ========== PATHWAY ENRICHMENT SECTION ==========
  # Perform pathway analysis (KEGG/Reactome)
  pathway_results <- eventReactive(input$pathway_enrich_button, {
    # Select data based on method
    df <- if (input$pathway_method == "ORA") req(filtered_data()) else req(data())
    
    # Convert IDs
    id_mapping <- tryCatch(
      bitr(df$ID, fromType = "ENSEMBL", toType = "ENTREZID", OrgDb = OrgDb_selected()),
      error = function(e) return(NULL)
    )
    
    if (is.null(id_mapping) || nrow(id_mapping) == 0) return(NULL)
    df <- merge(df, id_mapping, by.x = "ID", by.y = "ENSEMBL")
    
    # Perform enrichment based on database and method
    if (input$pathway_database == "KEGG") {
      organism_code <- if(input$organism == "Homo sapiens") "hsa" else "mmu"
      
      if (input$pathway_method == "ORA") {
        # Apply representation filter
        if (input$pathway_representation_filter == "over") {
          df <- df[df$log2FC > 0, ]
        } else if (input$pathway_representation_filter == "under") {
          df <- df[df$log2FC < 0, ]
        }
        
        gene_list <- unique(df$ENTREZID)
        if (length(gene_list) == 0) return(NULL)
        
        # ORA for KEGG
        result <- tryCatch(
          enrichKEGG(gene = gene_list, organism = organism_code,
                     pAdjustMethod = input$pathway_p_adjust_method,
                     pvalueCutoff = 1, qvalueCutoff = 1),
          error = function(e) return(NULL))
        
      } else {
        # GSEA for KEGG
        gene_list <- df$log2FC
        names(gene_list) <- df$ENTREZID
        gene_list <- sort(gene_list, decreasing = TRUE)
        gene_list <- gene_list[!duplicated(names(gene_list))]
        
        result <- tryCatch(
          gseKEGG(geneList = gene_list, organism = organism_code,
                  pAdjustMethod = input$pathway_p_adjust_method,
                  pvalueCutoff = 0.05, verbose = FALSE),
          error = function(e) return(NULL))
      }
      
    } else if (input$pathway_database == "Reactome") {
      organism_name <- if(input$organism == "Homo sapiens") "human" else "mouse"
      
      if (input$pathway_method == "ORA") {
        # Apply representation filter
        if (input$pathway_representation_filter == "over") {
          df <- df[df$log2FC > 0, ]
        } else if (input$pathway_representation_filter == "under") {
          df <- df[df$log2FC < 0, ]
        }
        
        gene_list <- unique(df$ENTREZID)
        if (length(gene_list) == 0) return(NULL)
        
        # ORA for Reactome
        result <- tryCatch(
          enrichPathway(gene = gene_list, organism = organism_name,
                        pAdjustMethod = input$pathway_p_adjust_method,
                        pvalueCutoff = 1, qvalueCutoff = 1, readable = TRUE),
          error = function(e) return(NULL))
        
      } else {
        # GSEA for Reactome
        gene_list <- df$log2FC
        names(gene_list) <- df$ENTREZID
        gene_list <- sort(gene_list, decreasing = TRUE)
        gene_list <- gene_list[!duplicated(names(gene_list))]
        
        result <- tryCatch(
          gsePathway(geneList = gene_list, organism = organism_name,
                     pAdjustMethod = input$pathway_p_adjust_method,
                     pvalueCutoff = 0.05, verbose = FALSE),
          error = function(e) return(NULL))
      }
    }
    
    return(result)
  })
  
  # Update pathway selection for PathView
  observe({
    res <- pathway_results()
    if (!is.null(res) && nrow(res@result) > 0 && input$pathway_database == "KEGG") {
      # Extract KEGG IDs
      pathway_ids <- gsub("^[a-z]{3}", "", res@result$ID)
      pathway_choices <- setNames(
        pathway_ids,
        paste0(res@result$Description, " (p.adj: ", format(res@result$p.adjust, digits = 2), ")"))
      
      updateSelectInput(session, "pathview_pathway_select",
                        choices = pathway_choices, selected = pathway_ids[1])
    } else if (input$pathway_database == "Reactome") {
      updateSelectInput(session, "pathview_pathway_select",
                        choices = list("Pathway View only available for KEGG" = ""),
                        selected = "")
    }
  })
  
  # Generate PathView visualization
  pathview_plot_reactive <- reactive({
    req(input$pathview_pathway_select)
    req(input$pathway_database == "KEGG")
    
    # Get appropriate data
    df <- if (input$pathway_method == "ORA") req(filtered_data()) else req(data())
    
    # Convert IDs
    id_mapping <- tryCatch(
      bitr(df$ID, fromType = "ENSEMBL", toType = "ENTREZID", OrgDb = OrgDb_selected()),
      error = function(e) return(NULL)
    )
    
    if (is.null(id_mapping)) return(NULL)
    df_merged <- merge(df, id_mapping, by.x = "ID", by.y = "ENSEMBL")
    
    # Create gene data vector
    gene_data <- df_merged$log2FC
    names(gene_data) <- df_merged$ENTREZID
    gene_data <- gene_data[order(abs(gene_data), decreasing = TRUE)]
    gene_data <- gene_data[!duplicated(names(gene_data))]
    
    # Generate PathView plot
    species <- if(input$organism == "Homo sapiens") "hsa" else "mmu"
    
    tryCatch({
      pv_out <- pathview(
        gene.data = gene_data, pathway.id = input$pathview_pathway_select,
        species = species, out.suffix = "feather", kegg.native = TRUE,
        map.symbol = FALSE, limit = list(gene = max(abs(gene_data))),
        bins = list(gene = 10), low = list(gene = "green"),
        mid = list(gene = "gray"), high = list(gene = "red"))
      
      return(paste0(species, input$pathview_pathway_select, ".feather.png"))
    }, error = function(e) { return(NULL) })
  })
  
  # Display PathView image
  output$pathway_view <- renderImage({
    filename <- pathview_plot_reactive()
    
    if (is.null(filename) || !file.exists(filename)) {
      list(src = "", alt = "No pathway view available")
    } else {
      list(src = filename, contentType = 'image/png', width = "100%",
           height = "auto", alt = paste("KEGG Pathway:", input$pathview_pathway_select))
    }
  }, deleteFile = FALSE)
  
  # Download handler for PathView
  output$download_pathview <- downloadHandler(
    filename = function() {
      paste0("pathway_", input$pathview_pathway_select, "_", Sys.Date(), ".png")
    },
    content = function(file) {
      filename <- pathview_plot_reactive()
      if (!is.null(filename) && file.exists(filename)) file.copy(filename, file)
    }
  )
  
  # ========== UI VISIBILITY CONTROLS ==========
  # Hide/show representation filter based on method
  observe({
    if (input$pathway_method == "GSEA") {
      shinyjs::hide("pathway_representation_filter")
    } else {
      shinyjs::show("pathway_representation_filter")
    }
  })
  
  # Render pathway network plots
  output$pathway_emapplot <- renderPlot({
    res <- pathway_results()
    
    # Early validation
    if (is.null(res) || nrow(res@result) == 0) {
      plot(1, type = "n", axes = FALSE, xlab = "", ylab = "")
      text(1, 1, "Impossible to plot, insufficient data to compute", col = "red", cex = 1.5)
      return()
    }
    
    if (nrow(res@result) < 2) {
      plot(1, type = "n", axes = FALSE, xlab = "", ylab = "")
      text(1, 1, "Impossible to plot, insufficient data to compute\n(Need at least 2 pathways for network plot)", 
           col = "red", cex = 1.2)
      return()
    }
    
    # Wrap the actual plotting in tryCatch to handle any remaining errors
    tryCatch({
      show_cat <- min(input$pathway_show_category, 30, nrow(res@result))
      render_pathway_plot(enrichplot::emapplot, res, show_cat, use_pairwise_sim = TRUE)
    }, error = function(e) {
      plot(1, type = "n", axes = FALSE, xlab = "", ylab = "")
      text(1, 1, "Impossible to plot, insufficient data to compute", col = "red", cex = 1.5)
    })
  }, height = 600, width = 800)
  
  # Render pathway concept network plot
  output$pathway_cnetplot <- renderPlot({
    res <- pathway_results()
    if (is.null(res) || nrow(res@result) == 0) {
      plot(1, type = "n", axes = FALSE, xlab = "", ylab = "")
      text(1, 1, "Impossible to plot, insufficient data to compute", col = "red", cex = 1.5)
      return()
    }
    
    # Get data based on method
    df <- if (input$pathway_method == "ORA") req(filtered_data()) else req(data())
    
    tryCatch({
      # Create fold change vector
      id_mapping <- bitr(df$ID, fromType = "ENSEMBL", toType = "ENTREZID", OrgDb = OrgDb_selected())
      df_merged <- merge(df, id_mapping, by.x = "ID", by.y = "ENSEMBL")
      
      foldchanges <- df_merged$log2FC
      names(foldchanges) <- df_merged$ENTREZID
      
      # Apply filter for ORA
      if (input$pathway_method == "ORA") {
        if (input$pathway_representation_filter == "over") {
          foldchanges <- foldchanges[foldchanges > 0]
        } else if (input$pathway_representation_filter == "under") {
          foldchanges <- foldchanges[foldchanges < 0]
        }
      }
      
      show_cat <- min(5, nrow(res@result))
      p <- cnetplot(res, foldChange = foldchanges, showCategory = show_cat)
      print(p)
      
    }, error = function(e) {
      plot(1, type = "n", axes = FALSE, xlab = "", ylab = "")
      text(1, 1, "Impossible to plot, insufficient data to compute", col = "red", cex = 1.5)
    })
  }, height = 600, width = 800)
  
  # Render pathway results table
  output$pathway_table <- DT::renderDataTable({
    res <- pathway_results()
    if (is.null(res) || nrow(res@result) == 0) {
      return(datatable(data.frame(Message = "No significant pathways found")))
    }
    
    df <- as.data.frame(res@result)
    
    # Select columns based on method and mode
    if (input$pathway_method == "ORA") {
      selected_cols <- switch(input$pathway_table_mode,
                              "detailed" = c("Description", "GeneRatio", "BgRatio", "p.adjust", "pvalue"),
                              "genes" = c("Description", "GeneRatio", "geneID"))
    } else {
      selected_cols <- switch(input$pathway_table_mode,
                              "detailed" = c("Description", "enrichmentScore", "NES", "p.adjust", "pvalue"),
                              "genes" = c("Description", "NES", "core_enrichment"))
    }
    
    # Verify columns exist
    available_cols <- intersect(selected_cols, colnames(df))
    if (length(available_cols) == 0) {
      return(datatable(data.frame(Message = "No data available for display")))
    }
    
    datatable(df[, available_cols, drop = FALSE], extensions = 'Buttons',
              options = list(pageLength = 10, scrollX = TRUE, dom = 'Bfrtip',
                             buttons = c('copy', 'csv', 'pdf')))
  })
  
  # Clean up pathview files on session end
  session$onSessionEnded(function() {
    # Remove pathview generated files
    pv_files <- list.files(pattern = "*.pathview.*", full.names = TRUE)
    if (length(pv_files) > 0) {
      file.remove(pv_files)
    }
    
    # Also remove any .png files that match the pattern
    kegg_files <- list.files(pattern = "(hsa|mmu)[0-9]+.*\\.png$", full.names = TRUE)
    if (length(kegg_files) > 0) {
      file.remove(kegg_files)
    }
    
    # Remove .xml files generated by pathview
    xml_files <- list.files(pattern = "(hsa|mmu)[0-9]+.*\\.xml$", full.names = TRUE)
    if (length(xml_files) > 0) {
      file.remove(xml_files)
    }
  })
  
}