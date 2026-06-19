## This script carries out preprocessing 
## on all sub-datasets that constitute 
## "objective" and "subjective" indicators of livability

## objective data are extracted aggregated FIRMBACKBONE / 
## innovatieSpotter data, EXPOSOME data on environmental influences 
## and exposures made available for the SICCS-ODISSEI summer school
## and administrative-demographic data taht were part of the 
## CBS-edited PC6- data of the Netherlands from 2024

## Subjective data are relevant variables from the LISS panel data
## from 2024 that inform about respondent's perceived living
## situation. These were aggregated on the level of the Postcode (PC4)
## where respondents live so no initials can be traced back

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
library(caret)
library(doParallel)

##############################################################################


# Step 1 - Loading the different datasets and doing some final preprocessing 
# (e.g column names alignment, re-coding, deleting cases), this will be done 
# separately for
# - LISS data
# - EXPOSOME data
# - FIRMBACKBONE_innovationSpotter data
# - original livability scores (with the outcome for ML, the
# "livability" scores)


## 1.0 Preparation steps

## alignment of merging variable name
pc4_name <- "pc4"


## 1.1 LISS data preprocessing
LISS_data <- fread(here::here(
  "data", "liss_data", "liveability_ps4.csv")) %>%
  as.data.frame()

## categorical columns
cat_cols_LISS <- c("HOUS_dweller_status",
                   "HOUS_rent_type",
                   "HOUS_owner_way",
                   "HOUS_dwelling_type",
                   "HOUS_value_change",
                   "SOC_occupation")

colnames(LISS_data)[colnames(LISS_data) == "jan2025.ps4.int"] <- pc4_name

## coding categorical variables as factor
LISS_data <- LISS_data %>%
  mutate(across(all_of(cat_cols_LISS), as.factor))

## descriptive check
LISS_data %>% 
  dplyr::select(-pc4) %>%
  dplyr::select(where(is.numeric)) %>%
  psych::describe()

## normalize numeric variables
LISS_normalize <- preProcess(LISS_data[, -1] %>% 
                               dplyr::select(where(is.numeric)),
                             method = c("center", "scale"))

LISS_num_processed <- predict(LISS_normalize, 
                              LISS_data[, -1] %>% 
                                dplyr::select(where(is.numeric)))

## one-hot encode categorical variables
dummy <- dummyVars("~.", data = LISS_data[, cat_cols_LISS])

df_cat <- data.frame(predict(dummy, newdata = LISS_data[, cat_cols_LISS]))

## preprocessed dataset
LISS_data_prepared <- cbind(LISS_data %>% 
                              dplyr::select(pc4), LISS_num_processed, df_cat)


LISS_data_prepared$pc4 <- as.character(LISS_data_prepared$pc4)

## saving column names of variables for later subsampling
LISS_cols <- grep("pc4", colnames(LISS_data_prepared),
                  invert = TRUE, value = TRUE)

## LISS_data is now prepared


#############################################################################

## 1.2 administrative / demographic / infrastructure data from CBS data
## on PC6 (PC6_poly data)

PC4_admin_data <- fread(here::here(
  "data", "exposome_pc4_aggregated", "pc4_demo_infr.csv")) %>%
  as.data.frame()

## checking for completeness in the demographic data, 
## during data extraction, many missings were reported
vars_all_na <- colMeans(is.na(PC4_admin_data)) %>%
  as.data.frame() %>%
  dplyr::rename("prop_na" = 1) %>%
  filter(prop_na == 1) %>%
  rownames_to_column("var_name") %>% 
  dplyr::select(var_name) %>%
  pull()
## we see that a lot of these variables have only missing values,
## all of these will be removed 

PC4_admin_data <- PC4_admin_data %>%
  dplyr::select(-all_of(vars_all_na))

## all variables starting with "aantal" are count variables,
## log transform these, normalize the other ones
count_cols_admin <- grep("^aantal", colnames(PC4_admin_data), value = TRUE)

## first normalize numeric columns 
num_cols_admin <- setdiff(colnames(PC4_admin_data),
                          c("pc4", count_cols_admin))


