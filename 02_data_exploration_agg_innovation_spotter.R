## This file explores the innovatieSpotter section 
## of the FIRMBACKBONE data that was made available 
## for the SICCS-ODISSEI Summer School 2026

## InnovatieSpotter data origins from Q1 2026 and 
## is thus not completely representative for innovation and 
## economic prosperity in the Netherlands

## Nevertheless, since the companies in this dataset 
## do have a PC4 postcode attached, this dataset can inform about 
## some indicators of economic prosperity

## These are created ad hoc and explained in the script

## the saved aggregated dataset will be part of the 
## models that predict livability in the Netherlands 
## based on "objective" data rather than the 
## subjective experiences of e.g. the LISS panel participants

## loading packages
library(data.table)
library(tidyverse)
library(dplyr)
library(readr)
library(psych)
library(haven)
library(foreign)
library(here)
library(stringr)
library(readxl)
library(arrow)

########################################################################

## Examining InnovatieSpotter data
innovatieSpotter_file <- "S:/source/FIRMBACKBONE/innovatie_spotter_202602/part-00000-3add8cda-75a3-4baa-b21d-0272fd444994-c000.snappy.parquet"

## loading in .parquet file
innovatieSpotter_data <- read_parquet(innovatieSpotter_file) %>% 
  as.data.frame()

## inpsecting column names to get insight into content of data
colnames(innovatieSpotter_data)


## Ideas for indicators

# - employees per PC 4
# - FTE per PC4
# - PTE per PC4
# - counts of sustainability ("verantwoord")
# - count of most often "Duurzaamheidseconomiesystemen"
# - counts of gebouwfuncties
# - maximum milieucategory (count, mean)
# - count, mean of landuse
# - counts of branche of interest (what adds to livability?)
# 
# Strategy: check unique values, create lots of counts and sumamry statistics,
# extract relevant codes, make sure to save it in a way that one PC4 has 
# one row

## renaming columns
colnames(innovatieSpotter_data)[4:6] <- c(
  "number_FTE", "number_PTE", "number_employees")

## selecting relevant columns
innovation_data_relevant <- innovatieSpotter_data %>%
  dplyr::select(number_FTE, 
                number_PTE,
                number_employees,
                Duurzaamheidsclaims,
                Duurzaamheidsecosystemen,
                Gebouwfunctie,
                `Innovatie-ecosysteem sectoren`,
                Innovatiethema,
                `Maximale milieucategorie`,
                `Netto oppervlakte (ha)`,
                Postcode_4,
                `SBI Branche`,
                `SBI Klasse`) %>%
  rename("claims_sustainable" = Duurzaamheidsclaims,
         "ecosystem_sustainable" = Duurzaamheidsecosystemen,
         "function_building" = Gebouwfunctie,
         "sector_ecosystem" = `Innovatie-ecosysteem sectoren`,
         "topic_innovation" = Innovatiethema,
         "max_environmental_cat" = `Maximale milieucategorie`,
         "landuse" = `Netto oppervlakte (ha)`,
         "PC4" = Postcode_4,
         "branche_SBI" = `SBI Branche`,
         "class_SBI" = `SBI Klasse`)



## Data preprocessing

## factor columns
factor_cols <- c("claims_sustainable",
                 "ecosystem_sustainable",
                 "function_building",
                 "sector_ecosystem",
                 "topic_innovation",
                 "branche_SBI", 
                 "class_SBI")

## numeric columns
num_cols <- c("number_FTE", 
              "number_PTE",
              "number_employees",
              "max_environmental_cat",
              "landuse")

## checking unique values of categorical columns
for(col in 1:ncol(innovation_data_relevant)){
  if(colnames(innovation_data_relevant)[col] %in% factor_cols){
    cat("unique values for column ", colnames(innovation_data_relevant)[col], 
        ": ", length(unique(innovation_data_relevant[, col])), "\n\n")
  }
}

## Topics that seem to come back often are "responsiblity", 
## "zero-emissions", "fairtrade", "sustainable development goals" and 
## "social"

## counting how often companies in a specific area use these keywords
## might serve as an indicator of innovation, economic responsiblity 
## and thus a liable economic prosperous area


##  What companies have what buildings and from which 
## economic branche do they come from?
unique(innovation_data_relevant$function_building)
unique(innovation_data_relevant$branche_SBI)



# Creating per postcode aggregated variables that encode economic prosperity / 
#   innovation / desirable economic activity

