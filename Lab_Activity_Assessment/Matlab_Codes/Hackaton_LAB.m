clc;
clear;
close all;

%% Defining variables
subjPrint_co = 11; %is the subject we want to see graph
subjPrint_fl = 13; %the subject of fallers
g = 9.81;
fs = 100;
f_lowpass = 5;
f_highpass = 0.2;
time_analysis = 30; %time for analizing the data equal for all subject

%% Defining parameters for reading data
CO1= 'long-term-movement-monitoring-database-100\LabWalks\co0';
tail = '_base.dat';
j = [1:11,13:36,40:42];  %j for CO (only available subjects)
FL1 = 'long-term-movement-monitoring-database-100\LabWalks\fl0';
k = [1,3:11,13,15:28,30:39];  % k for FL (only available subjects)

%% Reading data and run the algorithm
% Controls
vel_co = zeros(length(j),1);
stepTime_co = zeros(length(j),1);
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
    [vel_co(i),stepTime_co(i)] = mean_LAB_velocity(subj,fs,f_lowpass,f_highpass,flagPlot,time_analysis);
end

% Fallers
vel_fl = zeros(length(k),1);
stepTime_fl = zeros(length(k),1);
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
    [vel_fl(i),stepTime_fl(i)] = mean_LAB_velocity(subj,fs,f_lowpass,f_highpass,flagPlot,time_analysis);
end

%% Removing outliers for a better result
vel_fl = rmoutliers(vel_fl);
vel_co = rmoutliers(vel_co);

fprintf('Control patients\n')
fprintf('mean velocity: %.5f\n',mean(vel_co));
fprintf('std velocity: %.5f\n',std(vel_co));
fprintf('mean Step time: %.5f \n\n',mean(stepTime_co))
fprintf('Fallers patients\n')
fprintf('mean velocity: %.5f\n',mean(vel_fl));
fprintf('std velocity: %.5f\n',std(vel_fl));
fprintf('mean Step time: %.5f \n',mean(stepTime_fl))

%% Preparing data for boxplot
stepTime = [stepTime_co; stepTime_fl];
label = [repmat({'Control'},length(stepTime_co),1)
                repmat({'Fallers'},length(stepTime_fl),1)];
figure
boxplot(stepTime,label)
grid on
title('Step Time')

velocity = [vel_co; vel_fl];
labels = [repmat({'Control'},length(vel_co),1)
                repmat({'Fallers'},length(vel_fl),1)];
figure
boxplot(velocity,labels)
grid on
title('Gait velocity')

figure
subplot(121)
histogram(vel_co,'BinWidth',0.2)
grid on
title('Gait velocity Control subjects')
xlabel('Velocity(m/s)')
ylabel('Frequency')
subplot(122)
histogram(vel_fl)
grid on
title('Gait velocity Faller subjects')
xlabel('Velocity(m/s)')
ylabel('Frequency')

