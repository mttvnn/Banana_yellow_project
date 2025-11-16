clc; clear all; close all;

% Steps for the analysis according to https://biz.libretexts.org/Workbench/OER_Textbook_for_Data_Analytics/06%3A_Logistic_Regression/6.09%3A_Steps_for_Building_a_Logistic_Regression_Model
rng(1);
%% 1. Data Preparation

% 1.1 Here we collect and import our raw dataset. 
Datos=readtable("ClinicalDemogData_COFL.xlsx");

Datos(26,:) = [];
Datos(27:28,:) = [];
Datos(30:31,:) = [];
Datos(33,:) = [];
Datos(37,:) = [];
Datos(47,:) = [];
Datos(48,:) = [];
Datos(49,:) = [];

%Import the following variables to the workspace manually

TotalAct=[tot;tot_fl];
Datos.range=range_1;
Datos.TotalAct=TotalAct;




%%
% 1.2 We need to handle missing data thorugh imputation or deletion

% A) Impute missing values in predictors:  using column mean) %https://es.mathworks.com/discovery/missing-data.html
Datos1=table2array(Datos(:,6:31));
Datos_imputed = table2array(Datos(:,6:31));
for col = 1:size(Datos1, 2)
   nanIndices = isnan(Datos1(:, col));
   Datos_imputed(nanIndices, col) = mean(Datos1(~nanIndices, col), 'omitnan');
end
% B) Option B would be deleting missing data

Datos1=array2table(Datos_imputed,"VariableNames",{ 'Age','YearFall','x6MonthsFall','yrAlmost','GDS','ABCTot_','SF_36','PASE', 'MMSE','MoCa','FAB','TMTa','TMTb','TUG','FSST','BERG','DGI','DGIStairs', 'base_velocity_', 's3_velocity_','feetCloseEyesOpen','feetCloseEyesClosed','tandem_eyes_open','tandem_eyes_closed','range','TotalAct'});




%% 2. Exploratory Data Analysis 

% 2.1. Summary statistics

format compact
summary(Datos1)