PC4_admin_normalize <- preProcess(PC4_admin_data[, num_cols_admin],
                                  method = c("center", "scale"))

PC4_admin_num_processed <- predict(PC4_admin_normalize,
                                   PC4_admin_data[, num_cols_admin])

PC4_admin_processed <- cbind(PC4_admin_data %>% 
                               dplyr::select(pc4, all_of(count_cols_admin)),
                             PC4_admin_num_processed)


## log transforming count columns
PC4_admin_processed <- PC4_admin_processed %>%
  mutate(across(all_of(count_cols_admin), log1p))


PC4_admin_processed$pc4 <- as.character(PC4_admin_processed$pc4)
## preprocessing finished

## saving column names of variables for later subsampling
PC4_admin_cols <- grep("^pc4", colnames(PC4_admin_processed),
                       invert = TRUE, value = TRUE)


##############################################################################

## 1.3 EXPOSOME data (multiple aggregated files, were created in python
## notebook 03_geo_analysis_exposome_liv.ipynb)


## define exposome files: All that end on PC4
pc4_files_exposome <- 
  paste0(here::here("data", "exposome_pc4_aggregated"), "/", 
         grep("PC4.csv$",
              list.files(here::here("data", "exposome_pc4_aggregated")),
              value = TRUE))

pc4_exposome_all <- data.frame()


## load all files in, merge on pc4
for(exposome_file in 1:length(pc4_files_exposome)){
  data <- fread(pc4_files_exposome[exposome_file])
  if(exposome_file == 1){
    pc4_exposome_all <- rbind(pc4_exposome_all, data)
  } else {
    pc4_exposome_all <- full_join(pc4_exposome_all, data, by = c("pc4"))
  }
}

## MVI and NDV data need to be removed, aggregation did not work
pc4_exposome_all <- pc4_exposome_all %>%
  dplyr::select(-starts_with("MVI"), -starts_with("NDV"))


## descriptive check
pc4_exposome_all %>% 
  dplyr::select(-pc4) %>%
  dplyr::select(where(is.numeric)) %>%
  psych::describe()

## also here, strongly skewed columns, all will be normalized
pc4_exposome_normalize <- preProcess(pc4_exposome_all[, -1],
                                     method = c("center", "scale"))

pc4_exposome_processed <- predict(pc4_exposome_normalize,
                                  pc4_exposome_all[, -1])

pc4_exposome_processed <- cbind(pc4_exposome_all %>% 
                                  dplyr::select(pc4),
                                pc4_exposome_processed)


pc4_exposome_processed$pc4 <- as.character(pc4_exposome_processed$pc4)
## preprocessing finished


## saving column names of variables for later subsampling
pc4_exposome_cols <- grep("^pc4", colnames(pc4_exposome_processed),
                          invert = TRUE, value = TRUE)


#############################################################################

## 1.4 FIRMBACKBONE innovatieSpotter data (aggregated)

pc4_innovation_data <- fread(here::here(
  "data", "FIRMBACKBONE_innovation", "aggregates_innovatie_spotter.csv"))[, -1]  %>%
  as.data.frame()

colnames(pc4_innovation_data)[1] <- pc4_name

## all variables are either preprocessed counts (log-preprocessed in 
## script 02_data_exploration_innovation_spotter.R) or 
## means, no further preprocessing needed


pc4_innovation_data$pc4 <- as.character(pc4_innovation_data$pc4)

## saving column names of variables for later subsampling
pc4_innovation_cols <- grep("^pc4", colnames(pc4_innovation_data),
                            invert = TRUE, value = TRUE)


#############################################################################

## 1.5 loading in the "official" livability scores from OM
# (re-scaled from 0-100), these will be the outcome in the machine learning
## models

liv_scores_2024 <- fread(file = here::here(
  "data", "liv_2024", "liv_scores_transformed_pc4.csv"))[, -1] %>%
  dplyr::select(-jaar, -afw, -fys, -onv, -soc, -vrz, -won, 
                -gm_naam)
