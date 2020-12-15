library(sf); library(viridis)
library(tidyverse)
library(rnaturalearth)
library(rnaturalearthdata)
library(rgeos)
library(shiny)
library(tidyverse)
library(tidytext)
library(shinythemes)
library(tippy)
library(jpeg)
library(rsconnect)


first_date <- function(date_string){
  split = str_split(date_string,"/")
  ints = sapply(split,as.integer)
  return(mean(ints))
}

first_date("2001/2002")

wind_turbine <- readr::read_csv('https://raw.githubusercontent.com/rfordatascience/tidytuesday/master/data/2020/2020-10-27/wind-turbine.csv')

wind_turbine <- wind_turbine %>% mutate(year = sapply(commissioning_date,first_date))
projects <- wind_turbine %>% group_by(project_name) %>% summarize(capacity = mean(total_project_capacity_mw),
                                                                  latitude = mean(latitude),
                                                                  longitude = mean(longitude),
                                                                  province_territory = province_territory,
                                                                  year = mean(year)) %>%
                                                                  unique()
MWh_in_year = 24*365
avg_consumption = 11.135 #MWh per year
cumulative_MW_added <- projects %>% group_by(year,province_territory) %>% 
  summarize(total_MW_added = sum(capacity)) %>% 
  ungroup() %>% group_by(province_territory) %>%
  mutate(cumulative_MW = cumsum(total_MW_added), households_covered = MWh_in_year*cumulative_MW/(avg_consumption))

cumulative_MW_added

province <- st_read("./data/province/province.shp")
m= list(  "Alberta"= "Alberta","British Columbia"= "British Columbia","Manitoba"= "Manitoba",                 
          "New Brunswick"= "New Brunswick","Newfoundland and Labrador"= "Newfoundland and Labrador",
          "Northwest Territories"= "Northwest Territories",  
          "Nova Scotia"="Nova Scotia", "Ontario"= "Ontario",
          "Prince Edward Island"= "Prince Edward Island",    
          "Quebec"="Quebec")


ui <- fluidPage(theme = shinytheme("flatly"),
tags$head(tags$style('h4 {color:steelblue;}')), #change the color of all h4 font to steelblue

  navbarPage(title = "Welcome!",

      tabPanel("Home",
             sidebarLayout(   
               sidebarPanel(
                 br(),
                 h3("Use the tabs to explore Canada's wind turbine locations, production, and growth through the years."),
                 br(),br()
                 ),
               mainPanel(
                 fluidRow(
                    h1(tippy("Wind Energy in Canada", tooltip = "Welcome to our Shiny App: Wind Energy in Canada.")),
                    h4("More wind energy has been built in Canada between 2009 and 2020 than any other form of electricity."),
                    p("Wind energy is generating enough power to meet the needs of over three million Canadian homes."),
                    p("There are 301 wind farms operating from coast to coast, with projects in two northern territories."),
                    p("In 2019, Canada’s wind generation grew by 597 megawatts (MW) from five new wind energy projects, representing an investment of over $1 billion."),
                    p("Every Canadian province is now benefiting from clean wind energy.")
                    ),
                 fluidRow(
                   tags$img(id = "myImage", src = "image1.jpg", alt = "Image Source: NAwindpower.com"),
                   hr()
                   )
                 )
             )
      ),
      navbarMenu("Tables",
        tabPanel("Data Table",  
                 sidebarLayout(
                     sidebarPanel(
                       h3("Table Settings"),
                       p("The dataset is visualized for you in the table to the right."),
                       p("Select the columns you want to display."),
                       checkboxGroupInput("show_vars", "Columns in projects to show:",
                           names(wind_turbine), selected = names(wind_turbine)), width = 3,
         hr(),
         downloadButton("download", "Download")),
       mainPanel(
         h4("Wind Turbine Dataset (view of first 50 rows)"), br(),
         DT::dataTableOutput("table"))
       )
      ),
    tabPanel("Projects Summary",
             sidebarLayout(
               sidebarPanel(selectInput("selection", "Summary Tab Settings: Select a province to filter summary list", choices = m,selected='Alberta')),
               mainPanel(h4('Summary by Projects'), tableOutput("summary"))
               )
             )
    ),
    tabPanel("Graphs",
             sidebarLayout(
               sidebarPanel(radioButtons("selectPlot", h4("Select a plot type"),
                            choices = c("By Projects" = "projects", "By Province"="province")),
                            hr(),
               ),
               mainPanel(h4(br(),"Number of Turbines"), plotOutput("countPlots"))
             )
               
            ),
    tabPanel("Evolution of Turbines", 
             sidebarLayout(
               sidebarPanel(
                 h4("Turbine construction by province and year"),
                 sliderInput(inputId = "max", label = "Adjust years to see changes by province over time", 
                             min = 1993, max = 2019,step=1, value = 2019, animate=TRUE)
                            ),
               mainPanel(plotOutput("facetGraph"))
               )
             ),
    navbarMenu("Maps",
               tabPanel("Animated Map", 
                        sidebarLayout(
                          sidebarPanel(
                            h4("Adjust capacity settings"),
                            sliderInput(inputId = "map", label = "Adjust to see turbine capacity by location",
                                        min = 0, max = 350, step=1, value = 350, animate=TRUE)
                            ),
               mainPanel(plotOutput("animatedMap"))
               )
             ),
             tabPanel("Zoom Map",
                      fluidRow(
                        column(4,
                               h4("Click and drag over an area, then double-click to zoom in on the map."), 
                               p("Double-click again to zoom out.")),
                        column(8, align="left", plotOutput("zoomMap", height = "600px", width = "800px", 
                                    dblclick = "plot1_dblclick", brush = brushOpts(id = "plot1_brush", resetOnNew = TRUE))
                         )
                        )
                      )
             ),
    tabPanel("Presentation",
             mainPanel(
               fluidRow(
                 hr(), hr(),
                 h6("Slide 1"),
                 tags$img(id = "1", src = "slide1cover.png", alt = "Cover Page")
               ),
               fluidRow(
                 hr(), hr(),
                 h6("Slide 2"),
                 tags$img(id = "2", src = "slide2agenda.png", alt = "Agenda")
               ),
               fluidRow(
                 hr(), hr(),
                 h6("Slide 3"),
                 tags$img(id = "3", src = "slide3data.png", alt = "Data")
               ),
               fluidRow(
                 hr(), hr(),
                 h6("Slide 4"),
                 tags$img(id = "4", src = "slide4task.png", alt = "Design")
               ),
               fluidRow(
                 hr(), hr(),
                 h6("Slide 5"),
                 tags$img(id = "5", src = "slide5demo.png", alt = "Demo Slide")
               ),
               fluidRow(
                 hr(), hr(),
                 h6("Slide6"),
                 tags$img(id = "6", src = "slide6final.png", alt = "UNCC - School of Data Science")
               ),
               fluidRow(
                 hr(), hr(),
                 h4("Visual Analytics with Professor Jinwen Qiu"),
                 h4("School of Data Science, University of North Carolina - Charlotte"),
                 hr(), hr()
               )
              )
             )
      
  ) #close navbar
) #end ui

