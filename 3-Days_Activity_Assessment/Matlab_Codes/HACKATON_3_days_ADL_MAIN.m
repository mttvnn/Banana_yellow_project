clc; clear; close all;

%% defining variables
subjPrint_co = 1;
subjPrint_fl = 1;
g = 9.81;
fs = 100;
f_lowpass = 5;
f_highpass=0.2;

%% defining parameters for reading data
CO1 = 'CO0';
tail = '.dat';
j = [1:25,27,30:32,35:37,39:42,44]; % j for CO (only readable subjects)
FL1 = 'FL0';
k = [1,4:9,11,14,16,18,19:23,25:32,34:36]; % k for FL (only readable subjects)

%load just the firts subject
%j=1;
%k=1;

%% controls
StepNumber_CO = zeros(length(j),1);
StrideDuration_CO = zeros(length(j),1);
Activity_CO = zeros(length(j),1);
for i = 1:length(j)
    if j(i)==subjPrint_co
        flagPlot=1;
    else 
        flagPlot =0;
    end
    if j(i)<10
        string = strcat(CO1,num2str(0),num2str(j(i)),tail);
    else 
        string = strcat(CO1,num2str(j(i)),tail);
    end
    subj = rdsamp (string);
    tic
    fprintf('Subject %d\n',j(i));
    [StepNumber_CO(i),StrideDuration_CO(i),Activity_CO(i)] = three_days_processing(subj,fs,f_lowpass,f_highpass,flagPlot);
    toc
end

%% fallers
StepNumber_FL = zeros(length(k),1);
StrideDuration_FL = zeros(length(k),1);
Activity_FL = zeros(length(k),1);
for i = 1:length(k)
    if k(i)==subjPrint_fl
        flagPlot=1;
    else 
        flagPlot =0;
    end
    if k(i)<10
        string = strcat(FL1,num2str(0),num2str(k(i)),tail);
    else 
        string = strcat(FL1,num2str(k(i)),tail);
    end
    subj = rdsamp (string);
    tic
    fprintf('Subject %d\n',k(i));
    [StepNumber_FL(i),StrideDuration_FL(i),Activity_FL(i)] = three_days_processing(subj,fs,f_lowpass,f_highpass,flagPlot);
    toc
end

%% Remove Outliers
StepNumber_CO=rmoutliers(StepNumber_CO,'percentiles',[10 90]);
StepNumber_FL=rmoutliers(StepNumber_FL,'percentiles',[20 100]);
StrideDuration_CO=rmoutliers(StrideDuration_CO,'percentiles',[5 100]);
StrideDuration_FL=rmoutliers(StrideDuration_FL,'percentiles',[30 100]);

%% Mean and Std
m_step_number_CO=mean(StepNumber_CO);
m_stride_duration_CO=mean(StrideDuration_CO);
m_activity_CO=mean(Activity_CO);
std_step_number_CO=std(StepNumber_CO);
std_stride_duration_CO=std(StrideDuration_CO);
std_activity_CO=std(Activity_CO);
fprintf('\nControls Step Number:%d+-%d',m_step_number_CO,std_step_number_CO);
fprintf('\nControls Stride Duration:%d+-%d',m_stride_duration_CO,std_stride_duration_CO);
fprintf('\nControls Activity:%d+-%d',m_activity_CO,std_activity_CO);

m_step_number_FL=mean(StepNumber_FL);
m_stride_duration_FL=mean(StrideDuration_FL);
m_activity_FL=mean(Activity_FL);
std_step_number_FL=std(StepNumber_FL);
std_stride_duration_FL=std(StrideDuration_FL);
std_activity_FL=std(Activity_FL);
fprintf('\nFallers Step Number:%d+-%d',m_step_number_FL,std_step_number_FL);
fprintf('\nFallers Stride Duration:%d+-%d',m_stride_duration_FL,std_stride_duration_FL);

fprintf('\nFallers Activity:%d+-%d',m_activity_FL,std_activity_FL);
