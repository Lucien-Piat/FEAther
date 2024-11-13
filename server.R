# -----------------------------------------
# Project: FEA-ther (Functional Enrichment Analysis Tool)
# Author: Lucien Piat
# Affiliation: Rouen Normandie University
# Creation: 04/10/2024
# Last update : 13/11/2024
# -----------------------------------------
source("functions.R")

# Function used by the UI
function(input, output, session) {
  # -----------------------------------------
  # Data input
  # -----------------------------------------
  
  # Reactive expression for loading and processing the data
  data <- reactive({
    req(input$file) # Ensure file input is available
    
    # Check if the uploaded file has a valid extension (CSV, TXT, TSV, or DAT)
    file_ext <- tools::file_ext(input$file$name)
    if (!(file_ext %in% c("csv", "txt", "tsv", "dat"))) {
      show_shiny_error("File upload error", "Please upload a tabular data file with one of the following extensions: .csv, .txt, .tsv, or .dat.")
      return(NULL)
    }
    
    # Add the separator for fread
    separator <- switch(input$separator, Auto = "auto", Semicolon = ";", Comma = ",", Tab = "\t", Space = " ", Dot = ".")
    
    # Define the desired column names
    column_names <- c("GeneName", "ID", "baseMean", "log2FC", "pval", "padj")
    
    # Use fread with specified column names
    df <- tryCatch({
      fread(input$file$datapath, sep = separator, header = TRUE, col.names = column_names)
    }, error = function(e) {
      show_shiny_error("File upload error", HTML("There was an error reading the file.<br><br>Provide a file with exactly 6 columns:<br>'GeneName', 'ID', 'baseMean', 'log2FC', 'pval', and 'padj'.<br><br>A header row is optional."))
      return(NULL)
    })
    req(nrow(df) > 0) # Ensure the data frame is not empty
    df # Return the dataframe
  })
  
  # -----------------------------------------
  # Filter data
  # -----------------------------------------
  
  # Reactive expression for filtering the data based on slider inputs
  filtered_data <- reactive({
    df <- req(data()) # Ensure data is available
    df_filtered <- df %>% dplyr::filter(abs(log2FC) >= input$log2FC_slider, pval <= input$p_val_slider)
    df_filtered # Return the filtered dataframe
  })
  
  # -----------------------------------------
  # Create the volcano plot
  # -----------------------------------------
  
  volcano_plot <- reactive({
    df <- req(data()) # Ensure data is available
    plot <- filtered_plot(df, input$log2FC_slider, input$p_val_slider) # Create a volcano plot
    girafe(ggobj = plot, options = list(opts_hover(css = "fill:#FF6347;stroke:black;cursor:pointer;"), opts_zoom(min = 1, max = 5))) # Interactive plot
  })
  
  # Render the volcano plot
  output$volcano_plot <- renderGirafe({ volcano_plot() })
  
  # -----------------------------------------
  # Download
  # -----------------------------------------
  
  output$download <- downloadHandler(
    filename = function() {
      if (input$downloadType == "plot") paste("volcano_plot_", Sys.Date(), ".png", sep = "")
      else paste("filtered_data_", Sys.Date(), ".csv", sep = "")
    },
    content = function(file) {
      if (input$downloadType == "plot") {
        df <- req(data()) # Ensure data is available
        plot <- filtered_plot(df, input$log2FC_slider, input$p_val_slider)
        ggsave(file, plot = plot, device = "png", width = 8, height = 6, dpi = 300)
      } else if (input$downloadType == "table") {
        write.csv(filtered_data(), file, row.names = FALSE) # Download CSV
      }
    }
  )
  
  # -----------------------------------------
  # Render the Table
  # -----------------------------------------
  
  output$table <- DT::renderDataTable({
    req(filtered_data()) # Ensure filtered data is available
    datatable(filtered_data(), options = list(pageLength = 10, searchHighlight = TRUE, filter = "top")) # Render table
  })
}
