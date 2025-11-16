# Fall Risk Classifier

## Repository Structure
* Codes: main Matlab script and supporting SMOTE function
* Data: input data necessary for analysis
* Results: output figures and data
* README.md

## Requirements
* Statistics and Machine Learning Toolbox

## Executing program
1. Open Matlab and check the working directory
2. Run the main script 'Classificator.m'

## Workflow Overview
1. Data Import and imputation of missing data
2. Exploratory analysis and multicollinearity check
3. Creation of the binary target variable ('BinaryGroup')
4. Class imbalance handling
5. Model training using LASSO logistic regression with cross-validation and Optimal threshold selection via Youden’s J statistic
6. Model evaluation on the training and test samples using: confusion matrices, ROC-AUC, accuracy

## Notes
* Data processing steps are commented within 'Classificator.m'
* Outlier removal was not applied due to small sample size
