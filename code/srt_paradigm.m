function srt_paradigm(subid, subnr, blocknr)
% SRT_PARADIGM(subid, subnr, blocknr)
%
% Main script to run the SRT paradigm introduced by Crouzet et al., 2010.
% You need to specify an existing subid, with existing CSV trial order,
% its subject number (subnr, for filename purposes for the eye tracker),
% and the number of the block.
if nargin < 3
    error('Specify subid, subnr, and blocknr');
end

% close everything just in case
Screen('CloseAll');

% default settings
PsychDefaultSetup(2);

% load setup for the experiment
setupExp;

global CSVDIR STIMDIR RESDIR
global DEBUG RESOLUTION ACTUAL_REFRESH
global MAX_DIST_FIXATION_DEG BG_COLOR
global DEG2P EYE_USED
global STIM_SIZE_DEG STIM_POS_DEG FIX_CROSS_SIZE_DEG

dummymode = DEBUG;

% convert values from visual angle to pixels
MAX_DIST_FIXATION_PIX = round(MAX_DIST_FIXATION_DEG * DEG2P);
STIM_SIZE_PIX = round(STIM_SIZE_DEG * DEG2P);
STIM_POS_PIX = round(STIM_POS_DEG * DEG2P);
FIX_CROSS_SIZE_PIX = round(FIX_CROSS_SIZE_DEG * DEG2P);

% get flip duration -- for calculations on flips
FLIP_DURATION_MS = 1/ACTUAL_REFRESH * 1000;

if DEBUG
    % print some useful information on the experimental setup
    fprintf('Experimental setup:\n')
    fprintf('\t fixation cross size in deg: %.1f %.1f\n', FIX_CROSS_SIZE_DEG);
    fprintf('\t fixation cross size in pix: %d %d\n', FIX_CROSS_SIZE_PIX);
    fprintf('\t stimulus size in deg: %.1f %.1f\n', STIM_SIZE_DEG);
    fprintf('\t stimulus size in pix: %d %d\n', STIM_SIZE_PIX);
    fprintf('\t stimulus offset in deg: %.1f %.1f\n', STIM_POS_DEG);
    fprintf('\t stimulus offset in pix: %d %d\n', STIM_POS_PIX);
    fprintf('\t maximum distance allowed for fixation in deg: %d\n', ...
        MAX_DIST_FIXATION_DEG);
    fprintf('\t maximum distance allowed for fixation in pix: %d\n', ...
        MAX_DIST_FIXATION_PIX);
    fprintf('\n\n');
end

% LOAD TASK INFO FOR THE SUBJECT
taskInfo_fn = sprintf('%s_blocks.txt', subid);
taskInfo_fn = fullfile(CSVDIR, subid, taskInfo_fn);
if ~exist(taskInfo_fn, 'file')
    error(['File %s does not exist. Please modify the _orig.txt file', ...
           ' with the order you like,\nand save it as %s.'], taskInfo_fn, ...
           taskInfo_fn);
end
fid = fopen(taskInfo_fn, 'r');
taskInfo = textscan(fid, '%s');
fclose(fid);

% TASK FOR THE CURRENT BLOCK
block = taskInfo{1}{blocknr};

tmp = regexp(block, 'tar-(.*?)_', 'tokens');
block_tar = tmp{1}{1};

tmp = regexp(block, 'dis-(.*?)_', 'tokens');
block_dis = tmp{1}{1}; 

% TEXT TO DISPLAY AT THE BEGINNING OF THE EXPERIMENT
if strcmp(block_tar, 'faces')
    texttarget = '\nthe faces';
elseif strcmp(block_tar, 'objects')
    texttarget = '\nthe objects';
else
    error('I know only faces and objects, got %s', block_tar);
end

% load block
block_fn = fullfile(CSVDIR, subid, block);

f = fopen(block_fn, 'r');
order_block = textscan(f, '%s%s%s%s%s%s%s', 'delimiter', ',');
fclose(f);

% get header
lenheader = length(order_block);
header = cell(1, lenheader);
for i = 1:lenheader
    header{i} = order_block{i}{1};
end

% get number of trials
nl = length(order_block{1});
ntrl = nl - 1;

