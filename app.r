library(shiny)
#options(repos = c(CRAN = "https://cloud.r-project.org"))
#install.packages("xgboost")
#install.packages("sf")
#install.packages("dplyr")
#install.packages("ggmap")
#install.packages("sp")
#install.packages("geosphere")
#install.packages("leaflet")
library(xgboost)
library(caret)
library(leaflet)
library(sf)
library(dplyr)
library(ggmap)
library(sp)
library(geosphere)
#install.packages("bslib")
library(bslib)  # for theme
#install.packages("scales")
library(scales)

#install.packages("httr")
#install.packages("jsonlite")

library(httr)
library(jsonlite)
# Register Google API key (replace "your_api_key" with your actual API key)
register_google(key = "AIzaSyCq4alJdY60MRjNFOldG2OwWGNBW2SUxbw")
coastline <- st_read("tl_2019_us_coastline/tl_2019_us_coastline.shp")

# Set your API key
api_key <- "AIzaSyCq4alJdY60MRjNFOldG2OwWGNBW2SUxbw"

# Function to search for places near a given location
get_nearby_places <- function(lat, lon, radius = 5000, type = "park") {
  url <- paste0(
    "https://maps.googleapis.com/maps/api/place/nearbysearch/json?",
    "location=", lat, ",", lon,
    "&radius=", radius,
    "&type=", type,
    "&key=", api_key
  )

  response <- GET(url)
  data <- fromJSON(content(response, as = "text"))

  if (data$status == "OK") {
    return(data$results)
  } else {
    stop("Error:", data$status)
  }
}

# Load the pre-trained model
model <- readRDS("model.rds")
str(model)
# Define UI for the Shiny app
ui <- fluidPage(
    theme = bs_theme(
    bg = "#36454F",  # Background color for the app
    fg = "#FFFFFF",  # Text color
    primary = "#007bff",  # Primary color (e.g., for buttons)
    secondary = "#28a745",  # Secondary color (e.g., for other elements)
    base_font = font_google("Roboto")  # Font style
  ),
    titlePanel("House Price Prediction"),
    
    sidebarLayout(
        sidebarPanel(
            textInput("address", "address:", value = "121 34th Street, Newport Beach, CA, USA"),
            selectInput("hometype", "Select Home Type:", choices = c('SINGLE_FAMILY', 'TOWNHOUSE', 'MULTI_FAMILY', 'CONDO', 'APARTMENT',
       'LOT', 'HOME_TYPE_UNKNOWN', 'MANUFACTURED'), 
                  selected = "SINGLE_FAMILY", multiple = FALSE),
            numericInput("zipcode", "Zipcode: ", value = 92663, min = 0),
            numericInput("bedrooms", "Number of Bedrooms:", value = 1, min = 1),
            numericInput("bathrooms", "Number of Bathrooms:", value = 1, min = 1),
            numericInput("sqft", "Square Footage:", value = 1500, min = 500),
            numericInput("parkingCapacity", "Parking Capacity: ", value = 3, min = 1),
            checkboxInput("attachedProperty", "Has attached property?: ", value = FALSE),
            checkboxInput("hasCooling", "Has cooling?: ", value = FALSE),
            checkboxInput("landLease", "Has land lease?: ", value = FALSE),
            checkboxInput("newConstruction", "Is new construction?: ", value = FALSE),
            #textInput("address", "address:", value = "1600 Amphitheatre Parkway, Mountain View, CA, USA"),
            #selectInput("county", "County(Choose none if not shown): ", choices = c("None", "Fresno County", "San Diego County", "Madera County")),
            actionButton("generate", "Generate"),
            #actionButton("search", "Generate Map:")
        ),
        
        mainPanel(
            fluidRow(
                h4("Predicted House Price:"),
                verbatimTextOutput("priceOutput")),
            fluidRow(
                h4("Map"), 
                leafletOutput("map")

        )
    )
))

