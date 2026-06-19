# LIVING-SICSS

## DOI
https://doi.org/10.5281/zenodo.20746330

## Step by step guide to run the script
In order to reproduce the analysis, researchers can run the scripts in the Living-SICSS repository in the following order:

0. download the project to ensure the right packages are used and get the data from https://www.leefbaarometer.nl/page/Opendata#score and the ODISSEI Safe Environment;
1. 01_exp_transf_liv_pc4.R: this script explores the score variables from Leefbarometer from 2024 and creates the PC4 scores that are used later for the creation of the Shiny app and as outcome of the machine learning models;
2. Script_LISS_datapreparation: this script extract the survey variables that match the livability score dimensions and provides insights to people's perception of livability;
3. 02_data_exploration_agg_innovation_spotter.R: this script explores the data about innovative industries and the impact to the area where those companies were settled in Q1 2026;
4. 03_geo_analysis_exposome_liv.ipynb: This Python notebook extracts the geocoded (.tif files) information from the Exposome data and the administrative- demographic variables that are contained in the early 2025 CBS edited dataset containining the PC6 codes in the Netherlands. Data are subsequently aggregated to PC4 level to merge them with the livability scores
5. 04_machine_learning_models_livability_pc4: this script preprocesses all input data, then trains and validates elastic net regression and random forest machine learning models to predict the "official" livability scores. The first class of models model uses "objective" environmental dimensions (Aggregated ad-hoc indicators from InnovatieSpotter from FIRMBACKBONE, created in script 02 together with the extracted administrative-demographic data and EXPOSOME data, whereas the second class of models uses indicators from the LISS panel data that inform about the respondents' lived experiences of their living situation to predict the official scores
6. app.R: this script creates a Shiny app that displays both the scores from the Leefbarometer and the results from our analysis.

## Data availability
the Leefbarometer data in openly available at https://www.leefbaarometer.nl/page/Opendata#score, whereas the other datasets are available in the SANE Secure Environment of ODISSEI. To access this data files contact info@odissei-data.nl.


## Required software and packages
### Software
- R Studio version 4.5.3 (in SANE environment)
- R Studio version 4.6 (for Shiny Dashboard)
- Python 3.8 (for geospational analysis)

### Packages (R)
dplyr 1.2.1;
ggplot2 4.0.3;
leaflet 2.2.3;
readr 2.2.0;
renv 1.2.3;
shiny 1.13.0;
writexl 1.5.4;
readxl 1.5.0;
stringr 1.6.0;
data.table 1.18.4;
tidyverse 2.0.0;
psych 2.5.3;
haven 2.5.5;
foreign 0.8-91;
here 1.0.2;
arrow 24.0.0;
caret 7.0-1;
doParallel 1.0.17

### Modules (python)
In order to make the python script that extracts the geocoded exposome data run, first install the necessary modules with pip install <module-name>
The modules used are:

pathlib
pandas
geopandas
rasterio
matplotlib
os
numpy

## Leefbarometer data 
The Leefbarometer data provides scores for livability in the Netherlands. The data is pubicly available here: https://www.leefbaarometer.nl/page/Opendata#scores.
We chose to work with the 2024 data. Both geospatial data and data about the livability scores were downloaded. In particular, we decided to work with PC4 level geospatial geometry. Gemeente level geospatial data was also imported in order to then provide nicer overview in the Shiny app, but it is not used in the analysis.
Exploration of the score variables has been done with summaries and plots. Scores have been rescaled to 0-100 values, in order to improve understandability. Scores data and PC4 geometries have been merged in order to conduct the analysis, whereas PC4 data and Gemeente has been linked for shiny app visualizations.
Available variables:
- PC4 geometries;
- livability score;
- difference from national average score;
- security;
- amenities;
- social cohesion;
- physical environment;
- housing stock;
- Gemeente geometry.

## LISS data  
We used wave 18, year 2025 of LISS data, in particular the following core studies: 
Social Integration & Leisure: https://www.dataarchive.lissdata.nl/study-units/view/6 
- Economic Situation: Housing: https://www.dataarchive.lissdata.nl/study-units/view/37
- Health: https://www.dataarchive.lissdata.nl/study-units/view/12
- Work & Schooling: https://www.dataarchive.lissdata.nl/study-units/view/16.
  
To explore people's perception of liveability, we attempt to match variables from LISS Core Studies data to dimensions of Liveability Score. 

Liveability score consists of the following dimensions:
- Environment (Natural and Infrastructure);
- Housing;
- Amenities;
- Social cohesion;
- Safety.

However, there is no publicly available information on what specific measures were included in calculating the final score and the weightings, therefore, we try to match as closely as possible to the subdimensions presented in the following documentation: https://www.leefbaarometer.nl/resources/LBM3Instrumentontwikkeling.pdf 

The LISS core studies used to extract variables matching Livability score dimensions are the following: 
- Social Integration & Leisure: https://www.dataarchive.lissdata.nl/study-units/view/6 
- Economic Situation: Housing: https://www.dataarchive.lissdata.nl/study-units/view/37
- Health: https://www.dataarchive.lissdata.nl/study-units/view/12
- Work & Schooling: https://www.dataarchive.lissdata.nl/study-units/view/16

The variables were matched based on the interpretation of the meaning and were validated later through the machine learning model on how well they are able to predict livability score and how well they are aligned with the government model. The more detailed matching can be found in the document titled "Matching dimensions to variables" in the same folder. 

The preprocessing of the data included the following steps:
1) Loading the datasets, extracting the selected variables (all from Wave 18).
2) Assigning meaningful names to the variables and adding indicators for dimensions at the beginning of the variable names: ENV_ for environment, HOUS_ for housing, AMEN_ for amenities, SOC_ for social cohesion, SAF_ for safety.
3) Matching the data to PC6 and deriving PC4 out of PC6 data for consistency puposes across datasets and as PS4 is a good compromise between detailed and not too sensitive.
4) Recoding the variables (reducing number of categories for some variables for computational purposes, reverse-coding negatively phrased items to assign higher value to responses that align with higher livability, recoding -9/-8 values into NAs).
5) Aggregating all data on PS4 level: means for binary/likert-scale questions, modes for categorical variables to select the most frequent category in a neighbourhood.

