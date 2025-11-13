function [ICpeak,ICind,FCpeak,FCind] = CWT(AP,fs)
% Applying the Countinuous Wavelet Transform to the signal 
IntegratedAP=cumtrapz(1/fs,AP);
scale=5:15;
cwtS1=-cwt(IntegratedAP,scale,'gaus1',1/fs);
S1=mean(cwtS1,1);
[ICpeak,ICind]=findpeaks(-S1,'MinPeakDistance',1.3*fs,'MinPeakProminence',0.5*std(S1));
cwtS2=-cwt(S1,scale,'gaus1',1/fs);
S2=mean(cwtS2,1);
[FCpeak,FCind]=findpeaks(S2,'MinPeakDistance',1.3*fs,'MinPeakProminence',0.5*std(S2));
end