%% 2.2. Check for Multicollinearity (https://es.mathworks.com/help/matlab/data_analysis/visualize-corrcoef.html)

Datos1=table2array(Datos1);
[R,P]=corrcoef(Datos1); 
VIF=diag(inv(R))'  %(https://es.mathworks.com/matlabcentral/fileexchange/60551-vif-x)
% If VIF is between 1 and 5 this indicates a moderate multicollinearity,
% which indicates correlation with other predictos 
% If VIF is > 5, we have high multicollinearity, which makes this variable
% less reliable
% Finally, if VIF is >10, the signal is highly correlated and it can cause
% trouble

% Here, we are watching that YearFall and x6MonthsFall, TUG, BERG
% base_velocity_ and s3_velocity_ are quite correlated
R=tril(R,-1);
threshold = 0.05;
R(abs(P) > threshold) = 0;
[firstVar,secondVar,corrCoef] = find(R);
ind2 = sub2ind(size(P),firstVar,secondVar);
sigP = P(ind2);
TSig = table(firstVar,secondVar,corrCoef,sigP)
k = 5;
TTopk = topkrows(TSig,k,"corrCoef","descend",ComparisonMethod="abs")

%According to this, the variable YearFall is positive correlated with
%x6MonthsFall, s3_velocity is correlated with base_velocity_ and
%base_velocity is correlated with TUG, so we should remove this variables
%from the analysis 

%Therefore, we are going to remove for the analysis: s3_velocity,
%base_velocity, TUG and BERG

Datos1=array2table(Datos1(:,[1:13,15,17:18,21:26]),"VariableNames",{ 'Age','YearFall','x6MonthsFall','yrAlmost','GDS','ABCTot_','SF_36','PASE', 'MMSE','MoCa','FAB','TMTa','TMTb','FSST','DGI','DGIStairs','feetCloseEyesOpen','feetCloseEyesClosed','tandem_eyes_open','tandem_eyes_closed','range','TotalAct'});




%% 2.3. Select and define dependent variable

% We also prepare our response variable: if the number of falls reported
% are more than 2 within 6 months we will consider this patient as a
% potential future faller. 

% We want to associate control -->0 and fallers --> 1 as our dependent
% variable


Datos1.BinaryGroup = zeros(height(Datos1), 1);

for i=1:length(Datos1.x6MonthsFall)
    if Datos1.x6MonthsFall(i)>=2
        Datos1.BinaryGroup(i)=1;
    else 
        Datos1.BinaryGroup(i)=0;
    end

end 

%2.3.Check for imbalance in the dependent variable

disp(['The number of fallers is:', num2str(sum(Datos1.BinaryGroup==1))])
disp(['The number of controllers is:', num2str(sum(Datos1.BinaryGroup==0))])

% We clearly have an imbalance so we need to adress this

%We remove the variables that also are high correlated after obtaining the
%response variable

Datos1=Datos1(:,[1,4:end]); 
%% 2.4. Find outliers in the data 

% %We remove the outliers 
% TF = isoutlier(Datos1, "percentiles", [5 95]);
% Datos3=Datos1(~any(TF,2),:);

% After checking if we remove the outliers we are going to be left with
% just  16 rows. That's not feasible. So we are going to continue like this

%2.5 Normalize data
Datos1{:,1:20} = normalize(Datos1{:,1:20});


%% 3 Dividing datasets
% We split the data in two groups: data for testing the model and data for validating the model

%3.1.Here what we are doing is balancing both categories
Clase=categorical(Datos1.BinaryGroup);
Datos1=table2array(Datos1(:,1:20));
[Datos2,Clase2,new_Datos,new_Clase] = smote(Datos1, [],'Class',Clase); %https://matlab.mathworks.com/open/fileexchange/v1?id=75401
Datos2=array2table(Datos2,"VariableNames",{ 'Age','yrAlmost','GDS','ABCTot_','SF_36','PASE', 'MMSE','MoCa','FAB','TMTa','TMTb','FSST','DGI','DGIStairs','feetCloseEyesOpen','feetCloseEyesClosed','tandem_eyes_open','tandem_eyes_closed','range','TotalAct'});
Datos2.BinaryGroup=Clase2;
%% 3.2. Splitting the data
%n = length(Datos2.BinaryGroup); %Using this would be random splitting
%dataset
c = cvpartition(Datos2.BinaryGroup,HoldOut=0.3); % Stratified splitting dataset 

idxTrain = training(c,1);
idxTest = ~idxTrain;

train=Datos2(idxTrain,:);
test=Datos2(idxTest,:);


%% USE OF LASSSO VARIABLE SELECTION WITH CROSS VALIDATION 

% https://es.mathworks.com/help/stats/lassoglm.html

cv=cvpartition(train.BinaryGroup,'KFold',5); %Stratified splitting dataset
threshold=linspace(0.10,0.80,100);
lambda_grid = linspace(10,0.0001,100);

AUC_per_fold=zeros(cv.NumTestSets,1);

for i=1:cv.NumTestSets
    insidetrainingIdx=training(cv,i);
    insidetestIdx=~insidetrainingIdx;

    %We split data into training and testing sets
    insidetrainingData=train(insidetrainingIdx,:);
    insidetestData=train(insidetestIdx,:);

    Predictors=table2array(insidetrainingData(:,1:20));

    %Predictors=[insidetrainingData.Age, insidetrainingData.FSST, insidetrainingData.base_velocity_, insidetrainingData.PASE,insidetrainingData.MMSE, insidetrainingData.MoCa, insidetrainingData.FAB, insidetrainingData.TMTa, insidetrainingData.TMTb, insidetrainingData.DGIStairs,  insidetrainingData.s3_velocity_]; %, insidetrainingData.TotalAct, insidetrainingData.range]; insidetrainingData.BERG insidetrainingData.DGI, insidetrainingData.TUG

    %Train classification model: lasso
    [B,FitInfo]=lassoglm(Predictors,insidetrainingData.BinaryGroup,'binomial','CV',10,'Alpha',1,Lambda=lambda_grid);
    
    %We use the best lambda

    idxLambdaMinDeviance = FitInfo.IndexMinDeviance;
    B0 = FitInfo.Intercept(idxLambdaMinDeviance);
    coef = [B0; B(:,idxLambdaMinDeviance)]; %Coefficents of the chosen variables

    %Test classfication model

    Predictors=table2array(insidetestData(:,1:20));

    %Predictors=[insidetestData.Age, insidetestData.DGI, insidetestData.TUG, insidetestData.BERG, insidetestData.base_velocity_, insidetestData.PASE, insidetestData.MMSE, insidetestData.MoCa, insidetestData.FAB, insidetestData.TMTa, insidetestData.TMTb, insidetestData.DGIStairs]; %,  insidetestData.TotalAct, insidetestData.range]; insidetestData.FSST  insidetestData.s3_velocity_

    yhat = glmval(coef,Predictors,"logit");
    yhatBinom = (yhat>=0.5);
    [~, ~, ~, AUC] = perfcurve(insidetestData.BinaryGroup, double(yhatBinom), 1); 

    AUC_per_fold(i)=AUC;
end

meanAUC = mean(AUC_per_fold);
disp(['Mean AUC: ' num2str(meanAUC)]);

%% We train the model again and we validate it. 
Predictors=table2array(train(:,1:20));
%Predictors=[train.Age,train.DGI,train.TUG,train.FSST,train.BERG,train.base_velocity_, train.PASE, train.MMSE, train.MoCa, train.FAB, train.TMTa, train.TMTb, train.DGIStairs, train.s3_velocity_];%, train.TotalAct, train.range];
coefTable = table(["Intercept"; "Age"; "yrAlmost";"GDS";"ABCTot_";"SF_36";"PASE";"MMSE";"MoCa";"FAB";"TMTa";"TMTb";"FSST";"DGI";"DGIStairs";"feetCloseEyesOpen"; "feetCloseEyesClosed";"tandem_eyes_open";"tandem_eyes_closed";"range";"TotalAct"], coef,  'VariableNames', {'Variable','Coefficient'}); %; "TotAct";"Range"]