#['taxHistory/5/value', 'taxHistory/6/value',
 #      'priceHistory/0/attributeSource/infoString2',
  #     'priceHistory/2/attributeSource/infoString2', 'taxHistory/7/taxPaid',
   #    'taxHistory/6/time', 'taxHistory/2/time', 'taxHistory/8/time',
    #   'taxHistory/4/value', 'picnic_count', 'camp_county',
     #  'resoFacts/lotSize', 'nearbyHomes/1/lotSize', 'nearbyHomes/1/latitude',
      # 'nearbyHomes/1/longitude', 'nearbyHomes/1/price', 'distance_to_coast',
       #'longitude', 'latitude', 'livingArea', 'homeType', 'bathrooms',
    #   'bedrooms', 'zipcode', 'adTargets/bd', 'adTargets/sqft',
     #  'resoFacts/laundryFeatures/0', 'resoFacts/parkingCapacity',
      # 'resoFacts/hasAttachedProperty', 'resoFacts/hasCooling',
       #'resoFacts/hasLandLease', 'resoFacts/isNewConstruction',
      # 'propertyTaxRate', 'countyFIPS', 'county', 'taxHistory/0/value']

# Define server logic for the Shiny app
server <- function(input, output) {
    # Reactive expression to get input features as a matrix for prediction
    predict_price <- eventReactive(input$generate, {
        # Prepare input data as a matrix or dataframe matching model's input format
        #input_one <- data.frame(hometype = as.factor(input$hometype))
        geocoded <- geocode(input$address)
        address_point <- st_as_sf(data.frame(lon = geocoded$lon, lat = geocoded$lat), 
                          coords = c("lon", "lat"), crs = 4326)

        # Calculate the distance in meters
        coastline <- st_transform(coastline, st_crs(address_point))
        distance <- st_distance(address_point, coastline) %>% min()
        distance_km <- as.numeric(distance) / 1000  # Convert to kilometers
        #print(paste("Distance to coast:", round(distance_km, 2), "km"))
        rev_geocode_result <- revgeocode(as.numeric(geocoded), output = "all")
        zip_code <- rev_geocode_result$postal_code

        picnic_areas <- get_nearby_places(geocoded$lat, geocoded$lon, radius = 5000, type = "park")  # Use type "park" for picnic areas
        trails <- get_nearby_places(geocoded$lat, geocoded$lon, radius = 5000, type = "tourist_attraction")
        num_picnic_areas <- length(picnic_areas)
        num_trails <- length(trails)

        input_data_one <- data.frame(
            taxHistory_5_value = 341338.0154839849, 
            taxHistory_6_value = 320195.0922883225)
        input_data_two <- data.frame(
            pricehistory_stringone = factor('None', levels = c('None', 'Fresno MLS', 'MLSListings Inc', 'Bakersfield AOR',
       'SDMLS', 'CRMLS', 'SFAR', 'bridgeMLS/CCAR/Bay East AOR',
       'Public Record', 'TAAR', 'Zillow Rentals', 'TCMLS', 'CLAW',
       'GAVAR', 'MetroList Services of CA', 'BAREIS', 'Kings County MLS',
       'BHHS broker feed')))
        input_data_three <- data.frame(
            pricehistory_stringtwo = 0, 
            taxHistorytaxPaid_seven = 3923.813233880065,
            taxHistorytaxTime_six = 1530094392360.2234, 
            taxHistorytaxTime_two = 1655662541177.4106, 
            taxHistorytaxTime_eight = 1465941179948.31,
            taxHistorytaxValue_four = 359755.4769059106,
            picnic_count = as.numeric(num_picnic_areas), # edit with arcgis and below
            camp_county = as.numeric(num_trails),
            lotsize = as.numeric(input$sqft),
            nearbyLotSize = as.numeric(input$sqft),
            nearbyLatitude = geocoded$lon,
            nearbyLongitude = geocoded$lat,
            nearbyPrice = 0,
            distance_to_coast = distance_km, # get this value and 2 below
            long = geocoded$lon,
            lat = geocoded$lat,
            livingArea = as.numeric(input$sqft)) # maybe have the user input or use sqft here
        input_data_six <- data.frame(
            hometype = factor(input$hometype, levels = c('SINGLE_FAMILY', 'TOWNHOUSE', 'MULTI_FAMILY', 'CONDO', 'APARTMENT',
       'LOT', 'HOME_TYPE_UNKNOWN', 'MANUFACTURED')))
        input_data_seven <- data.frame(
            bathrooms = as.numeric(input$bathrooms),
            bedrooms = as.numeric(input$bedrooms),
            zipcode = as.numeric(input$zipcode),
            bd = as.numeric(input$bathrooms),
            sqft = as.numeric(input$sqft),
            laundryFeatures = 0,
            parkingCapacity = as.numeric(input$parkingCapacity),
            attachedProperty = ifelse(input$attachedProperty, 1, 0),
            hasCooling = ifelse(input$hasCooling, 1, 0),
            landLease = ifelse(input$landLease, 1, 0),
            newConstruction = ifelse(input$newConstruction, 1, 0),
            tax_rate = 1.1,
            fips = 0 # edits with API
            #location = 
        )
        input_data_ten <- data.frame(
            county = factor('None', levels = c("None", "Fresno County", "San Diego County", "Madera County"))
        )
        input_data_eleven <- data.frame(
            taxHistoryValueZero = 454063.7576018946,
            location = 454063.7576018946
        )
        # evens are dummied
        dummy_2 <- dummyVars(~ ., data = input_data_two)
        encoded_two <- predict(dummy_2, newdata = input_data_two)
        #dummy_4 <- dummyVars(~ ., data = input_data_four)
        #encoded_four <- predict(dummy_4, newdata = input_data_four)
        dummy_6 <- dummyVars(~ ., data = input_data_six)
        encoded_six <- predict(dummy_6, newdata = input_data_six)
        #dummy_8 <- dummyVars(~ ., data = input_data_eight)
        #encoded_eight <- predict(dummy_8, newdata = input_data_eight)
        dummy_10 <- dummyVars(~ ., data = input_data_ten)
        encoded_ten <- predict(dummy_10, newdata = input_data_ten)
        # Convert to matrix if required (e.g., xgboost expects matrix input)
        #input_clean <- as.data.frame(model.matrix(~ . - 1, data = input_one))
        #input_matrix <- rbind(input_matrix, input_one)
        input_data <- cbind(input_data_one, encoded_two, input_data_three, encoded_six,
                            input_data_seven, encoded_ten, input_data_eleven)
        input_matrix <- as.matrix(input_data)
        
        # Make the prediction
        predicted_price <- predict(model, input_matrix)
        comma(round(predicted_price, 2))  # Round to two decimal places
    })
    
    # Output the prediction result
    output$priceOutput <- renderText({
            paste0("$", predict_price())
        })

    observeEvent(input$generate, {
        address <- input$address
        location <- geocode(address)
        
        if (!is.null(location)) {
            lat <- location$lat
            lon <- location$lon
            
            # Get picnic areas and trails
            picnic_areas <- get_nearby_places(lat, lon, radius = 5000, type = "park")
            trails <- get_nearby_places(lat, lon, radius = 5000, type = "tourist_attraction")
            
            # Counts
            picnic_area_count <- length(picnic_areas)
            trail_count <- length(trails)
            
            # Render the map
            output$map <- renderLeaflet({
                leaflet() %>%
                addTiles() %>%
                setView(lng = lon, lat = lat, zoom = 13) %>%
                addMarkers(
                    lng = lon, lat = lat,
                    popup = paste(
                    "<b>Address:</b>", address, "<br>",
                    "<b>Nearby Picnic Areas:</b>", picnic_area_count, "<br>",
                    "<b>Nearby Trails:</b>", trail_count
                    )
                ) %>%
                addCircleMarkers(data = picnic_areas, 
                                ~geometry$location$lng, ~geometry$location$lat, 
                                color = "blue", radius = 5, label = "Picnic Area") %>%
                addCircleMarkers(data = trails, 
                                ~geometry$location$lng, ~geometry$location$lat, 
                                color = "green", radius = 5, label = "Toursit Attraction") %>%
                # Add a legend
                addLegend(position = "bottomright", 
                    colors = c("blue", "green"),
                    labels = c("Picnic Area", "Tourist Attraction"),
                    title = "Legend (5km radius)")
            })
        } else {
        showNotification("Address not found. Please try again.", type = "error")
        }
  })
}

# Run the application
shinyApp(ui = ui, server = server)