## remove scoring dimensions, these were used to construct the 
## official scores

colnames(liv_scores_2024)[1] <- pc4_name

liv_scores_2024$pc4 <- as.character(liv_scores_2024$pc4)

#############################################################################
#############################################################################


## Step 2: Merging datasets and create sub datasets for the ML models
# Train-test split (80 / 20) also done here

## "Objective dataset": EXPOSOME, FIRMBACKBONE and demographic data
data_objective_full <- liv_scores_2024 %>%
  left_join(PC4_admin_processed, by = c("pc4")) %>%
  left_join(pc4_exposome_processed, by = c("pc4")) %>%
  left_join(pc4_innovation_data, by = c("pc4")) %>%
  as.data.frame()

dim(data_objective_full)
## 70 features, ~ 4,056 scored postcodes

colMeans(is.na(data_objective_full)) %>% as.data.frame()
## missings occur, median imputation will be applied prior to training



## splitting into train and test set, respect the distribution so that 
## both high and low values are equally represented in train and test data
## setting seed for reproducibility
set.seed(2026)

indices_obj <- createDataPartition(data_objective_full$lbm, p = 0.8,
                                   list = FALSE)

train_obj <- data_objective_full[indices_obj, ]
test_obj <- data_objective_full[-indices_obj, ]

###############################################################################

## "Subjective dataset": Lived experiences of LISS panel respondents that 
## live in PC areas
data_subjective_full <- LISS_data_prepared %>%
  left_join(liv_scores_2024, by = c("pc4")) %>% 
  filter(!is.na(lbm)) %>%
  as.data.frame()

dim(data_subjective_full)
## 82 features, ~ 1,900 scored postcodes

colMeans(is.na(data_subjective_full)) %>% as.data.frame()
## missings are in there, median imputation will be applied prior to training


## splitting into train and test set, respect the distribution so that 
## both high and low values are equally represented in the data

## setting seed for reproducibility
set.seed(2026)

indices_subj <- createDataPartition(data_subjective_full$lbm, p = 0.8,
                                    list = FALSE)

train_subj <- data_subjective_full[indices_subj, ]
test_subj <- data_subjective_full[-indices_subj, ]


#############################################################################
#############################################################################

## Step 3: ML preprocessing:
# - near-zero variance removal
# - check for highly correlated columns 
# - imputation (median)

## Objective data

## removing low variance variables (common practice in ML)
nzv_obj <- nearZeroVar(train_obj)

train_obj <- train_obj[, -nzv_obj]

## removing highly correlated variables
high_cor_obj <- findCorrelation(
  cor(train_obj[, -1], use = "pairwise.complete.obs"),
  cutoff = .95) + 1

train_obj <- train_obj[, -high_cor_obj]

## median imputation on training and test data to be able 
## to run model and to create output
pre <- preProcess(train_obj, "medianImpute")
train_obj <- predict(pre, train_obj)
test_obj <- predict(pre, test_obj)

#############################################################################

## Subjective data (LISS)

## removing variables with low variance
nzv_subj <- nearZeroVar(train_subj)
nzv_subj

train_subj <- train_subj[, -nzv_subj]


## finding highly correlated variables and removing them
high_cor_subj <- findCorrelation(
  cor(train_subj[, -1], use = "pairwise.complete.obs"),
  cutoff = .95) + 1

train_subj <- train_subj[, -high_cor_subj]

## median imputation on training and test data to be able 
## to run model and to create output
pre_subj <- preProcess(train_subj, "medianImpute")
train_subj <- predict(pre_subj, train_subj)
test_subj <- predict(pre_subj, test_subj)

#############################################################################
#############################################################################


## Step 4: Training ML models 

### 4.1 Elastic net (less flexible)
# Regularized regression technique that can be used to deal with problems of 
# multicollinearity and overfitting thus advisable for high-dimensional datasets
# (Tay et al., 2023, Nogueira et al., 2018)

# linear regression algorithm that adds two penalty terms to least-squares
# objective function (L1 and L2 norm of coefficient vector multiplied by
# hyperparameters lambda and alpha)
# L1: feature selection
# L2: feature shrinkage

