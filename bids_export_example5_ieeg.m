% Example to export NWB-formated iEEG data to BIDS
% The data is not included here because it is too large, but it 
% can be downloaded from https://dandiarchive.org/dandiset/000576
% 
% Arnaud Delorme - April 2024

folder = '/System/Volumes/Data/data/data/nwb000576/';
if ~exist(folder, 'dir')
    error([ 'Data folder not found' 10 'Download data at https://dandiarchive.org/dandiset/000576' 10 'and set the folder variable in this script' ]);
end

% list of files to include (a loop is also possible)
data = [];
data(end+1).file     = { fullfile(folder, 'sub-01', 'sub-01_ses-20140828T132700_ecephys+image.nwb') };
data(end+1).file     = { fullfile(folder, 'sub-02', 'sub-02_ses-20160302T164800_ecephys+image.nwb') };
data(end+1).file     = { fullfile(folder, 'sub-03', 'sub-03_ses-20150304T164400_ecephys+image.nwb') };
data(end+1).file     = { fullfile(folder, 'sub-04', 'sub-04_ses-20120829T175200_ecephys+image.nwb') };
data(end+1).file     = { fullfile(folder, 'sub-05', 'sub-05_ses-20121207T173500_ecephys+image.nwb') };
data(end+1).file     = { fullfile(folder, 'sub-06', 'sub-06_ses-20131209T113600_ecephys+image.nwb') };
data(end+1).file     = { fullfile(folder, 'sub-07', 'sub-07_ses-20160212T171400_ecephys+image.nwb') };
data(end+1).file     = { fullfile(folder, 'sub-08', 'sub-08_ses-20161217T120200_ecephys+image.nwb') };
data(end+1).file     = { fullfile(folder, 'sub-09', 'sub-09_ses-20170311T170500_ecephys+image.nwb') };

% Content for README file
README = 'Re-exporting Dandiset https://dandiarchive.org/dandiset/000576 as BIDS';

% call to the export function
bids_export(data, 'targetdir', 'BIDS000576', 'README', README, 'exportformat', 'same');

