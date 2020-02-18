%% This function reads and formats the .dat files that are produced by the downstairs FCS microscope Labview programs. 
% Inputs:
% filepath - the complete file path including the file name and extension.
% Should direct to a raw FCS data file collected with the shared microscope
% bintime - the bintime used for collection in ms. This is used to
% reconstruct the time axis as this is not actually stored in the data file
% Output:
%datafinal -  formatted as a 2 column matrix with the first column being the
%time and the second being counts. This format should be compatable with
%existing FCS analysis scripts. 

function datafinal = Read_FCS_Binary(filepath, bintime)
%% Read the raw data from the binary file
fid=fopen(filepath);
dataraw=fread(fid,'int32','b');
fclose(fid);

%% Calculate the change in counts between each element
% We ignore the first element in dataraw since it is just the number of
% acquired points.
temp1=dataraw(2:end-1);
temp2=dataraw(3:end);
data=temp2-temp1;
clear('temp1','temp2')
% data now contains the counts detected per bin time period. 
datalength=length(data);

%% Build the time array based on the user supplied bin time
time=(bintime:bintime:datalength*bintime)';

%% Concatenate the vecors
datafinal=[time data];
end