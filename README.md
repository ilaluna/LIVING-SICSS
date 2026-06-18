# LIVING-SICSS

## Step by step guide to run the script
In order to reproduce the analysis, researchers can run the scripts in the Living-SICSS repository in the following order:

0. download the project to ensure the right packages are used and get the data from https://www.leefbaarometer.nl/page/Opendata#score and the ODISSEI Safe Environment;
1. Script_Leefbarometer.R: this script explores the score variables from Leefbarometer and creates datasets that are used later for the creation of the Shiny app;
2. Script_LISS_datapreparation: this script extract the survey variables that match the livability score dimensions and provides insights to people's perception of livability;
3. Script_DataInnovationSpotter: this script explores the data about innovative industries and the impact to the territory;
4. Script_Modeling: this script train and test two dinstinct ML models to predict official livability scores. The first model uses "objective" environmental dimensions coming from the different registers, whereas the second model uses the survey data to predict the official scores;
5. app.R: this script creates a Shiny app that displays both the scores from the Leefbarometer and the results from our analysis.

## Data availability
the Leefbarometer data in openly available at https://www.leefbaarometer.nl/page/Opendata#score, whereas the other datasets are available in the SANE Secure Environment of ODISSEI. To access this data files contact info@odissei-data.nl.

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
- phisical environment;
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
The EXPOSOME data offers a wide variety of variables measuring environmental dimensions such as pollution, biodiversity and light intensity. We used the #### year ### wave ### version of the dataset. In the R script, we conducted a preprocessing step in order to have the variables in the correct form for the predictive models.


## FIRMBAKBONE data
This dataset, also accessible through SANE, covers a wide range of topics. In particular, we used ***** from ## year ## wave## and the InnovatieSpotter from ## year ## wave##, which covers topics about innovation in industries and environmental data. This data is linkable to PC4 geospatial level.
The Firmbackbone data has been preprocessed in R and particularly variables have been rescaled due to skeweness to then fit the predictive model.

## Models


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

