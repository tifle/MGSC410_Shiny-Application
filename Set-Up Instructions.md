# Real Estate Valuation Shiny App Setup Instructions
## Overview
This Shiny app provides real estate value estimation based on user-provided property details. 
The backend utilizes an XGBoost model built in Python for property prediction values. 
The app is designed for deployment on an AWS EC2 instance with a Shiny Server for easy accessibility.

Disclaimer! This guide is for setting up a Shiny Application built on R.

## Step 2: Setting Up an AWS EC2 Instance
### Launching a New EC2 Instance
1) Sign into your AWS Amazon Account
2) In AWS Management Console, select **EC2**
3) Click Launch Instance
  a) Name instance (i.e. "Shiny-App Server") -- can be anything you would like
  b) **AMI**: **Ubuntu Server 24.04 LTS** 
  c) **Instance Type**: `t2.micro`
  d) **Key Pair**:
    * Create a new key
    * Name it (i.e. "Shiny Key") -- can be anything you would like
    * Select **.pem** format
    * Download & save it in a place you'll remember
  e) **Security Group**
    * Four (4) Inbound Rules
      |  Type    | Port # | Source |
      |:---------|:------:|:------:|
      |SSH       |22      |Anywhere|
      |Custom TCP|3838    |Anywhere|
      |Custom TCP|8000    |Anywhere|
      |Custom TCP|80      |Anywhere|
   f) Launch Instance

### Option 1: Connecting Instance via SSH -- Longer Version
NOTE! Here are some sample values to help you find your unique AWS values
|Name               |Structure                                                       |Sample                             |
|:------------------|:--------------------------------------------------------------:|:----------------------------------|
|Public IPv4 Address| Digits and "." |12.34.567.89
|Your-ec2-public-ip | ec2-**public ipv4 address separated by "i"**.**serverArea**.compute.amazonaws.com|ec2-12-34-567-89.us-east-2.compute.amazonaws.com|
1) Copy the Public IPv4 Address
2) Open Windows Powershell or Mac Terminal
3) Change the directory to where the .pem file is stored
```
cd path\to\your-key.pem
```
4) Connect to the instance
```
ssh -i "your-key.perm" ubuntu@"your-ec2-public-ip"
```
* NOTE! Replace "your-key.pem" and "your-ec2-public-ip" to your key name and unique ec2-public-ip
* Confirm with **yes** when prompted, and now you've successfully connected to the Ubuntu Server!
  
### Option 2: Connecting Instance on AWS Site - Shortcut Version
1) Navigate to your instance on Amazon AWS
2) Click **Connect**, and it'll navigate you to a power shell/terminal that's already connected to the Ubuntu Server

## Step 3: Installing the Appropriate Packages
### 3.1 - Update the Instance & R
1) Update the Package Lists
  ```
sudo apt update && sudo apt upgrade -y
```
2) Install R
```
sudo apt-get install r-base
```
3) Install the Shiny R Package
```
sudo su - -c "R -e \"install.packages('shiny', repos='https://cran.rstudio.com/')\""
```
### 3.2 - Install the Shiny Server
Disclaimer, the following information was sourced from [Shiny Server](https://posit.co/download/shiny-server/), so the information might be updated for future updates :)

1) Download `gdebi` which is used to install the Shiny Server & its dependencies
```
sudo apt-get install gdebi-core
```
2)  Install Shiny Server Software for Ubuntu 18.04+
```
wget https://download3.rstudio.org/ubuntu-18.04/x86_64/shiny-server-1.5.22.1017-amd64.deb
```
3)  Install Shiny Server Debain Package for Ubuntu
```
sudo gdebi shiny-server-1.5.22.1017-amd64.deb
```

### 3.3 - Install Required Packages
1) Open the R console as Root (this will give your permissions to install)
```
sudo R
```
2) Install the necessary libraries
```
# Installing One Package
install.packages("ggplot2")
q() # Exit R
```
```
# Installing Multiple Packages
install.packages(c("ggplot2","plotly")) # sample libraries
q() # Exit R
```
  * If Step 2 doesn't work and the installation process appears to have stopped
    * **Reasoning**: the packages you're installing might be too big for i2.micro to handle
    * **Alternatives**:
      1) Simplify your Model (XGBoost --> Linear Regression)
         
      * XGBoost's package is pretty large, and the server might not have enough computational
        power to fully install this package
        
      2) Utilize CMake
### Utilize CMake
   ```
   git clone --recursive https://github.com/dmlc/xgboost
   cd xgboost
   mkdir build
   cd build
   cmake .. -DR_LIB=ON
   make -j$(nproc)
   make install
   ```
### Utilize Docker Container (if needed) <-- IGNORE THIS RN
* Make sure that docker is installed on your local machine & ubuntu server
  ```
  docker --version
  ```
  
1) Create & Open a Dockerfile for the R Environment
```
sudo nano Dockerfile
```
2) Make Changes to the Dockerfile
```
# Use an official R image
FROM rocker/r-ver:4.1.0  # replace with your R version

# Install system dependencies
RUN apt-get update && apt-get install -y \
    libcurl4-openssl-dev \
    libxml2-dev \
    libssl-dev \
    libomp-dev

# Install R packages
RUN R -e "install.packages(c('xgboost','sf','dplyr','ggmap','sp','geosphere'), repos = 'https://cloud.r-project.org')"

# Optional: Copy your R scripts into the container
COPY . /app

# Set the working directory
WORKDIR /app

# Run R
CMD ["R"]
```
3) Construct the docker-compose.yaml file
```
# docker-compose.yaml
# Simple R Shiny web app configuration

version: '3.8'
services:
  app:
    container_name: shiny-r-app
    build:
      context: .
      dockerfile: Dockerfile  # Make sure you have a Dockerfile with R and Shiny setup
    ports:
      - "80:3838"  # Map port 3838 (default for Shiny) to port 80 on your local machine
    environment:
      - SHINY_LOG_LEVEL=INFO  # Optional: Set Shiny log level
    restart: unless-stopped

```
4) Build the Docker Image in your App Directory on the Ubuntu Server
```
docker-compose up --build
```
5) Run the Docker Container on the EC2 Instance
```
docker run -it my-r-image
```
## Step 4: Deploy Your Application
### 4.1 Download Your App from Github
1. Navigate to the Shiny Server Directory on EC2
   ```
   cd/srv/shiny-server
   ```
2. Clone your GitHub Repo
```
sudo git clone https://github.com/your-username/your-repo-name
```
3. Move to the App Directory
```
cd shiny-app
ls # see all the files in the directory
```
### 4.1 Start the Application
1) Rename your application to `app.r``, since it's the name that Shiny expects
```
sudo mv your-app-name.r app.r
```
2) Access your application at: htttp://**your-ec2-public-id**:3838/**your-repo-name**

## Usage Instructions
Open the App: Visit the app’s URL and enter the property details in the input fields.
Get Prediction: After entering details, click "Generate" to receive an estimated property value and a map including nearby tourist attractions and picnic areas.
