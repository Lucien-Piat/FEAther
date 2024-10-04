function(input, output, session) {
  
  # Reactive expression to read the uploaded file
  data <- reactive({
    req(input$file)  # Require the file input to be available
    
    separator <- switch(input$separator, 
                        Comma = ",", 
                        Tab = "\t", 
                        Space = " ", 
                        Dot = ".")
    
    # Attempt to read the file
    tryCatch({
      df <- read.csv(input$file$datapath, 
                     header = input$header, 
                     sep = separator, 
                     stringsAsFactors = FALSE)
      req(nrow(df) > 0)  # Ensure the data frame is not empty
      df
    }, error = function(e) {
      shinyalert::shinyalert(
        title = "Error", 
        text = tags$div(
          tags$img(src = "dodo.png", height = "50px"), 
          tags$p("Your file is of invalid format, use a .csv file")  # Error message with dodo for max fun
        ), 
        type = "error", 
        html = TRUE
      )
      NULL
    })
  })
  
  output$table <- DT::renderDataTable({
    req(data())  # Require the data to be available
    datatable(data(), options = list(pageLength = 10))  # Display data in table format
  })
  
  
  output$plot_1 <- renderPlot({
    req(data())  

  })
  

  output$plot_2 <- renderPlot({
    req(data())  #
 
  })
  
  # Download handler
  output$download <- downloadHandler(
    filename = function() {
      paste("data-", Sys.Date(), ".csv", sep="")
    },
    content = function(file) {
      req(data())  
      write.csv(data(), file, row.names = FALSE)
    }
  )
}