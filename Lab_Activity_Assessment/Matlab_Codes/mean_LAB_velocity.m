function [vel,stepTime] = mean_LAB_velocity(subj,fs,f_lowpass,flagPlot,time_analysis)
%this function allows to compute the mean velocity starting from
%acelerometer signal
%if flagPlot = 1 it also plot them
%Takes as input a matrix with three-axis accelerometers, sampling freq, and
%frequencies for LPF and HPF and the selected time interval for normalizing
%signals. The outputs are the mean velocity and the mean step time

%defining variables
acel = subj(:,1:3);
gyro = subj(:,4:6);

%filtering the signals
[b,a] = butter(4,f_lowpass*2/fs);
acel = filtfilt(b,a,acel);
gyro = filtfilt(b,a,gyro);
% HPF is not needed because in MoeNillsen is removed g

%applying moe nillsen algorithm to adjust axis
[acel(:,3), acel(:,2), acel(:,1)] = algo_Moe_Nilssen(acel(:,3),acel(:,2),acel(:,1),'tiltAndNoG');

%defining time vector
time = (1/fs:1/fs:length(acel)/fs);

%plot accelerations
if flagPlot
    figure
    subplot(211)
    plot(time,acel)
    grid on
    hold on
    xlabel('seconds [s]')
    ylabel('g')
    legend('Vertical','ML','AP')
    title('Acelerations')
    subplot(212)
    plot(time,gyro)
    grid on
    hold on
    xlabel('seconds [s]')
    ylabel('m/s')
    legend('Roll','Pitch','Yaw')
    title('Angular velocities')
end

%from now on we only need AP acceleration
% This because every peak in the AP acceleration signal correspond to the
% Initial Contact (Trojanello et al. 2013) (Gonzalez et al. 2009)
% This is an event present in every gait cycles and reflect the cyclic 
% characteristic of the human gait
acc = acel(:,3);     

%interval selection + normalization (Weiss et.al 2011)
Nsamples = round(time_analysis*fs);
start = round((length(acc)-Nsamples)/2);
acc = acc(start:start+Nsamples);   %selecting just a pre-defined time interval for analysis
acc = (acc-mean(acc))/std(acc);    %normalizing the signal
time = (start/fs:1/fs:(start+Nsamples)/fs); %adjusting the time vector

%finding peaks representing steps
[pksAP,locsAP] = findpeaks(acc,'MinPeakDistance',0.4*100);

%plot the identified peaks 
if flagPlot
    figure
    plot(time,acc,start/fs+locsAP/fs,pksAP,'*')
    hold on
    grid on
    xlabel('seconds [s]')
    ylabel('aceleration [m/s^2]')
    title('AP aceleration')
    legend('AP','Step')
end

%OFDRI to obtain displacement
for i=1:length(pksAP)-1
    kAP(i) = trapz(acc(locsAP(i:i+1)))/fs;
end

AAP = trapz(kAP);       %displacement
Ls = 0.775 * AAP;       %step length (Wenxia Lu et.al) k = 0.775
stepTime = mean(diff(locsAP/fs));
vel = Ls / stepTime;    %velocity

end