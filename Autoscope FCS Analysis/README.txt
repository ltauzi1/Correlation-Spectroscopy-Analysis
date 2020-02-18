The main function is processFCSData. Use as follows:
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