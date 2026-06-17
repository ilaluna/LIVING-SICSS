# LIVING-SICCS

## LISS data preparation 
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
