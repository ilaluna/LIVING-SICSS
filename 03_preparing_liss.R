# Library and packages ####
# Installing packages if necessary and loading them
if (!requireNamespace("renv", quietly = TRUE)) {
  install.packages("renv")}
library(renv)
renv::init(force = TRUE)

if (!requireNamespace("dplyr", quietly = TRUE)) {
  install.packages("dplyr")}
library(dplyr)

if (!requireNamespace("readr", quietly = TRUE)) {
  install.packages("readr")}
library(readr)

if (!requireNamespace("stringr", quietly = TRUE)) {
  install.packages("stringr")}
library(stringr)

# Loading and subsetting data ####
# social, housing, health, work - the core studies of LISS, all wave 18 as it's the latest data 
social <- read.csv2("S:/source/LISS/LISSCoreStudyWave12to218/SocialIntegrationAndLeisure/wave18/cs25r_EN_1.0p.csv")
names(social)
social <- social %>%
  select(ï..nomem_encr, cs25r005, cs25r006, cs25r010, cs25r011,
         cs25r101, cs25r100, cs25r497, cs25r098, cs25r099, cs25r499, cs25r569,
         cs25r572, cs25r570, cs25r571, cs25r494, cs25r495, cs25r517, cs25r093,
         cs25r094, cs25r568, cs25r516, cs25r496, 
         cs25r283, cs25r284, cs25r285, cs25r286, cs25r287, cs25r288, cs25r289,
         cs25r634, cs25r635, cs25r290, cs25r291
         )

housing <- read.csv2("S:/source/LISS/LISSCoreStudyWave12to218/Housing/wave18/cd25r_EN_1.0p.csv")
names(housing)
housing <- housing %>%
  select(ï..nomem_encr, cd25r092, cd25r003, cd25r097, cd25r102, cd25r038, cd25r041, cd25r042,
         cd25r043, cd25r044, cd25r045, cd25r046, cd25r047, cd25r048,
         cd25r210, cd25r034, cd25r049, cd25r050, cd25r051, cd25r052, cd25r053, cd25r090)

health <- read.csv2("S:/source/LISS/LISSCoreStudyWave12to218/Health/wave18/ch25r_EN_1.0p.csv")
names(health)
health <- health %>%
  select(ï..nomem_encr, ch25r301, ch25r304)
    
work <- read.csv2("S:/source/LISS/LISSCoreStudyWave12to218/WorkAndSchooling/wave18/cw25r_EN_1.0p.csv")
names(work)
work <- work %>%
  select(ï..nomem_encr, cw25r525)

#postcode data
ps6 <- read_csv("S:/source/LISS/LISS_PC6_2020-2026/PC6_LISS_2020-2026.csv")
names(ps6)
ps6 <- ps6 %>%
  rename(
    nomem = nomem_encr
  ) %>%
  select(nomem, jan2025, july2025)

# Cleaning data ####
## Renaming variables ####
# All variables have HOUS, AMEN, ENV, SAF, SOC in front of them to represent the dimensions
# of liveability scores: HOUS for Housing, AMEN for Amenities, ENV for Environment, 
# SOC for Social integration & Leisure.
health <- health %>%
  rename(
    nomem = ï..nomem_encr,
    HOUS_stress_housing = ch25r301,
    HOUS_stress_finances = ch25r304
  )

names(housing)
housing <- housing %>%
  rename(
    nomem = ï..nomem_encr,
    AMEN_vicinity_satisf = cd25r092, 
    HOUS_dweller_status = cd25r003,
    HOUS_rent_type = cd25r097,
    HOUS_owner_way = cd25r102,
    HOUS_dwelling_type = cd25r038, 
    HOUS_dwell_toosmall = cd25r041,
    HOUS_dwell_toolarge = cd25r042, 
    HOUS_dwell_toodark = cd25r043,
    HOUS_dwell_heatinadeq = cd25r044,
    HOUS_dwell_roofleak = cd25r045,
    HOUS_dwell_damp = cd25r046,
    HOUS_dwell_rotten = cd25r047,
    HOUS_dwell_noissues = cd25r048,
    HOUS_value_change = cd25r210,
    HOUS_rooms = cd25r034, 
    HOUS_noise_neighbours = cd25r049, 
    ENV_noise_streets = cd25r050, 
    ENV_dirt_streets = cd25r051, 
    SAF_crime = cd25r052, 
    HOUS_annoyance_noissues = cd25r053, 
    ENV_noise_airtraffic = cd25r090
  )

