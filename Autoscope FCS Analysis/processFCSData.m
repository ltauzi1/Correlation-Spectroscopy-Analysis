function [stdData, expData] =processFCSData(dataPath,bintime,stdFiles,expFiles)
%Process FCS data collected with FCSHighSpeed Labview Scripts
%   This function will read in all data files in a user defined list of
%   subfolders in a directory constructed using the FCS Highspeed Labview
%   VI. These subfolders should be named S followed by a number, for
%   instance S1, S2, etc. 
%
%   In a typical FCS experiment you will measure a sample of known
%   hydrodynamic radius to calibrate the focal volume prior to measuring an
%   unknown sample of interest. This function assumes you have done this
%   and asks you to designate your standard sameple data and experimental
%   data separately. This is to simplify downstream processing such as
%   fitting and the actual focal volume calibration. 
%
%   Input Arguments:
%   dataPath - (string) path of the main data directory. Should contain subfolders
%   labeled S1, S2, etc.
%
%   binTime - the original experiment bin time in ms. Typically 0.01 ms.
%
%   stdFiles - row vector containing the list of subfolders to analyze and
%   store as standard files for calibrating the focal volume. These files
%   are processed the same as expFiles but stored separately so they are
%   easier to work with later. For example if stdFiles = [1 2 3] then all
%   of the files in folders S1, S2 and S3 will be processed and stored as
%   standard data. 
%
%   expFiles - row vector containing the list of subfolders to analyze and
%   store as experiment files. The processing performed on these files is
%   the same as stdFiles but they will be stored in a separate structure.
%   
%   Outpt:
%   stdData - Structure containing the raw data and autocorrelated data for
%   all of the files in the folders designated in stdFiles. stdData.Source
%   is the originating folder the data was pulled from. stdData.RawData is
%   an n x m matrix where m is the number of files in the folder and n is
%   the number of data points. So each column is a trajectory. StdData.Time
%   is the time vector that goes with the trajectories in stdData.RawData.
%   stdData.LagsBinned and stdData.ACBinned are the lag times and the
%   corresponding normlaizedautocorrelation of each time trace binned logarithmically
%  .
%   expData - Structure containing the same data as stdData for the folders
%   designated in expFiles. 
%   Note that the raw data is saved in the structure as a 32 bit integer to
%   save memory. Keep that in mind when using it for computations. You may
%   need to convert it to a floating point data type first. 
%
%   This function also plots all the autocorrelation curves and saves the
%   figures in an analysis directory it creates in dataPath. It will also
%   save stdData and expData to dataPath as .mat files. 
%
%   Example:
%   [stdData, expData]=processFCSData('Z:\MyDir',0.01,[1 2 3],[4 5 6]);
%   This would process all of the data in folders S1, S2, and S3 as
%   standard data and S4, S5, and S6 as experimental data. All the S
%   folders should be found in Z:\MyDir

%% Read in raw data
stdData=struct([]); %create an empty structure to store our standard data in
expData=struct([]); %create an empty structure to store our experimental data in
cd(dataPath) % change to working directory

%Begin loop to read in standard data files
for ifolder=1:length(stdFiles)
    path=fullfile(dataPath, ['S' num2str(stdFiles(ifolder))]);
    % Check to make sure that folder actually exists.  Warn user if it doesn't.
    if ~isfolder(path)
        errorMessage = sprintf('Error: The following folder does not exist:\n%s', path);
        uiwait(warndlg(errorMessage));
        return;
    end
    stdData(ifolder).Source=path;
    % Get a list of all files in the folder with the desired file name pattern.
    filePattern = fullfile(path, '*.dat');
    theFiles = dir(filePattern);
    %Filter out any files smaller than 1000 bytes. This gets rid of the
    %metadata file automaticlaly saved by the FCS program. 
    theFiles = theFiles([theFiles.bytes]>1000);
    for k = 1 : length(theFiles) % loop over each .dat file in the folder
        baseFileName = theFiles(k).name;
        fullFileName = fullfile(path, baseFileName);
        fprintf(1, 'Now reading %s\n', fullFileName);
        M=Read_FCS_Binary(fullFileName, bintime); %read in data from custom binary
        %Place data into data structure
        if k==1
            stdData(ifolder).Time=M(:,1);
        end
        stdData(ifolder).RawData(:,k)=int32(M(:,2));
    end