innovation_data_relevant <- innovation_data_relevant %>%
  ## coding indicator for un-desirable, neutral and desirable economic 
  ## activity
  ## assigning -1, 0 or +1 indicating whether this specific 
  ## economic area would be desirable 
  ## in your living environment
  mutate(branche_livable = ifelse(
    branche_SBI %in% c(
      "F: Bouwnijverheid",
      "C: Industrie",
      "H: Vervoer en opslag", 
      "E: Winning en distributie van water; afval- en afvalwaterbeheer en sanering",
      "D: Productie en distributie van en handel in elektriciteit, gas, stoom en gekoelde lucht",
      "A: Landbouw, bosbouw en visserij",
      "B: Winning van delfstoffen"), 
    -1, ifelse(branche_SBI %in% c(
      "G: Groot- en detailhandel",
      "N: Wetenschappelijke en technische activiteiten en specialistische zakelijke dienstverlening",
      "M: Exploitatie van en handel in onroerend goed", 
      "J: Activiteiten van uitgeverijen, omroepactiviteiten, en activiteiten op het gebied van productie en distributie van inhoud", 
      "P: Openbaar bestuur, overheidsdiensten en verplichte sociale verzekeringen",
      "V: Activiteiten van extraterritoriale organisaties en instanties"),
      0, ifelse(branche_SBI %in% c(
        "T: Overige dienstverlening",
        "O: Verhuur van roerende goederen en overige zakelijke dienstverlening",
        "I: Logies-, maaltijd- en drankverstrekking",
        "K: Telecommunicatie, computerprogrammering en consultancy, informatica-infrastructuur en overige activiteiten op het gebied van informatiediensten",
        "Q: Onderwijs" ,
        "R: Gezondheids- en welzijnszorg",
        "S: Kunst, cultuur, sport en recreatie activiteiten",
        "U: Activiteiten van huishoudens als werkgever en niet-gedifferentieerde productie van goederen en diensten door huishoudens voor eigen gebruik"),
        1, NA))
  ),
  across(all_of(factor_cols), as.factor), ## recoding factor columns
  across(all_of(num_cols), as.numeric), ## recoding numeric columns
  
  ## in the variable max_environmental_cat that informs on maximum pollution
  ## allowed, NA is re-coded as 0 since this means that for this 
  ## company, there is no pollution category expected
  max_environmental_cat = ifelse(is.na(max_environmental_cat), 0, 
                                 max_environmental_cat)
  )



## To bring data to same scale as livability scores:
## Aggregate variables of interest to PC4 level

## creating further count indicators based on company descriptions, 
## claims, the types of buildings, the branche, 
## the number of jobs and employees 
## and land use

## calculating aggregated variables on PC4 level, these will be 
## exported and used for ML training

innovation_data_pc4_agg <- innovation_data_relevant %>%
  group_by(PC4) %>%
  summarize(
    ## economic indicators, number of employees and jobs
    sum_FTE = sum(number_FTE, na.rm = TRUE),
    sum_PTE = sum(number_PTE, na.rm = TRUE),
    sum_employees = sum(number_employees, na.rm = TRUE),
    ## how often do indicators of social responsibility appear in companies'
    ## descriptions?
    count_responsible_claim = sum(
      str_count(claims_sustainable, "Verantwoord"), na.rm = TRUE),
    count_sus_dev_goal_claim = sum(
      str_count(claims_sustainable, "Sustainable Development Goal"),
      na.rm = TRUE),
    count_fairtrade = sum(str_count(claims_sustainable, "Fairtrade"),
                          na.rm = TRUE),
    count_social_goal = sum(str_count(claims_sustainable, "Social"),
                            na.rm = TRUE),
    ## how often do specific keywords of sustainability occur in the 
    ## description of the ecosystem?
    count_zero_emission_license = sum(
      str_count(ecosystem_sustainable, "zero-emissie"), na.rm = TRUE),
    ## environmental category: how much pollution is caused by companies 
    ## in this area
    sum_environmental_cat = sum(max_environmental_cat, na.rm = TRUE),
    mean_environmental_cat = mean(max_environmental_cat, na.rm = TRUE),
    ## landuse of companies
    sum_landuse = sum(landuse, na.rm = TRUE),
    ## how much buildings of what function occur per postcode?
    count_live_building = sum(function_building == "woonfunctie", na.rm = TRUE),
    count_industry_building = sum(
      function_building == "industriefunctie", na.rm = TRUE),
    count_retail_building = sum(
      function_building == "winkelfunctie", na.rm = TRUE),
    count_office_building = sum(
      function_building == "kantoorfunctie", na.rm = TRUE),
    count_meeting_building = sum(
      function_building == "bijeenkomstfunctie", na.rm = TRUE),
    count_healthcare_building = sum(
      function_building == "gezondheidszorgfunctie", na.rm = TRUE),
    count_education_building = sum(
      function_building == "onderwijsfunctie", na.rm = TRUE),
    count_sport_building = sum(
      function_building == "sportfunctie", na.rm = TRUE),
    ## are the companies in this area desirable in the sense of 
    ## livability?
    count_neg_branche = sum(branche_livable == - 1, na.rm = TRUE),
    count_pos_branche = sum(branche_livable == 1, na.rm = TRUE),
    mean_livability_branche = mean(branche_livable, na.rm = TRUE)
  )


## log-transform strongly skewed columns (sum columns)
log_transf_cols <- c("sum_FTE", "sum_PTE", "sum_employees", "sum_landuse")

innovation_data_pc4_agg <- innovation_data_pc4_agg %>%
  mutate(across(all_of(log_transf_cols), log1p))



## saving results
write.csv(innovation_data_pc4_agg,
          here::here("data", "FIRMBACKBONE_innovation",
                     "aggregates_innovatie_spotter.csv"))

## eoF