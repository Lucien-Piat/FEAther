function(input, output, session) {
  
  # Reactive expression to read the uploaded file
  data <- reactive({
    req(input$file)  # Require the file input to be available
    separator <- switch(input$separator, 
                        Comma = ",", 
                        Tab = "\t", 
                        Space = " ", 
                        Dot = ".")
    
    # Read the file
    read.csv(input$file$datapath, 
             header = input$header, 
             sep = ',', 
             stringsAsFactors = FALSE)
  })
  
  # Render the DataTable in the UI
  output$table <- DT::renderDataTable({
    req(data())  # Require the data to be available
    datatable(data(), options = list(pageLength = 10))  # Display data in table format
  })
  
  # Future output here
  output$plot_1 <- renderPlot({
  })
  
  output$plot_2 <- renderPlot({
  })
  
  # Future download button 
  output$download <- downloadHandler(
    filename = function() {
      paste("data-", Sys.Date(), ".csv", sep="")
    },
    content = function(file) {
      write.csv(data(), file, row.names = FALSE)
    }
  )
}