## Matching dimensions document
In this excel file we have written down the dimensions of the official livability score and we have linked the survey data to each dimension. These variables are the ones that we used in the predictive models.

## EXPOSOME data
The EXPOSOME data offers a wide variety of variables measuring environmental dimensions such as pollution, biodiversity and light intensity. 
Whenever multiple years were available, we used the one most adjacent to the year of the livability scores (2024). The exposures are described in more detail in the 
python script (03_geo_analysis_exposome_liv.ipynb)

The following exposures were extracted:
- NO2 exposure mean average in 2023 per PC4
- Access to different kinds of food
- Light exposure at night (2020, within buffer of 300, 500 and 1000m)
- walkability
- Urbanicity (scores from 2015)


## FIRMBAKBONE data
This dataset, also accessible through SANE, covers a wide range of topics. In particular, we used the InnovatieSpotter data from Q1 2026, which covers topics about innovation in industries and environmental data. This data is aggregated at PC4 level as well.
The Firmbackbone data has been preprocessed in R and some skewed count and sum variables have been log transformed to avoid distribution based issues in the machine learning modeling

## Machine lerning modelling
All variable sets were used as input for machine learning 
We carried out the following preprocessing steps:
- normalize all numeric variables (except for the ones from the InnovatieSpotter dataset)
- one-hot encode all categorical variables
- remove variables with very low variance
- remove variables that are highly correlated with other variables
- median impute missing values

We created 2 different variables sets to train our models on: 
1) "Objective predictors": EXPOSOME features, administrative-demographic features and aggregated variables from the InnovatieSpotter data
2) "Subjective predictors": variables from the LISS panel that contain information about the living situation of the participants

On both feature sets, we carried out the preprocessing steps named above and then trained an elastic net (Nogueira et al., 2018, Tay et al., 2023) and a random forest (Breiman, 2001) model. 

Elastic net is a Regularized regression technique that can be used to deal with problems of multicollinearity and overfitting thus advisable for high-dimensional datasets
it is  a linear regression algorithm that adds two penalty terms to least-squares
containing an objective function (L1 and L2 norm of coefficient vector multiplied by hyperparameters lambda and alpha)
L1: feature selection
L2: feature shrinkage

Hyperparameters tuned: 
- lambda: regularization parameter 
(when > 0, elastic net penalty kicks in, we shrink parameters)
- alpha: mixing parameter between L1 and L2 norms (penalty)

random forest is more flexible, decision-tree based and can also accomodate non-linearities
Hyperparameters tuned :
-	mtry: number of features that are available to be considered at each split. 
-	min.node.size: Minimum number of samples required to split a node 
- Splitrule (more variance or extratrees)

  We created a 80-20 train test split in both feature sets before modelling where we ensured that the distribution of the livability scores
  was comparable in both splits. We trained the model using 5 fold cross-validation on the training set and calculated training and test error. Since the outcome was continuous (livability scores, transformed to a 0-100 scale), we calculated RMSE and MAE as outcome values

  The files plot_MAE.png and plot_RMSE.png visualize model performance depedent on variable set and model family in train and test set.

  The model that performed best was the random forest model trained on the objective predictors which reached an MAE of 1.43 in the training set and 4.02 in the test set indicating that on average, the prediction was off by 1.43 points and 4.02 scores respectively compared to the true scores.

  This model had the following CV-tuned hyperparameters: mtry = 30, splitrule = "variance", min.node.side = 1


## Shiny App
We created a Shiny app in order to visualize both the livability scores from the Leefbarometer (2024) and our prdicted scores at the PC4 level.
The app has some features to maximaze usefullness of the dashboard, in particular the following:
- interchangeable scores: on the left sidebar we can change the score we want to visualize (final score or subdimensions);
- geographical levels: again on the left sidebar there is the opportunity to vizualise scores for the whole country or select just one municipality. This will ensure readability. If a specific municipality is chosen (being by clicking on it or typing it), the PC4 areas that don't belong to the specific municipality will turn gray.
- PC4 info: by dragging the mouse on a specific PC4 area, a pop up legend will show the PC4 code, the municipality it belongs to and the livability score, rounded to the second decimal.


## License
Copyright [2026] [Gilazh, Leitritz, Lunardelli]

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

