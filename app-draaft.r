library(shiny)
options(repos = c(CRAN = "https://cloud.r-project.org"))
install.packages("xgboost")
install.packages("sf")
install.packages("dplyr")
install.packages("ggmap")
install.packages("sp")
install.packages("geosphere")
library(xgboost)
library(caret)

library(sf)
library(dplyr)
library(ggmap)
library(sp)
library(geosphere)
# Register Google API key (replace "your_api_key" with your actual API key)
register_google(key = "AIzaSyCq4alJdY60MRjNFOldG2OwWGNBW2SUxbw")
coastline <- st_read("/Users/michaelmorrison/Documents/GitHub/MGSC410_Shiny-Application/tl_2019_us_coastline/tl_2019_us_coastline.shp")


# Load the pre-trained model
model <- readRDS("model.rds")
str(model)
# Define UI for the Shiny app
ui <- fluidPage(
    titlePanel("House Price Prediction"),
    
    sidebarLayout(
        sidebarPanel(
            selectInput("hometype", "Select Home Type:", choices = c('SINGLE_FAMILY', 'TOWNHOUSE', 'MULTI_FAMILY', 'CONDO', 'APARTMENT',
       'LOT', 'HOME_TYPE_UNKNOWN', 'MANUFACTURED'), 
                  selected = "SINGLE_FAMILY", multiple = FALSE),
            numericInput("zipcode", "Zipcode: ", value = 90000, min = 0),
            numericInput("bedrooms", "Number of Bedrooms:", value = 1, min = 1),
            numericInput("bathrooms", "Number of Bathrooms:", value = 1, min = 1),
            numericInput("sqft", "Square Footage:", value = 1500, min = 500),
            numericInput("parkingCapacity", "Parking Capacity: ", value = 3, min = 1),
            checkboxInput("attachedProperty", "Has attached property?: ", value = FALSE),
            checkboxInput("hasCooling", "Has cooling?: ", value = FALSE),
            checkboxInput("landLease", "Has land lease?: ", value = FALSE),
            checkboxInput("newConstruction", "Is new construction?: ", value = FALSE),
            textInput("address", "address:", value = "1600 Amphitheatre Parkway, Mountain View, CA, USA"),
            selectInput("county", "County(Choose none if not shown): ", choices = c("None", "Fresno County", "San Diego County", "Madera County")),
            actionButton("predict", "Predict Price")
        ),
        
        mainPanel(
            h3("Predicted House Price:"),
            verbatimTextOutput("priceOutput")
        )
    )
)

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
    predict_price <- eventReactive(input$predict, {
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
            picnic_count = 2.055098684210526, # edit with arcgis and below
            camp_county = 1.7893366228070176,
            lotsize = 0,
            nearbyLotSize = 301731.6131317939,
            nearbyLatitude = 35.80472625464329,
            nearbyLongitude = -119.73470027872543,
            nearbyPrice = 763963.7899612252,
            distance_to_coast = distance_km, # get this value and 2 below
            long = geocoded$lon,
            lat = geocoded$lat,
            livingArea = 1614.0220003551567) # maybe have the user input or use sqft here
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
            tax_rate = 1.15391005545425,
            fips = 6044.606433254794, # edits with API
            location = 0
        )
        input_data_ten <- data.frame(
            county = factor(input$county, levels = c("None", "Fresno County", "San Diego County", "Madera County"))
        )
        input_data_eleven <- data.frame(
            taxHistoryValueZero = 454063.7576018946
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
        round(predicted_price, 2)  # Round to two decimal places
    })
    
    # Output the prediction result
    output$priceOutput <- renderText({
        paste0("$", predict_price())
    })
}

# Run the application
shinyApp(ui = ui, server = server)