names(social)
social <- social %>%
  rename(
    nomem = ï..nomem_encr,
    AMEN_sports_partic = cs25r005,
    AMEN_sports_member = cs25r006,
    AMEN_leis_hob_partic = cs25r010,
    AMEN_leis_hob_member = cs25r011,
    AMEN_leis_museum = cs25r101,
    AMEN_leis_artgall= cs25r100, 
    AMEN_leis_library = cs25r497, 
    AMEN_leis_cinema = cs25r098,
    AMEN_leis_filmfest = cs25r099,
    AMEN_leis_foodfest = cs25r499, 
    AMEN_leis_fair = cs25r569, 
    AMEN_leis_sale = cs25r572,
    AMEN_leis_zoo = cs25r570, 
    AMEN_leis_themepark= cs25r571,
    AMEN_leis_theatre = cs25r494,
    AMEN_leis_cabaret = cs25r495,
    AMEN_leis_dance = cs25r517,
    AMEN_leis_classical = cs25r093,
    AMEN_leis_opera = cs25r094,
    AMEN_leis_musical = cs25r568,
    AMEN_leis_concert= cs25r516,
    AMEN_leis_musicfest= cs25r496,
    SOC_social_satisf = cs25r283,
    SOC_social_emptiness = cs25r284,
    SOC_people_count_on = cs25r285, 
    SOC_people_rely_on = cs25r286,
    SOC_people_connected = cs25r287, 
    SOC_miss_people = cs25r288, 
    SOC_feel_deserted = cs25r289, 
    SOC_family_day = cs25r634,
    SOC_neighbour_day = cs25r635,
    SOC_family_evening = cs25r290,
    SOC_neighbour_evening = cs25r291
  )

names(work)
work <- work %>%
  rename(
    nomem = ï..nomem_encr,
    SOC_occupation = cw25r525
  )

ps6$jan2025.ps4 <- str_remove(ps6$jan2025, " .{2}$")
ps6$jan2025.ps4.int <- as.integer(ps6$jan2025.ps4)
ps6$july2025.ps4 <- str_remove(ps6$july2025, " .{2}$")
ps6$july2025.ps4.int <- as.integer(ps6$july2025.ps4)

# Merging data ####
# the version of merged file that only has IDs that are present in all datasets
liveability.full <- health %>%
  inner_join(housing, by = "nomem") %>%
  inner_join(social, by = "nomem") %>%
  inner_join(work, by = "nomem")

# the version of merged file that has all IDs even if not present in some datasets
liveability.na <- health %>%
  full_join(housing, by = "nomem") %>%
  full_join(social, by = "nomem") %>%
  full_join(work, by = "nomem")

# merging with postcode data
liveability.full <- liveability.full %>%
  left_join(ps6, by = "nomem")

liveability.na <- liveability.na %>%
  left_join(ps6, by = "nomem")

# Recoding variables ####
## Occupation into fewer categories ####
unique(liveability.full$SOC_occupation)
# to reduce the number of categories, joined based on the broad categories of occupation
# 1 = paid employment
# 2 = works/assists family business
# 3 = freelancer/self-employed
# 4 = job seeker after job loss
# 5 = first-time job seeker
# 6 = exempted from job seeking after job loss
# 7 = education
# 8 = houskeepers
# 9 = pensioner
# 10 = work disability
# 11 = unpaid work - unemploynent benefit
# 12 = volunteer
# 13 = does something else
# 14 = too young

# 1 = 1, 2, 3 - employed
# 2 = 7, 14 - education
# 3 = 5 - graduate
# 4 = 9 pensioneer 
# 5 = 4, 6, 8, 10, 11, 12, 13 - unemployed

liveability.full <- liveability.full %>%
  mutate(
    SOC_occupation = recode(
      SOC_occupation,
      '1' = 1,
      '2' = 1,
      '3' = 1,
      '4' = 5,
      '5' = 3,
      '6' = 5,
      '7' = 2,
      '8' = 5,
      '9' = 4,
      '10' = 5,
      '11' = 5,
      '12' = 5,
      '13' = 5,
      '14' = 2
    )
  )

liveability.na <- liveability.na %>%
  mutate(
    SOC_occupation = recode(
      SOC_occupation,
      '1' = 1,
      '2' = 1,
      '3' = 1,
      '4' = 5,
      '5' = 3,
      '6' = 5,
      '7' = 2,
      '8' = 5,
      '9' = 4,
      '10' = 5,
      '11' = 5,
      '12' = 5,
      '13' = 5,
      '14' = 2
    )
  )

## Reverse-coding negatively phrased variables ####
# negatively phrased variables:
# binary:
# HOUS_stress_housing
# HOUS_stress_finances
# HOUS_dwell_toosmall
# HOUS_dwell_toolarge
# HOUS_dwell_toodark
# HOUS_dwell_heatinadeq
# HOUS_dwell_roofleak
# HOUS_dwell_damp
# HOUS_dwell_rotten
# HOUS_noise_neighbours
# ENV_noise_streets
# ENV_dirt_streets
# SAF_crime
# ENV_noise_airtraffic

