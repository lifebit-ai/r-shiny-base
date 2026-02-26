# Demo Shiny App
# This is a simple example app included in the base image

library(shiny)

ui <- fluidPage(
  titlePanel("R Shiny Base Image - Demo App"),

  sidebarLayout(
    sidebarPanel(
      sliderInput("n",
                  "Number of observations:",
                  min = 10,
                  max = 500,
                  value = 100),
      selectInput("color",
                  "Histogram color:",
                  choices = c("steelblue", "coral", "seagreen", "purple")),
      hr(),
      h4("Environment Info:"),
      verbatimTextOutput("env_info")
    ),

    mainPanel(
      plotOutput("histogram"),
      hr(),
      h4("R Session Info:"),
      verbatimTextOutput("session_info")
    )
  )
)

server <- function(input, output) {

  output$histogram <- renderPlot({
    data <- rnorm(input$n)
    hist(data,
         col = input$color,
         border = "white",
         main = paste("Histogram of", input$n, "random observations"),
         xlab = "Value")
  })

  output$env_info <- renderPrint({
    cat("R Version:", R.version.string, "\n")
    cat("Shiny Version:", as.character(packageVersion("shiny")), "\n")
    if (requireNamespace("BiocManager", quietly = TRUE)) {
      cat("Bioconductor:", as.character(BiocManager::version()), "\n")
    }
  })

  output$session_info <- renderPrint({
    sessionInfo()
  })
}

shinyApp(ui = ui, server = server)