server <- function(input, output, session) {
 

  ## data table output 
  wind_turbine2 = wind_turbine[sample(nrow(wind_turbine), 50), ] 
  
  output$table <- DT::renderDataTable({
    DT::datatable(wind_turbine2[, input$show_vars, drop = FALSE])
  })
  
  # Idea is a downloadable csv of selected dataset--- not functioning as intended 
  output$downloadData <- downloadHandler(
    filename = function() {
      paste(input$dataset, ".csv", sep = "")
    },
    content = function(file) {
      write.csv(datasetInput(input$dataset), file, row.names = FALSE)
    }
  )
  ##-------------------
 
  ## summary table output 
  output$summary <- renderTable({
    subset(projects,province_territory == input$selection)
  })
  ## -------------------
 
  ## Bar Graphs output
   countPlots <- reactive({  
      projCount %>% 
        filter(projCount %in% 100:input$count)
    })
  
  output$countPlots <- renderPlot({
    if (input$selectPlot == "projects") {
      projCount <- wind_turbine %>% 
        count(project_name) %>% 
        filter(n > 50)
      projCount %>%
        ggplot(aes(forcats::fct_reorder(project_name, n), n)) +
        geom_bar(stat="identity", fill="steelblue") +
        ggtitle("Number of Turbines by Project") +
        coord_flip() +
        theme_minimal() +
        ylab('Number of Turbines') +
        xlab('Project Name')
      
    } else if (input$selectPlot == "province") {
      wind_turbine %>% 
        count(province_territory) %>% 
        ggplot(aes(forcats::fct_reorder(province_territory, n), n)) +
        geom_bar(stat="identity", fill="steelblue") +
        ggtitle("Number of Turbines for Each Province") +
        coord_flip() +
        theme_minimal() +
        ylab('Number of Turbines') +
        xlab('Province')}
  },height=800)
  ##------------------------
  
  ## facted graphs output
  yearData <- reactive({  
    m <- select(wind_turbine,year,hub_height_m,turbine_rated_capacity_k_w,province_territory) %>% 
      filter(year %in% 1993:input$max)
  })
  
  output$facetGraph <- renderPlot({
    
    ggplot(yearData(),aes(year,hub_height_m)) + 
      geom_point(aes(size=turbine_rated_capacity_k_w,color=turbine_rated_capacity_k_w)) +
      theme_bw() +
      #theme_linedraw() +
      facet_wrap(~province_territory) +
      ylab('Turbine Height') +
      xlab('Year')
  })
  ## ---------------------
 
  ## animated map output 
  data1 <- reactive({select(projects,longitude,latitude,capacity) %>% filter (capacity %in% 0:input$map ) })
  
  output$animatedMap <- renderPlot({
    province %>% 
      ggplot() +
      geom_sf(aes(fill = NAME)) + 
      geom_sf_text(aes(label=NAME),size =1.5) + 
      geom_point(data = data1(), aes(x = longitude, y = latitude, size = capacity))+
      theme_minimal()
  }, height = 800)
  ## ----------------------
  
  ## zoom map output
  ranges <- reactiveValues(x = NULL, y = NULL)
  
  output$zoomMap <- renderPlot({
    
    world <- ne_countries(scale = "medium", returnclass = "sf")
    
    ggplot(data = world) +
      geom_sf() + 
      coord_sf(xlim = ranges$x, ylim = ranges$y, expand = FALSE) +
      geom_point(data = projects, aes(x = longitude, y = latitude, size = capacity,color=province_territory), alpha=.5) +
      labs(x = "", y="",
           title="Harnessing the Wind",
           subtitle = 'Canadian Wind Power Generation',
           caption="Data Source: Government of Canada | Analysis: @The_DataViz",
           color = "Province",
           size = "Total Project\nCapacity [MW]") +
      theme_bw() +
      theme(plot.title = element_text(face="bold")) 
  })
  
  observeEvent(input$plot1_dblclick, {
    brush <- input$plot1_brush
    if (!is.null(brush)) {
      ranges$x <- c(brush$xmin, brush$xmax)
      ranges$y <- c(brush$ymin, brush$ymax)
      
    } else {
      ranges$x <- NULL
      ranges$y <- NULL
    }
    
  })
  ## ---------------------
}

shinyApp(ui, server)
