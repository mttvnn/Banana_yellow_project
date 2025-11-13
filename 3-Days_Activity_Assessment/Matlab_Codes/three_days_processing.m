function [Total_StepNumber, Average_StrideDuration,act] = three_days_processing(subj,fs,f_lowpass,f_highpass,flagPlot)

%% defining variables
acel = subj(:,1:3);
gyro = subj(:,4:6);

%% filtering the signals
[b,a] = butter(4,f_lowpass*2/fs);
acel = filtfilt(b,a,acel);
gyro = filtfilt(b,a,gyro);
% HPF is not needed because in MoeNillsen is removed g

%% applying moe nillsen algorithm to adjust axis
[acel(:,3), acel(:,2), acel(:,1)] = algo_Moe_Nilssen(acel(:,3),acel(:,2),acel(:,1),'tilt');

%% filtering the signals
[b,a] = butter(4,f_highpass*2/fs,'high');
acel = filtfilt(b,a,acel);

%defining time vector
time = (1/fs:1/fs:length(acel)/fs);

%% SMA filterering
SMA_data = SMA(acel,time,fs);
SMA_logic = SMA_data>(0.18);

% figure()
% plot(time,SMA_logic)

%% Second filtering
energy= frequencyenergy(acel,time,fs); %each value represent one second
energy_logic = energy > 0.05;  %(weiss 2013)
activity = energy_logic | SMA_logic;

%% evaluating avarage activity
global_activity = activity_detection(activity);
act = sum(global_activity)/length(activity)*100;

%% plot accelerations and ang.velocities
flagPlot = 1;
if flagPlot
    figure
    subplot(411)
    plot(time,acel)
    grid on
    hold on
    xlabel('seconds [s]')
    ylabel('g')
    legend('Vertical','ML','AP')
    title('Acelerations')
    subplot(412)
    plot(global_activity)
    grid on
    hold on
    xlabel('seconds [s]')
    ylabel('activity')
    ylim([-.5 1.5])
    subplot(413)
    plot(SMA_logic)
    title('SMA')
    subplot(414)
    plot(energy_logic)
    title('energy')
end

%% StepNumber
AP = acel(:,3);

start_activity = [];
end_activity = [];

if global_activity(1) > 0
        start_activity = 1;
end

for i=2:length(global_activity)
    if global_activity(i-1) == 0 & global_activity(i) > 0
        start_activity = [start_activity; i*fs];
    elseif global_activity(i-1) > 0 & global_activity(i) == 0
        end_activity = [end_activity; i*fs];
    end
end

if length(start_activity) ~= length(end_activity)
    end_activity = [end_activity; length(global_activity)*fs];
end

% Unbiased Correlation Method
for i=1:length(start_activity)
    [APcorr,lags]=xcorr(AP(start_activity(i):end_activity(i)),'unbiased');
    CenterSample=find(lags==0);
    APcorr=APcorr/APcorr(CenterSample);
    sign=APcorr(CenterSample:end);

    [pks,Ind]=findpeaks(sign);
    IndAd1=Ind(1);

    StepNumber(i)=(end_activity(i)-start_activity(i))/IndAd1;
end

Total_StepNumber=sum(StepNumber);



%% Stride Duration
window_len = 60 * fs;     
for i = 1:length(start_activity)
    s = start_activity(i);
    e = end_activity(i);
    bout_len = e - s + 1;
    if bout_len < window_len
        continue;
    end

    AP_w = AP(s:e);

    nwin = floor(bout_len / window_len);

    for w = 1:nwin
        win_start = (w-1)*window_len + 1; 
        win_end   = w*window_len;
        win_AP = AP_w(win_start:win_end);

        % CWT method
        [ICpeak, ICind, FCpeak, FCind] = CWT(win_AP, fs);

        [ICind, FCind, Check] = check(FCind, ICind);

        if Check==0
            continue;
        end

        for j=1:length(ICind)-2
            stride_duration(j) = ICind(j+2)-ICind(j);
        end

        Window_Stride_duration(w) = sum(stride_duration)/fs;

    end
end

Average_StrideDuration = median(Window_Stride_duration);
end