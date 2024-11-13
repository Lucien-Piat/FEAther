function(input, output, session) {
  
  # Reactive expression for loading and processing the data
  data <- reactive({
    req(input$file)  # Ensure file input is available
    
    # Check if the uploaded file has a valid extension (CSV, TXT, TSV, or DAT)
    file_ext <- tools::file_ext(input$file$name)
    if (!(file_ext %in% c("csv", "txt", "tsv", "dat"))) {
      show_shiny_error("File upload error", "Please upload a tabular data file with one of the following extensions: .csv, .txt, .tsv, or .dat.")
      return(NULL)
    }
    
    # Add the separator for fread 
    separator <- switch(input$separator,
                        Auto = 'auto',
                        Semicolon = ';',
                        Comma = ",", 
                        Tab = "\t", 
                        Space = " ", 
                        Dot = ".")
    
    # Define the desired column names
    column_names <- c("GeneName", "ID", "baseMean", "log2FC", "pval", "padj")
    
    # Use fread with specified column names
    df <- tryCatch({
      fread(input$file$datapath, sep = separator, header = TRUE, col.names = column_names)
    }, error = function(e) {
      show_shiny_error("File upload error", HTML("There was an error reading the file.<br><br>Provide a file with exactly 6 columns:<br>'GeneName', 'ID', 'baseMean', 'log2FC', 'pval', and 'padj'.<br><br>A header row is optional."))
      return(NULL)
    })
    
    # Ensure the data frame is not empty
    req(nrow(df) > 0)
    
    df  # Return the dataframe
  })
  
  # Reactive expression for filtering the data based on slider inputs
  filtered_data <- reactive({
    df <- req(data())  # Ensure data is available
    
    # Apply filtering based on log2FC and p-value thresholds
    df_filtered <- df %>%
      dplyr::filter(
        abs(log2FC) >= input$log2FC_slider,
        pval <= input$p_val_slider
      )
    
    df_filtered  # Return the filtered dataframe
  })
  
  # Create the plot for use in both rendering and saving
  volcano_plot <- reactive({
    df <- req(data())  # Ensure data is available
    
    log2FC_cutoff <- input$log2FC_slider
    pval_cutoff <- input$p_val_slider
    
    log2FC_min <- -log2FC_cutoff
    log2FC_max <- log2FC_cutoff
    
    # Perform -log10 transformation on p-values
    df$log10_pval <- -log10(df$pval)
    
    # Assign colors based on log2FC and p-value thresholds
    df$color <- ifelse(df$pval >= pval_cutoff, "grey",
                       ifelse(df$log2FC < log2FC_min, "red", 
                              ifelse(df$log2FC > log2FC_max, "green", "grey")))
    
    # Create the volcano plot
    plot <- ggplot(df, aes(x = log2FC, y = log10_pval,
                           tooltip = paste("Gene:", GeneName, "<br>ID:", ID, "<br>log2FC:", log2FC, "<br>-log10(pval):", log10_pval))) +
      geom_point_interactive(aes(color = color), size = 1) +
      labs(x = "log2 Fold Change (log2FC)", y = "-log10(p-value)") +
      ylim(0, 10) +  # Cap y-axis limit
      scale_color_identity() +  # Use color as defined in df$color
      theme_minimal() +
      theme(legend.position = "none")  # Hide legend
    
    # Make the plot interactive with hover and zoom functionality
    girafe(ggobj = plot, options = list(
      opts_hover(css = "fill:#FF6347;stroke:black;cursor:pointer;"),
      opts_zoom(min = 1, max = 5)
    ))
  })
  
  # Render the volcano plot
  output$volcano_plot <- renderGirafe({
    volcano_plot()  # Just render the reactive plot
  })
  
  output$download <- downloadHandler(
    filename = function() {
      if (input$downloadType == "plot") {
        paste("volcano_plot_", Sys.Date(), ".png", sep = "")
      } else {
        paste("filtered_data_", Sys.Date(), ".csv", sep = "")
      }
    },
    
    content = function(file) {
      if (input$downloadType == "plot") {
        # Save volcano plot as PNG (same logic as before)
        df <- req(data())  # Ensure data is available
        
        log2FC_cutoff <- input$log2FC_slider
        pval_cutoff <- input$p_val_slider
        
        log2FC_min <- -log2FC_cutoff
        log2FC_max <- log2FC_cutoff
        
        # Perform -log10 transformation on p-values
        df$log10_pval <- -log10(df$pval)
        
        # Assign colors based on log2FC and p-value thresholds
        df$color <- ifelse(df$pval >= pval_cutoff, "grey",
                           ifelse(df$log2FC < log2FC_min, "red", 
                                  ifelse(df$log2FC > log2FC_max, "green", "grey")))
        
        # Create the volcano plot
        plot <- ggplot(df, aes(x = log2FC, y = log10_pval,
                               tooltip = paste("Gene:", GeneName, "<br>ID:", ID, "<br>log2FC:", log2FC, "<br>-log10(pval):", log10_pval))) +
          geom_point(color = df$color, size = 1) +
          labs(x = "log2 Fold Change (log2FC)", y = "-log10(p-value)") +
          ylim(0, 10) +  # Cap y-axis limit
          scale_color_identity() +  # Use color as defined in df$color
          theme_minimal() +
          theme(legend.position = "none")  # Hide legend
        
        # Save the plot as a PNG file
        ggsave(file, plot = plot, device = "png", width = 8, height = 6, dpi = 300)
        
      } else if (input$downloadType == "table") {
        # Download the filtered data table as CSV
        write.csv(filtered_data(), file, row.names = FALSE)
      }
    }
  )
  
  # Render the filtered data in a DataTable with search and filter options
  output$table <- DT::renderDataTable({
    req(filtered_data())  # Ensure filtered data is available
    
    # Render datatable with options
    datatable(
      filtered_data(),
      options = list(
        pageLength = 10,        # Set number of rows per page
        searchHighlight = TRUE, # Highlight search results
        filter = "top"          # Add a filter option on each column
      )
    )
  })
}