## Hyperparameters tuned: 

# lambda: regularization parameter 
# (when > 0, elastic net penalty kicks in, we shrink parameters)

# alpha: mixing parameter between L1 and L2 norms (penalty)
cv_ctrl <- trainControl(method = "cv", number = 5, allowParallel = TRUE)

## 1) Elastic net tuning parameters: penalty and mixing parameter
grid_elastic_net <- expand.grid(alpha = seq(0, 1, by = 0.1),
                                lambda = 10^seq(-4, 1, length.out = 30))


## a) Objective data: Training the model

## setting up parallelization
cl <- makePSOCKcluster(detectCores() - 2)
registerDoParallel(cl)

## train model: lbm is the livability score
elastic_net_obj <- train(
  lbm ~ .,
  data = train_obj[, -1],
  method = "glmnet",
  tuneGrid = grid_elastic_net,
  trControl = cv_ctrl
)

stopCluster(cl)
registerDoSEQ()


## b) Subjective data

cl <- makePSOCKcluster(detectCores() - 2)
registerDoParallel(cl)

elastic_net_subj <- train(
  lbm ~ .,
  data = train_subj[, -1],
  method = "glmnet",
  tuneGrid = grid_elastic_net,
  trControl = cv_ctrl
)

stopCluster(cl)
registerDoSEQ()

## With 14 cores, both models taked less than 1 minute to run!

##############################################################################

### 4.2 random forest (more flexible, decision-tree based, 
## can also accomodate non-linearities)

## Hyperparameters tuned :

# -	mtry: number of features that are available to be considered at each split. 
# -	min.node.size: Minimum number of samples required to split a node 
# - Splitrule (more variance or extratrees)

cv_ctrl <- trainControl(method = "cv", number = 5, allowParallel = TRUE)

## 2) Random Forest using the ranger package
grid_ranger <- expand.grid(mtry = c(2, 6, 10, 15, 20, 30, 45),
                           splitrule = c("variance", "extratrees"),
                           min.node.size = c(1, 5, 10))


## training the model

## a) Objective data

cl <- makePSOCKcluster(detectCores() - 2)
registerDoParallel(cl)

rf_obj <- train(
  lbm ~ .,
  data = train_obj[, -1],
  method = "ranger",
  tuneGrid = grid_ranger,
  trControl = cv_ctrl,
  num.trees = 500
)

stopCluster(cl)
registerDoSEQ()


## b) Subjective data

cl <- makePSOCKcluster(detectCores() - 2)
registerDoParallel(cl)

rf_subj <- train(
  lbm ~ .,
  data = train_subj[, -1],
  method = "ranger",
  tuneGrid = grid_ranger,
  trControl = cv_ctrl,
  num.trees = 500
)

stopCluster(cl)
registerDoSEQ()

#############################################################################
#############################################################################

## Step 5: Calculating predictions for training and test set and saving them

### 5.1 Predictions from the elastic net models

## Objective data - Elastic net
predictions_train_obj_enet <- as.numeric(
  predict(elastic_net_obj, newdata = train_obj))

predictions_test_obj_enet <- as.numeric(
  predict(elastic_net_obj, newdata = test_obj))

pc4_pred_obj_enet <- data.frame(
  pc4 = c(train_obj$pc4, test_obj$pc4),
  prediction_enet_obj = c(predictions_train_obj_enet,
                          predictions_test_obj_enet),
  diff = c((train_obj$lbm - predictions_train_obj_enet),
           (test_obj$lbm - predictions_test_obj_enet))
)

write.csv(pc4_pred_obj_enet, 
          file = here::here("data", "predictions_models", "objective",
                            "predictions_enet_objective_data_pc4.csv"))

write.csv(pc4_pred_obj_enet, 
          file = "../results/download_LIVING/predictions_models/predictions_enet_objective_data_pc4.csv")

############################################################################

## Subjective data - elastic net
predictions_train_subj_enet <- as.numeric(
  predict(elastic_net_subj, newdata = train_subj))