end

%Begin loop to read in expermintal data files
for ifolder=1:length(expFiles)
    path=fullfile(dataPath, ['S' num2str(expFiles(ifolder))]);
    % Check to make sure that folder actually exists.  Warn user if it doesn't.
    if ~isfolder(path)
        errorMessage = sprintf('Error: The following folder does not exist:\n%s', path);
        uiwait(warndlg(errorMessage));
        return;
    end
    expData(ifolder).Source=path;
    % Get a list of all files in the folder with the desired file name pattern.
    filePattern = fullfile(path, '*.dat');
    theFiles = dir(filePattern);
    theFiles = theFiles([theFiles.bytes]>1000);
    for k = 1 : length(theFiles)
        baseFileName = theFiles(k).name;
        fullFileName = fullfile(path, baseFileName);
        fprintf(1, 'Now reading %s\n', fullFileName);
        M=Read_FCS_Binary(fullFileName, bintime);
        %Place raw data in final structures
        if k==1
            expData(ifolder).Time=M(:,1);
        end
        expData(ifolder).RawData(:,k)=int32(M(:,2));
    end
end
clear M

%% Compute Autocorrelation
%Check for analysis directory and create one if it doesn't exist
check_for_dir = dir;
dir_flag_AC = 0;
for idir = 1:length(check_for_dir)
    if strcmp('AC_analysis',check_for_dir(idir).name)
        dir_flag_AC = 1;    
    end
end

if dir_flag_AC == 0
    mkdir('AC_analysis');
end
% Loop over standard files
for i=1:length(stdData)
    for j=1:size(stdData(i).RawData,2) %run autocorrelation one data set at a time
        [AC,ACBinned, lags, lagsBinned] = FCSAutocorrelation(double(stdData(i).RawData(:,j)),bintime);
        %compile results in data structure
        %Currently only saving binned AC and binned lags to save memory.
        %Uncomment the following lines to save everything
%         stdData(i).AC(:,j)=AC;
        stdData(i).ACBinned(:,j)=ACBinned;
%         stdData(i).Lags(:,j)=lags;
        stdData(i).LagsBinned(:,j)=lagsBinned;
        clear AC lags
    end
end

%Loop over experiment files
for i=1:length(expData)
    for j=1:size(expData(i).RawData,2) %run autocorrelation one data set at a time
        [AC,ACBinned, lags, lagsBinned] = FCSAutocorrelation(double(expData(i).RawData(:,j)),bintime);
        %compile results in data structure
%         expData(i).AC(:,j)=AC;
        expData(i).ACBinned(:,j)=ACBinned;
%         expData(i).Lags(:,j)=lags;
        expData(i).LagsBinned(:,j)=lagsBinned;
        clear AC lags
    end
end
%% Plot and save the data
%Plot the FCS curves for each file
plotFCS(stdData,dataPath)
plotFCS(expData,dataPath)
%Save all the data
save(fullfile(dataPath,'AC_analysis','AnalyzedData'),'stdData','expData')
end

%Plot subfunction
function plotFCS(data,dataPath)
for iplot = 1:length(data)
    figure
    h=plot(data(iplot).LagsBinned,data(iplot).ACBinned,'o'); %plot all runs
    %I want filled in circles so set markerfacecolor to the default colors
    set(h,{'MarkerFaceColor'},get(h,'Color'),'MarkerSize',8)
    %make the x axis log scale
    set(gca,'XScale','log','FontSize',12)
    xlabel('Lag Time (ms)','FontSize',14)
    ylabel('Autocorrelation','FontSize',14)
    xlim([0.005,80000])
    title(data(iplot).Source(end-1:end))
    for i=1:length(h)
        legtext{i}=sprintf('Run %d',i); %Generate legend text
    end
    legend(legtext)
    %Save as .tif image
    saveas(gcf,fullfile(dataPath,'AC_analysis',[data(iplot).Source(end-1:end) '.tif']))
end
end

