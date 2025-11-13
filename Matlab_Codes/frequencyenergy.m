function [energy] = frequencyenergy(acel,time,fs)
% Calculating the energy per seconds of the signals 
energy = [];
for i=1:fs:length(time)-fs
    energy = [energy bandpower(acel(i:(fs+i),1),fs,[0 5])];
end