names(liveability.full)
liveability.full <- liveability.full %>%
  mutate(
    across(c(HOUS_stress_housing,
             HOUS_stress_finances,
             HOUS_dwell_toosmall,
             HOUS_dwell_toolarge,
             HOUS_dwell_toodark,
             HOUS_dwell_heatinadeq,
             HOUS_dwell_roofleak,
             HOUS_dwell_damp,
             HOUS_dwell_rotten,
             HOUS_noise_neighbours,
             ENV_noise_streets,
             ENV_dirt_streets,
             SAF_crime,
             ENV_noise_airtraffic), ~ 1 - .x)
  )

head(liveability.full)

liveability.na <- liveability.na %>%
  mutate(
    across(c(HOUS_stress_housing,
             HOUS_stress_finances,
             HOUS_dwell_toosmall,
             HOUS_dwell_toolarge,
             HOUS_dwell_toodark,
             HOUS_dwell_heatinadeq,
             HOUS_dwell_roofleak,
             HOUS_dwell_damp,
             HOUS_dwell_rotten,
             HOUS_noise_neighbours,
             ENV_noise_streets,
             ENV_dirt_streets,
             SAF_crime,
             ENV_noise_airtraffic), ~ 1 - .x)
  )

## Recode NAs ####
# some of the variables have values -9 or -8 which were "don't know"/"not applicable" responses
liveability.na$HOUS_rent_type[liveability.na$HOUS_rent_type %in% c(-9, -8)] <- NA
liveability.na$HOUS_value_change[liveability.na$HOUS_value_change %in% c(-9, -8)] <- NA
liveability.na$AMEN_vicinity_satisf[liveability.na$AMEN_vicinity_satisf %in% c(-9, -8)] <- NA
liveability.na$SOC_social_satisf[liveability.na$SOC_social_satisf %in% c(-9, -8)] <- NA

# Aggregating data on PS4 level ####
liveability.ps4 <- liveability.na %>%
  group_by(jan2025.ps4.int) %>%
  summarise(
    across(
      c(HOUS_stress_housing, HOUS_stress_finances, AMEN_vicinity_satisf, HOUS_dwell_toosmall,
        HOUS_dwell_toolarge, HOUS_dwell_toodark, HOUS_dwell_heatinadeq, HOUS_dwell_roofleak,
        HOUS_dwell_damp, HOUS_dwell_rotten, HOUS_dwell_noissues, HOUS_rooms, HOUS_noise_neighbours,
        ENV_noise_streets, ENV_dirt_streets, SAF_crime, HOUS_annoyance_noissues, ENV_noise_airtraffic,
        AMEN_sports_partic, AMEN_sports_member, AMEN_leis_hob_partic, AMEN_leis_hob_member,
        AMEN_leis_museum, AMEN_leis_artgall, AMEN_leis_library, AMEN_leis_cinema, AMEN_leis_filmfest,
        AMEN_leis_foodfest, AMEN_leis_fair, AMEN_leis_sale, AMEN_leis_zoo, AMEN_leis_themepark,
        AMEN_leis_theatre, AMEN_leis_cabaret, AMEN_leis_dance, AMEN_leis_classical,
        AMEN_leis_opera, AMEN_leis_musical, AMEN_leis_concert, AMEN_leis_musicfest,
        SOC_social_satisf, SOC_social_emptiness, SOC_people_count_on, SOC_people_rely_on,
        SOC_people_connected, SOC_miss_people, SOC_feel_deserted, SOC_family_day,
        SOC_neighbour_day, SOC_family_evening, SOC_neighbour_evening),
      ~ mean(.x, na.rm = TRUE)
    ),
    HOUS_dweller_status = mode_fun(HOUS_dweller_status), #variables that are categorical
    HOUS_rent_type = mode_fun(HOUS_rent_type),           #most common variable in the ps4
    HOUS_owner_way = mode_fun(HOUS_owner_way),
    HOUS_dwelling_type = mode_fun(HOUS_dwelling_type),
    HOUS_value_change = mode_fun(HOUS_value_change),
    SOC_occupation = mode_fun(SOC_occupation),
    n = n()
  )

liveability.ps4 <- liveability.ps4 %>%
  mutate(
    across(where(is.numeric),
           ~ ifelse(is.nan(.x), NA, .x))
  ) #replace NaNs with NAs

liveability.ps4 <- liveability.ps4 %>%
  mutate(
    across(c(HOUS_dweller_status, HOUS_rent_type, HOUS_owner_way,
             HOUS_dwelling_type, HOUS_value_change, SOC_occupation),
           as.numeric)
  ) #convert variables from characters to numeric

write_csv2(liveability.ps4, "liveability.ps4.csv")