% let's create the output right now and save it...no other information is
% needed right now
if ~exist(fullfile(RESDIR, subid, 'csv'), 'dir')
    mkdir(fullfile(RESDIR, subid, 'csv'));
end
resultsfn = fullfile(RESDIR, subid, 'csv', ...
    strrep(block, '.csv', sprintf('-%s.csv', datestr(now,30))));

% create dir for edf files
EDF_RESDIR = fullfile(RESDIR, subid, 'edf');
if ~exist(EDF_RESDIR, 'dir')
    mkdir(EDF_RESDIR);
end

ncols = 8; % col8 is jitter
nrows = ntrl + 1; % block plus header
output = cell([nrows, ncols]);
output(1, :) = [header, 'jitter'];
for i = 1:7
    output(2:end, i) = order_block{i}(2:end);
end
% add jitter using actual delays supported by the monitor
output(2:end, 8) = num2cell(...
                       randsample(round(800:FLIP_DURATION_MS:1600), ntrl, 1)); 
% save results file
cell2csv(resultsfn, output);

% open screen and setup PTB
try
    % call kbcheck once to speed callings
    KbCheck;

    screens = Screen('Screens');
    screenNumber = max(screens);
    
    oldRes = SetResolution(screenNumber, RESOLUTION(1), RESOLUTION(2), ...
                           RESOLUTION(3));
    [expWin,rect] = Screen('OpenWindow', screenNumber, BG_COLOR);
    if ~DEBUG
        HideCursor(screenNumber);
    end
    
    % get the midpoint (mx, my) of this window, x and y
    [mx, my] = RectCenter(rect);
    
    % ----- TIMING STUFF ------
    % get flip interval
    ifi = Screen('GetFlipInterval', expWin);
    
    % Numer of frames to wait when specifying good timing
    waitframes = 1;
    
    % period timings
    blank1Secs = 1;
    blank1Frames = round(blank2Secs/ifi);
    blank2Secs = .2;
    blank2Frames = round(blank1Secs/ifi);
    stimSecs = .4;
    stimFrames = round(stimSecs/ifi);    
    % ----- END TIMING STUFF ----
    
    % Retreive the maximum priority number
    topPriorityLevel = MaxPriority(expWin);
    
    % stimuli rectangles
    stimulus_rect = [0 0 STIM_SIZE_PIX]; 
    rectleft = CenterRectOnPoint(stimulus_rect, ...
                                 mx - STIM_POS_PIX(1), my + STIM_POS_PIX(2));
    rectright = CenterRectOnPoint(stimulus_rect, ...
                                  mx + STIM_POS_PIX(1), my + STIM_POS_PIX(2));
    
    %Preparing and displaying the welcome screen
    % We choose a text size of 24 pixels - Well readable on most screens:
    Screen('TextSize', expWin, 24);
    
    % This is our intro text. The '\n' sequence creates a line-feed:
    myText = ['Press a key to start the experiment.'];
    
    % Draw 'myText', centered in the display window:
    DrawFormattedText(expWin, myText, 'center', 'center');

    % Show the drawn text at next display refresh cycle:
    Screen('Flip', expWin);
    
    % Wait for key stroke. This will first make sure all keys are
    % released, then wait for a keypress and release:
    KbWait([], 3);

    % Fixation Cross
    FixCr = ones(FIX_CROSS_SIZE_PIX)*128;
    fix_cross_center = round(FIX_CROSS_SIZE_PIX/2);
    FixCr(fix_cross_center-1:fix_cross_center+1, :) = 0;
    FixCr(:, fix_cross_center-1:fix_cross_center+1) = 0;
    fixcross = Screen('MakeTexture', expWin, FixCr);
    
    % EL
    el = EyelinkInitDefaults(expWin);
    if ~EyelinkInit(dummymode, 1)
        fprintf('Eyelink Init aborted.\n');
        Eyelink('Shutdown');
        sca
        return;
    end
    
    % set calibration type (9 point) and auto-advance
    Eyelink('Command', 'calibration_type = HV9');
    Eyelink('Command', 'enable_automatic_calibration = YES');
    
    % set what we want to record...just basic stuff, we'll do post processing
    % later
    Eyelink('Command', ['file_event_filter = LEFT,RIGHT,FIXATION,', ...
                        'SACCADE,BLINK,MESSAGE,BUTTON,INPUT']);
    Eyelink('Command', ['link_event_filter = LEFT,RIGHT,FIXATION,', ...
                        'SACCADE,BLINK,MESSAGE,BUTTON,INPUT']);
    Eyelink('Command', 'file_sample_data = LEFT,RIGHT,GAZE,AREA');
    Eyelink('Command', 'link_sample_data = LEFT,RIGHT,GAZE,AREA');
    % open file
    edf_fn = sprintf('s%02d_%d', subnr, blocknr);
    Eyelink('OpenFile', edf_fn);
    % Save information about the current trial
    Eyelink('Message', ['Matlab output: ', resultsfn]);
    % CALIBRATION
    Eyelink('Message', ['Starting calibration']);
    EyelinkDoTrackerSetup(el);
    Eyelink('Message', ['Done calibration']);
    % DRIFT CORRECTION
    Eyelink('Message', ['Starting drift correction']);
    EyelinkDoDriftCorrection(el);
    Eyelink('Message', ['Done drift correction']);
    % START RECORDING
    Eyelink('StartRecording');
    % record few samples before starting with the experiment
    WaitSecs(0.1);
    % zero-plot time
    Eyelink('Message', 'SYNCTIME');
    
    myText = [sprintf('Block %d: make saccades toward %s.\n\n', ... 
        blocknr, texttarget), ...
        'Press a key to start the block.'];
    DrawFormattedText(expWin, myText, 'center', 'center');

    % Show the drawn text at next display refresh cycle:
    Screen('Flip', expWin);
    
    % Wait for key stroke. This will first make sure all keys are
    % released, then wait for a keypress and release:
    KbWait([], 3);
    
