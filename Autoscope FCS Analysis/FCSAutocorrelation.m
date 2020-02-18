function [AC,ACBinned, lags, lagsBinned] = FCSAutocorrelation(data,bintime)
%Perform the normalized autocorrelation on time trajectory data for FCS
%analysis

% Start Main Loop over each element in the data structure
F=data;
maxLag=length(F)*bintime;
meanF=mean(F);

dF=F-meanF;
F = F(1:int32(maxLag/bintime));
[AC, lags]=xcorr(dF); % perform autocorrelation of deviations from the mean
AC = AC/meanF^2/length(dF); %Normalize
minLag=(length(lags)-1)/2+2; %ensure lag=0 is not included
if int32(maxLag/bintime) >= (length(F)-2)
    maxLags = minLag + int32(maxLag/bintime)-2; % to make sure the matrix
    % dimensions are not exceeded
else
    maxLags = minLag + int32(maxLag/bintime);
end
AC=AC(minLag:maxLags); %get rid of the negative lagtimes
lags=lags(minLag:maxLags);
%Bin the data logarithmically
[lagsBinned, ACBinned]=logbindata(lags,AC,bintime,maxLag);
lags=lags*bintime;%convert lags to time
lagsBinned=lagsBinned*bintime;
end

