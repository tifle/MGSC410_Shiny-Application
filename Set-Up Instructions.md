# Real Estate Valuation Shiny App Setup Instructions
## Overview
This Shiny app provides real estate value estimation based on user-provided property details. 
The backend utilizes an XGBoost model built in Python for property prediction values. 
The app is designed for deployment on an AWS EC2 instance with a Shiny Server for easy accessibility.

## Prerequisites
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
