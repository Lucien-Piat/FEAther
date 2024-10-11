function(input, output, session) {
  
  # Reactive expression to read the uploaded file
  data <- reactive({
    req(input$file)  # Ensure file input is available
    
    # Check if the uploaded file is a CSV file
    if (tools::file_ext(input$file$name) != "csv") {
      show_shiny_error("File upload error", "Please upload a file with a .csv extension.")
      return(NULL)
    }
    
    separator <- switch(input$separator,
                        Semicolon = ';',
                        Comma = ",", 
                        Tab = "\t", 
                        Space = " ", 
                        Dot = ".")
    
    df <- read.csv(input$file$datapath, header = input$header, sep = separator, stringsAsFactors = FALSE)
    req(nrow(df) > 0)  # Ensure the data frame is not empty
    
    # Check if the required columns are present
    if (!all(c("GeneName", "ID", "log2FC", "pval") %in% colnames(df))) {
      show_shiny_error("File upload error", "The uploaded file must contain 'GeneName', 'ID', 'log2FC', and 'pval' columns.")
      return(NULL)
    }
    
    df  # Return the dataframe
  })
  
  # Render the volcano plot
  output$plot_1 <- renderGirafe({
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
  
  # Render the filtered table
  output$table <- DT::renderDataTable({
    req(data())  # Require the filtered data
    datatable(data(), options = list(pageLength = 10))
  })
}