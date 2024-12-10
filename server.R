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