%     % start block
%     if DEBUG
%        ntrl = 10; 
%     end
    
    Eyelink('Message', sprintf('BLOCK %d %s SUBJECT %02d: START', ...
        blocknr, block_tar, subnr));
    Priority(topPriorityLevel);
    for itrl = 1:ntrl
        Eyelink('Message', ... 
            sprintf('Trial %d Code %s: START Target: %s Distractor: %s', ...
            itrl, ...
            output{1+itrl, 7}, ...
            output{1+itrl, 3}, output{1+itrl, 5}));
        % blank for 1000ms
        Eyelink('Message', sprintf('Trial %d Code %s: BLANK1 ON', itrl, ...
            output{1+itrl, 7}));
        vbl = Screen('Flip', expWin);
        
        % load stimuli
        target = imread(fullfile(STIMDIR, output{itrl+1, 3}));
        distr = imread(fullfile(STIMDIR, output{itrl+1, 5}));
        
        targetTexture = Screen('MakeTexture', expWin, target);
        distrTexture = Screen('MakeTexture', expWin, distr);
        
        % fixation cross for jittered period 
        Screen('DrawTexture', expWin, fixcross);
        vbl = Screen('Flip', expWin, vbl + (waitframes*blank1Frames - 0.5)*ifi);
        Eyelink('Message', sprintf('Trial %d Code %s: BLANK1 OFF', itrl, ...
            output{1+itrl, 7}));
        Eyelink('Message', sprintf('Trial %d Code %s: FIXATION ON', itrl, ...
            output{1+itrl, 7}));
        
        % jitter
        jitt = output{itrl+1, 8};
        jittFrames = round(jitt/1000/ifi);
        
        
        Screen('DrawTexture', expWin, fixcross);
        count_fixation = 1; % we want the subject to fixate for this much
        while count_fixation < jittFrames - 1
           % get position of the eye -- fixation cross is already on
           [trueEyePos, dist, rawEyePos] = ...
               getEyePos(mx, my, EYE_USED, DEBUG, expWin);
           if DEBUG
               fprintf('trueEyePos: %.2f %.2f; dist: %.2f\n', ...
                   trueEyePos, dist);
           end
           % check if it's within the range
           if dist <= MAX_DIST_FIXATION_PIX
               count_fixation = count_fixation + 1;
           else % otherwise reset counter
               count_fixation = 1;
           end
           % draw fixation cross again
           vbl = Screen('Flip', expWin, vbl + (waitframes - 0.5)*ifi, 1);
        end
        vbl = Screen('Flip', expWin, vbl + (waitframes - 0.5)*ifi);
        %[VBLTimestamp, StimulusOnsetTime, FlipTimestamp] = ...
        %    Screen('Flip', expWin, StimulusOnsetTime + jitt/1000);
        Eyelink('Message', sprintf('Trial %d Code %s: FIXATION OFF', itrl, ...
            output{1+itrl, 7}));
        Eyelink('Message', sprintf('Trial %d Code %s: BLANK2 ON', itrl, ...
            output{1+itrl, 7}));        
        % blank for 200ms
        % draw stimuli on the backbuffer according to the trial
        if strcmp(output(itrl+1, 6), 'right')
            Screen('DrawTexture', expWin, targetTexture, [], ...
                rectright);
            Screen('DrawTexture', expWin, distrTexture, [], ...
                rectleft);
        else
            Screen('DrawTexture', expWin, distrTexture, [], ...
                rectright);
            Screen('DrawTexture', expWin, targetTexture, [], ...
                rectleft);
        end
        vbl = Screen('Flip', expWin, vbl + (waitframes * blank2Frames - 0.5) * ifi);
        if DEBUG
            stimOn = vbl;
        end
        Eyelink('Message', sprintf('Trial %d Code %s: BLANK2 OFF', itrl, ...
            output{1+itrl, 7}));
        Eyelink('Message', sprintf('Trial %d Code %s: STIM ON', itrl, ...
            output{1+itrl, 7}));
        vbl = Screen('Flip', expWin, vbl + (waitframes * stimFrames - 0.5) * ifi);
        if DEBUG
            stimOff = vbl;
            fprintf('Stimulus on for %.5f secs\n', stimOff-stimOn);
        end
        Eyelink('Message', sprintf('Trial %d Code %s: STIM OFF', itrl, ...
            output{1+itrl, 7}));

        % clear stimuli textures     
        Screen('Close', [targetTexture, distrTexture]);
        Eyelink('Message', sprintf('Trial %d Code %s: DONE', itrl, ...
            output{1+itrl, 7}));
    end % trl for loop
    %reset priority
    Priority(0);
    
    Eyelink('Message', sprintf('BLOCK %d %s SUBJECT %02d: DONE', ...
        blocknr, block_tar, subnr));
    % get data from eyetracker
    Eyelink('StopRecording');
    Eyelink('CloseFile');
    % download data file
    try
        fprintf('Receiving data file ''%s''\n', edf_fn);
        status=Eyelink('ReceiveFile');
        if status <= 0
            fprintf('ReceiveFile status %d\n', status);
        end
        % move edf file and rename it accordingly
        if 2==exist([edf_fn, '.edf'], 'file')
            edf_fn_moved = [sprintf('%02d_', blocknr), ...
                strrep(block, '.csv', '.edf')];
            movefile([edf_fn, '.edf'], fullfile(EDF_RESDIR, edf_fn_moved));
            fprintf('Data file can be found in ''%s''\n', ...
                fullfile(EDF_RESDIR, edf_fn_moved));
        end
    catch rdf
        fprintf('Problem receiving data file ''%s''\n', edf_fn );
        rdf;
    end
    
    Eyelink('Shutdown');
    
    myText = ['Done.\n\n', ...
        'Press a key to exit.'];
    DrawFormattedText(expWin, myText, 'center', 'center');

    % Show the drawn text at next display refresh cycle:
    Screen('Flip', expWin);
    
    % Wait for key stroke. This will first make sure all keys are
    % released, then wait for a keypress and release:
    KbWait([], 3);
    ListenChar(0);
    ShowCursor;
    Screen('CloseAll');
    SetResolution(screenNumber, oldRes);   
catch
    ShowCursor;
    Screen('CloseAll'); %or sca
    psychrethrow(psychlasterror);
    SetResolution(screenNumber, oldRes);
    ListenChar(0);
end
end