predictions_test_subj_enet <- as.numeric(
  predict(elastic_net_subj, newdata = test_subj))

pc4_pred_subj_enet <- data.frame(
  pc4 = c(train_subj$pc4, test_subj$pc4),
  prediction_enet_subj = c(predictions_train_subj_enet,
                           predictions_test_subj_enet),
  diff = c((train_subj$lbm - predictions_train_subj_enet),
           (test_subj$lbm - predictions_test_subj_enet))
)

write.csv(pc4_pred_subj_enet, 
          file = here::here("data", "predictions_models", "subjective",
                            "predictions_enet_subjective_data_pc4.csv"))

write.csv(pc4_pred_subj_enet, 
          file = "../results/download_LIVING/predictions_models/predictions_enet_subjective_data_pc4.csv")


############################################################################

### 5.2 predictions from the random forest models

## Objective data - random forest
predictions_train_obj_rf <- as.numeric(
  predict(rf_obj, newdata = train_obj))

predictions_test_obj_rf <- as.numeric(
  predict(rf_obj, newdata = test_obj))

pc4_pred_obj_rf <- data.frame(
  pc4 = c(train_obj$pc4, test_obj$pc4),
  prediction_rf_obj = c(predictions_train_obj_rf,
                        predictions_test_obj_rf),
  diff = c((train_obj$lbm - predictions_train_obj_rf),
           (test_obj$lbm - predictions_test_obj_rf))
)

write.csv(pc4_pred_obj_rf, 
          file = here::here("data", "predictions_models", "objective",
                            "predictions_rf_objective_data_pc4.csv"))

write.csv(pc4_pred_obj_rf, 
          file = "../results/download_LIVING/predictions_models/predictions_rf_objective_data_pc4.csv")

############################################################################

## Subjective data - elastic net
predictions_train_subj_rf <- as.numeric(
  predict(rf_subj, newdata = train_subj))

predictions_test_subj_rf <- as.numeric(
  predict(rf_subj, newdata = test_subj))

pc4_pred_subj_rf <- data.frame(
  pc4 = c(train_subj$pc4, test_subj$pc4),
  prediction_rf_subj = c(predictions_train_subj_rf,
                         predictions_test_subj_rf),
  diff = c((train_subj$lbm - predictions_train_subj_rf),
           (test_subj$lbm - predictions_test_subj_rf))
)

write.csv(pc4_pred_subj_rf, 
          file = here::here("data", "predictions_models", "subjective",
                            "predictions_rf_subjective_data_pc4.csv"))

write.csv(pc4_pred_subj_rf, 
          file = "../results/download_LIVING/predictions_models/predictions_rf_subjective_data_pc4.csv")

#############################################################################
#############################################################################


## Step 6: Extract and report the best hypertuning parameters

elastic_net_obj$bestTune
## alpha = 0.4, lambda = 0.08531679
elastic_net_subj$bestTune
## alpha = 0.2, lambda = 0.6210169

rf_obj$bestTune
## mtry = 30, splitrule = "variance", min.node.side = 1
rf_subj$bestTune
## mtry = 10, splitrule = "variance", min.node.size = 10

#############################################################################
#############################################################################

## Step 7: Evaluate model: Performance measures (RMSE and MAE) and comparison

## calculate RMSE and MAE for all models 

## 1) Objective data

## A) Elastic Net model

## train data
RMSE_enet_obj_train <- RMSE(predictions_train_obj_enet, train_obj$lbm)

MAE_enet_obj_train <- mean(abs(predictions_train_obj_enet - train_obj$lbm))


## test data
RMSE_enet_obj_test <- RMSE(predictions_test_obj_enet, test_obj$lbm)

MAE_enet_obj_test <- mean(abs(predictions_test_obj_enet - test_obj$lbm))


## B) Random Forest model

## train data
RMSE_rf_obj_train <- RMSE(predictions_train_obj_rf, train_obj$lbm)

MAE_rf_obj_train <- mean(abs(predictions_train_obj_rf - train_obj$lbm))

