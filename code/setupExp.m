function setupExp()
% setup paths for the experiment
%=============================================================================
% GLOBAL VARS AND FILE VARS
%=============================================================================
global CSVDIR STIMDIR RESDIR
global DEBUG RESOLUTION ACTUAL_REFRESH
global MAX_DIST_FIXATION_DEG BG_COLOR
global DEG2P EYE_USED
global STIM_SIZE_DEG STIM_POS_DEG FIX_CROSS_SIZE_DEG

myname = mfilename;
mydir = which(myname);
curdir = fileparts(mydir);

CSVDIR = fullfile(fileparts(curdir), 'csv');
STIMDIR = fullfile(fileparts(curdir), 'stim');
RESDIR = fullfile(fileparts(curdir), 'res');

%=============================================================================
% PARAMETERS OF THE SETUP -- CHANGE THIS ACCORDING TO YOUR ACTUAL SETUP
%=============================================================================
% debug mode?
DEBUG = 0;

DIST_CM = 50;  % distance subject-screen in cm
SCREEN_W_CM = 36.5;  % width of the screen in cm

% are we using a mac?
if strcmp(computer, 'MACI64')
    RESOLUTION = [800 600 0];
    ACTUAL_REFRESH = 60; %for stupid macs
else  % CCNL's lab eye tracker
    RESOLUTION = [800 600 85];
    ACTUAL_REFRESH = RESOLUTION(3);
end

if DEBUG
    EYE_USED = 0;
else
    EYE_USED = 1;  % 0 LEFT, 1 RIGHT
end

%=============================================================================
% EXTRA PARAMETERS -- YOU SHOULDN'T NEED TO CHANGE THESE
%=============================================================================

% Stimulus size and position -- from Crouzet et. al, 2010
STIM_SIZE_DEG = [14 14];  % width, height
STIM_POS_DEG = [8.6 0];  % x, y
FIX_CROSS_SIZE_DEG = [2 2];  % width, height
% Background color
BG_COLOR = [128, 128, 128];
% Maximum allowed distance from fixation
MAX_DIST_FIXATION_DEG = 2;  % considering possible errors of calibration of max 1 deg

% compute conversion factor visual angle --> pixel
DEG2P = angle2pix(1, DIST_CM, SCREEN_W_CM, RESOLUTION(1));

if DEBUG
    Screen('Preference', 'SkipSyncTests', 1);
end