[B,FitInfo]=lassoglm(Predictors,train.BinaryGroup,'binomial','CV',10,'Alpha',1,Lambda=lambda_grid);
%lassoPlot(B,FitInfo,plottype="CV"); 
%legend("show") % Show legend
idxLambdaMinDeviance = FitInfo.IndexMinDeviance;
B0 = FitInfo.Intercept(idxLambdaMinDeviance);
coef = [B0; B(:,idxLambdaMinDeviance)];
disp(coefTable(coefTable.Coefficient~=0,:));

%% Threshold optimization

%Optimization based on AUC performance

% for i=1:length(threshold)
%     yhat = glmval(coef,Predictors,"logit");
%     yhatBinom = (yhat>=threshold(i));
%     [X, Y, ~, AUCTrain(i)] = perfcurve(train.BinaryGroup, double(yhatBinom), 1);  
% end
% 
% [best_AUC, best_idx] = max(AUCTrain);
% best_threshold = threshold(best_idx); 
% 
% disp(['Optimal threshold:', num2str(best_threshold)]);
% 
% figure;
% plot(threshold, AUCTrain, '-o');
% xlabel('Threshold');
% ylabel('AUC');
% title('Threshold Optimization');
% grid on;  

%Optimization based on Youden Index

 yhat = glmval(coef,Predictors,"logit");
 [X, Y, T, AUCTrain,OPTROCPT] = perfcurve(train.BinaryGroup, yhat, 1); 
 best_threshold=T((X==OPTROCPT(1))&(Y==OPTROCPT(2)));
 disp(['Optimal threshold:', num2str(best_threshold)]);
% 
%% Evaluation of the model in the training dataset

yhat = glmval(coef,Predictors,"logit");
yhatBinom = (yhat>=best_threshold);
CTrain=confusionmat(double(train.BinaryGroup)-1,double(yhatBinom),'Order',[0 1]);

SensitivityTrain = CTrain(2,2) / (CTrain(2,1) + CTrain(2,2));  
SpecificityTrain = CTrain(1,1) / (CTrain(1,1) + CTrain(1,2));
disp(['Sensivity: ' num2str(SensitivityTrain)]);
disp(['Specificity: ' num2str(SpecificityTrain)]);
AccuracyTrain =sum(diag(CTrain))/sum(CTrain,'all'); 
disp(['Accuracy: ' num2str(AccuracyTrain)]);
[X, Y, ~, AUCTrain] = perfcurve(train.BinaryGroup, yhat, 1);  
disp(['AUC(Train):' num2str(AUCTrain)]);

confusionchart(double(train.BinaryGroup)-1,double(yhatBinom));
%matrix_labels = {'0','1'};
%confusionchart(CTrain,matrix_labels)
xlabel('Predicted');
ylabel('True'); 

figure;
plot(X, Y, 'LineWidth', 2);
xlabel('False Positive Rate');
ylabel('True Positive Rate');
title('ROC Curve (Train)');
grid on;

%%  Evaluation of the model in the test dataset

Predictors=table2array(test(:,1:20));
%Predictors=[test.Age,test.DGI,test.TUG,test.FSST,test.BERG,test.base_velocity_, test.PASE, test.MMSE, test.MoCa, test.FAB, test.TMTa, test.TMTb, test.DGIStairs, test.s3_velocity_];%, test.TotalAct, test.range];


yhat = glmval(coef,Predictors,"logit");
yhatBinom = (yhat>=best_threshold);

C=confusionmat(double(test.BinaryGroup)-1,double(yhatBinom));
confusionchart(double(test.BinaryGroup)-1,double(yhatBinom));
xlabel('Predicted');
ylabel('True'); 
Sensitivity = C(2,2) / (C(2,1) + C(2,2));  
Specificity = C(1,1) / (C(1,1) + C(1,2));
disp(['Sensivity: ' num2str(Sensitivity)]);
disp(['Specificity: ' num2str(Specificity)]);
Accuracy =sum(diag(C))/sum(C,'all'); 
disp(['Accuracy: ' num2str(Accuracy)]);
[X, Y, ~, AUC] = perfcurve(double(test.BinaryGroup)-1, double(yhatBinom), 1);  
disp(['AUC(Test):' num2str(AUC)]);

%Results
figure;
plot(X, Y, 'LineWidth', 2);
xlabel('False Positive Rate');
ylabel('True Positive Rate');
title('ROC Curve (Test)');
grid on;

Results3=table([SensitivityTrain;Sensitivity],[SpecificityTrain;Specificity],[AccuracyTrain;Accuracy],[AUCTrain;AUC],'RowNames',{'Train';'Test'},'VariableNames',{'Sensivity','Specificity','Accuracy','AUC'});
disp(Results3)









    


    