## test data
RMSE_rf_obj_test <- RMSE(predictions_test_obj_rf, test_obj$lbm)

MAE_rf_obj_test <- mean(abs(predictions_test_obj_rf - test_obj$lbm))


## 2) Subjective data

## A) Elastic Net model

## train data
RMSE_enet_subj_train <- RMSE(predictions_train_subj_enet, train_subj$lbm)

MAE_enet_subj_train <- mean(abs(predictions_train_subj_enet - train_subj$lbm))


## test data
RMSE_enet_subj_test <- RMSE(predictions_test_subj_enet, test_subj$lbm)

MAE_enet_subj_test <- mean(abs(predictions_test_subj_enet - test_subj$lbm))


## B) Random Forest model

## train data
RMSE_rf_subj_train <- RMSE(predictions_train_subj_rf, train_subj$lbm)

MAE_rf_subj_train <- mean(abs(predictions_train_subj_rf - train_subj$lbm))

## test data
RMSE_rf_subj_test <- RMSE(predictions_test_subj_rf, test_subj$lbm)

MAE_rf_subj_test <- mean(abs(predictions_test_subj_rf - test_subj$lbm))



#############################################################################
#############################################################################


#### Step 8: Visualization of model performances


## RMSE
RMSE_df <- data.frame(
  RMSE = c(RMSE_enet_obj_train, RMSE_enet_obj_test,
           RMSE_rf_obj_train, RMSE_rf_obj_test,
           RMSE_enet_subj_train, RMSE_enet_subj_test,
           RMSE_rf_subj_train, RMSE_rf_subj_test),
  Variables = c(rep("Objective \n(EXPOSOME + Admin + Innovation)", 4),
                rep("Subjective \n(LISS)", 4)),
  Model = c(rep("Elastic Net", 2),
            rep("Random Forest", 2),
            rep("Elastic Net", 2),
            rep("Random Forest", 2)),
  Set = rep(c("Train", "Test"), 4)
) %>%
  mutate(across(all_of(c("Variables", "Model", "Set")), as.factor))

RMSE_df$Variables <- factor(RMSE_df$Variables)
RMSE_df$Model <- factor(RMSE_df$Model)
RMSE_df$Set <- factor(RMSE_df$Set)

## MAE
MAE_df <- data.frame(
  MAE = c(MAE_enet_obj_train, MAE_enet_obj_test,
          MAE_rf_obj_train, MAE_rf_obj_test,
          MAE_enet_subj_train, MAE_enet_subj_test,
          MAE_rf_subj_train, MAE_rf_subj_test),
  Variables = c(rep("Objective \n(EXPOSOME + Admin + Innovation)", 4),
                rep("Subjective \n(LISS)", 4)),
  Model = c(rep("Elastic Net", 2),
            rep("Random Forest", 2),
            rep("Elastic Net", 2),
            rep("Random Forest", 2)),
  Set = rep(c("Train", "Test"), 4)
) %>%
  mutate(across(all_of(c("Variables", "Model", "Set")), as.factor))

MAE_df$Variables <- factor(MAE_df$Variables)
MAE_df$Model <- factor(MAE_df$Model)
MAE_df$Set <- factor(MAE_df$Set)

plot_RMSE <-
  ggplot(data = RMSE_df, aes(x = Variables, y = RMSE, fill = Set)) + 
  geom_col(position = position_dodge2(
    preserve = "single", width = 0.8, padding = 0.15), width = 0.9) + 
  facet_grid(Model ~ .)

ggsave(plot = plot_RMSE, 
       filename = here::here(
         "..", "results", "download_LIVING", "plot_RMSE.png"))

plot_MAE <-
  ggplot(data = MAE_df, aes(x = Variables, y = MAE, fill = Set)) + 
  geom_col(position = position_dodge2(
    preserve = "single", width = 0.8, padding = 0.15), width = 0.9) + 
  facet_grid(Model ~ .)

ggsave(plot = plot_MAE, 
       filename = here::here(
         "..", "results", "download_LIVING", "plot_MAE.png"))



#############################################################################
#############################################################################

## eoS