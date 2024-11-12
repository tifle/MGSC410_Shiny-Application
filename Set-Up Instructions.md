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
2.5) If Step 2 doesn't work, and the installation process appears to have stopped
  * Reasoning: the packages you're installing might be too big for i2.micro to handle
  * Alternatives:
    1) Simplify your Model (XGBoost --> Linear Regression)
    * XGBoost's package is pretty large, and the server might not have enough computational
      power to fully install this package
    2) Utilize Docker Containers

1) R and Shiny: Ensure that R and Shiny are installed on your system.
* Install R from CRAN.
* Install Shiny in R by running:

```
install.packages("shiny")
```
2) Python and Dependencies: Python 3.X and necessary libraries must be installed.

* Install Python from Python.org.
* Install Python dependencies by running:
bash
```
pip install xgboost pandas scikit-learn
```
3) Shiny Server (For Deployment on EC2): Install Shiny Server to host the application on AWS.
* For instructions, please visit the Shiny Server installation guide.
  
## Running the App Locally
1) Clone the Repository: Start by cloning the project repository in your computer's terminal.
```
git clone <https://github.com/tifle/MGSC410_Shiny-Application>
cd MGSC410_Shiny-Application
```
2) Start R Shiny App:
* Open R, set the working directory to the app folder, and run:
```
library(shiny)
runApp("app")
```
* The app will open in a web browser, allowing you to input property details and get an estimate.

## Run Backend Model:
1) Ensure your Python environment is activated.
2) Launch the Python script that contains the XGBoost model to start serving predictions (if using Flask or a REST API).

## Deploying on AWS EC2
1) Setup EC2 Instance:
*  Launch an AWS EC2 instance (Ubuntu or Amazon Linux recommended).
*  Open the following ports in the security group:
  * 22 for SSH
  * 3838 for Shiny Server
  
2)  Install Dependencies on EC2:
*  Update and install R, Shiny, and Shiny Server.
```
sudo apt update
sudo apt install -y r-base
sudo apt install gdebi-core
wget wget https://download3.rstudio.org/ubuntu-18.04/x86_64/shiny-server-1.5.22.1017-amd64.deb
sudo gdebi shiny-server-1.5.22.1017-amd64.deb
```
3) Install Python and Model Dependencies:

* Install Python and required packages:
```
sudo apt install -y python3-pip
pip3 install xgboost pandas scikit-learn
```
4) Deploy the App:
* Copy your app files to /srv/shiny-server/ on the EC2 instance:
```
sudo cp -r /path-to-your-app /srv/shiny-server/real-estate-valuation-app
```
5) Start Shiny Server:
* Shiny Server should start automatically. Access the app at:
vbnet
```
http://<EC2-public-IP>:3838/real-estate-valuation-app/
```
## Usage Instructions
Open the App: Visit the app’s URL and enter the property details in the input fields.
Get Prediction: After entering details, click "Generate" to receive an estimated property value and a map including nearby tourist attractions and picnic areas.
