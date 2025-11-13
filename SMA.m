function [SMA] = SMA(acceleration,time,fs)
% Applying the SMA formulas
SMA = [];
for i=1:fs:length(time)-fs
    SMA = [SMA sum(sum(abs(acceleration(i:(i+fs),:))))/fs];
end

