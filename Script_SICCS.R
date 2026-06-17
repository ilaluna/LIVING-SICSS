### Set working directory

setwd("C:/Users/lunardel/Downloads")

### Install renv (if not already available)
if (!requireNamespace("renv", quietly = TRUE)) {
    install.packages("renv")}
# load renv()
library(renv)
# activate environment
renv::init()

### Install packages if not already installed
if (!requireNamespace("sf", quietly = TRUE)) {
  install.packages("sf")
}
if (!requireNamespace("dplyr", quietly = TRUE)) {
  install.packages("dplyr")
}
if (!requireNamespace("ggplot2", quietly = TRUE)) {
  install.packages("ggplot2")
}

# Load packages
library(sf)
library(dplyr)
library(ggplot2)

# Record the exact package versions
renv::snapshot()

### Read the data

# write path to data
path <- "data/geometrie-lbm3-2024/PC4 2024.gpkg"

# get layers
layers <- st_read(path)

# read the score file, we can derive the scores from year 2002 to 2024
scores <- read.csv("data2/Leefbaarometer 3.0 - Meting 2024 - open data/Leefbaarometer-scores PC4 2002-2024.csv")

# read the development file, we can derive the difference in scores across years
development <- read.csv("data2/Leefbaarometer 3.0 - Meting 2024 - open data/Leefbaarometer-ontwikkeling PC4 2002-2024.csv")

#########################
## Data cleaning

scores_2024 <- scores[scores$jaar == 2024,]

#########################
## Exploration of different scores

# lbm is the total score (each score component has different weight)
summary(scores_2024$lbm)
hist(scores_2024$lbm)

# afw is the score difference from the nation average score
summary(scores_2024$afw)
hist(scores_2024$afw)

# fys stands for physiscal environment 
summary(scores_2024$fys)
hist(scores_2024$fys)

# onv stands for nuisance and insecurity
summary(scores_2024$onv)
hist(scores_2024$onv)

# soc stands for social cohesion
summary(scores_2024$soc)
hist(scores_2024$soc)

# vrz stands for amenities
summary(scores_2024$vrz)
hist(scores_2024$vrz)

# won stands for housing stock
summary(scores_2024$won)
hist(scores_2024$won)



#####################

### Merge livability scores with PC4 data

nrow(scores_2024) #4056 observations
nrow(layers) #4071 observations

# there is a 15 observations difference between the two datafiles

# lets see which PC4 areas are not scored
layers$PC4 <- as.numeric(layers$PC4) # change to numeric variable to match PC4 in scores_2024

PC4_codes <- layers %>% left_join(scores_2024, by = "PC4") # merge the datasets

missing_codes <- PC4_codes[is.na(PC4_codes$lbm),]$PC4 # codes of PC4 that are not scored
missing_codes_gemeente <- PC4_codes[is.na(PC4_codes$lbm),]$gm_naam #gemeente of PC4 that are missing scores

########################################################
## Rescale scores to 1-100

# they all have same direction
PC4_codes <- PC4_codes %>%
  mutate(lbm = 1 + (lbm - min(lbm, na.rm = TRUE)) /
           (max(lbm, na.rm = TRUE) - min(lbm, na.rm = TRUE)) * 99, #lbm
         afw = 1 + (afw - min(afw, na.rm = TRUE)) /
           (max(afw, na.rm = TRUE) - min(afw, na.rm = TRUE)) * 99, #afw
         fys = 1 + (fys - min(fys, na.rm = TRUE)) /
           (max(fys, na.rm = TRUE) - min(fys, na.rm = TRUE)) * 99, #fys
         onv = 1 + (onv - min(onv, na.rm = TRUE)) /
           (max(onv, na.rm = TRUE) - min(onv, na.rm = TRUE)) * 99, #onv
         soc = 1 + (soc - min(soc, na.rm = TRUE)) /
           (max(soc, na.rm = TRUE) - min(soc, na.rm = TRUE)) * 99, #soc
         vrz = 1 + (vrz - min(vrz, na.rm = TRUE)) /
           (max(vrz, na.rm = TRUE) - min(vrz, na.rm = TRUE)) * 99, #vrz
         won = 1 + (won - min(won, na.rm = TRUE)) /
           (max(won, na.rm = TRUE) - min(won, na.rm = TRUE)) * 99) #won


#######################################################

## Plot score maps

# lbm (final score)
ggplot(PC4_codes) +
  geom_sf(aes(fill = lbm)) +
  scale_fill_viridis_c(option = "C") +
  theme_minimal()

# afw (difference from national mean)
ggplot(PC4_codes) +
  geom_sf(aes(fill = afw)) +
  scale_fill_viridis_c(option = "C") +
  theme_minimal()

#fys (physical environment)
ggplot(PC4_codes) +
  geom_sf(aes(fill = fys)) +
  scale_fill_viridis_c(option = "C") +
  theme_minimal()

#onv (nuisance and insecurity)
ggplot(PC4_codes) +
  geom_sf(aes(fill = onv)) +
  scale_fill_viridis_c(option = "C") +
  theme_minimal()

#soc (social cohesion)
ggplot(PC4_codes) +
  geom_sf(aes(fill = soc)) +
  scale_fill_viridis_c(option = "C") +
  theme_minimal()

#vrz (amenities)
ggplot(PC4_codes) +
  geom_sf(aes(fill = vrz)) +
  scale_fill_viridis_c(option = "C") +
  theme_minimal()

#won (housing stock)
ggplot(PC4_codes) +
  geom_sf(aes(fill = won)) +
  scale_fill_viridis_c(option = "C") +
  theme_minimal()


####################################

# get municipality geometry from grouping pc4
PC4_codes2 <- st_make_valid(PC4_codes)
PC4_codes2 <- st_buffer(PC4_codes2, 0)
muni_sf <- PC4_codes2 %>%
  st_make_valid() %>%
  group_by(gm_naam) %>%
  summarise(geometry = st_union(geom), .groups = "drop")

# trim names, in order to have consistent names 
PC4_codes$gm_naam <- trimws(as.character(PC4_codes$gm_naam))
muni_sf$gm_naam   <- trimws(as.character(muni_sf$gm_naam))

# change to Leaflet standard
muni_sf   <- st_transform(muni_sf, 4326)

