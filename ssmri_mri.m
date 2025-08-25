%ssmri-mri

% global edfFile dummymode height width el status window1;

%% MAKE SURE TO RESTART MATLAB after you connect the laptop
% to the scanner/projector/other equipments,
% otherwise PTB will not recognize the external signals.

% NOTES:
% 66 trials (i.e., 15*4)
% 4 second-long trials (1 second fixation and 3 second image)
% 66 trials * 4 seconds = 264 seconds
% 264 seconds + 14 s pre + 16 sec post = 294 seconds for the entire run
%
% scanner TR = 1.5 second duration
%
% 294 s / 1.5 s = 196 dynamics (i.e., number of TRs)
% 294 s / 60s = 4:54 minutes

% There are 6 dummy scans with roughly 1.5 s for each of the 6, but it is
% unreliable; average is 1.5 seconds per scan, not precise.
% Stimulation starts at the first dynamic scan with a manual
% trigger: 3, 2, 1, go.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Set up file paths
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

addpath(genpath(fullfile('Applications', 'Psychtoolbox')));
Screen('Preference', 'SkipSyncTests', 1);
sca; clear all; clc;
Screen('Preference','SkipSyncTests', 1);
PsychJavaTrouble;
localDir = '~/Desktop/ssmri-mri';

% Add location of support files to path.
addpath(genpath(fullfile(localDir, 'supportFiles')));
addpath(genpath(fullfile(localDir, 'stimuli-3TB-new')));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Set up base parameters
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

prefs.backColor = [100 100 100];   % (0 0 0) is black, (255 255 255) is white
prefs.foreColor = [255 255 255];
prefs.imgframe = 15;
fixationduration = 1; %seconds
trialduration = 4; %seconds
imagonduration = trialduration-fixationduration; %seconds
prefs.imgbuffer = 15;
nTrials_percategory = 15;

% Do you want to lock the timing to the trigger from the MRI?
tlock = 'no'; %yes, no; yes doesn't work right now because '`~' doesn't seem to be recognized, even though it is a valid KbName

prefs.scanner = 'B'; %deblank(input('\nIs this 3T A or B (e.g., A or B): ', 's'));%'1';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% INITIALIZE EYELINK CONNECTION; OPEN EDF FILE; GET EYELINK TRACKER VERSION
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Initialize EyeLink connection (dummymode = 0) or run in "Dummy Mode" without an EyeLink connection (dummymode = 1);
dummymode = 0;
EyelinkInit(dummymode); % Initialize EyeLink connection
status = Eyelink('IsConnected');
if status < 1 % If EyeLink not connected
    dummymode = 1;
end

% Open dialog box for EyeLink Data file name entry. File name up to 8 characters
prompt = {'Enter EDF file name (up to 8 characters)'};
dlg_title = 'Create EDF file';
def = {'demo'}; % Create a default edf file name
answer = inputdlg(prompt, dlg_title, 1, def); % Prompt for new EDF file name
% Print some text in Matlab's Command Window if a file name has not been entered
if  isempty(answer)
    fprintf('Session cancelled by user\n')
    cleanup; % Abort experiment (see cleanup function below)
    return
end
edfFile = answer{1}; % Save file name to a variable
% Print some text in Matlab's Command Window if file name is longer than 8 characters
if length(edfFile) > 8
    fprintf('Filename needs to be no more than 8 characters long (letters, numbers and underscores only)\n');
    cleanup; % Abort experiment (see cleanup function below)
    return
end

% Open an EDF file and name it
failOpen = Eyelink('OpenFile', edfFile);
if failOpen ~= 0 % Abort if it fails to open
    fprintf('Cannot create EDF file %s', edfFile); % Print some text in Matlab's Command Window
    cleanup; %see cleanup function below
    return
end

% Get EyeLink tracker and software version
% <ver> returns 0 if not connected
% <versionstring> returns 'EYELINK I', 'EYELINK II x.xx', 'EYELINK CL x.xx' where 'x.xx' is the software version
ELsoftwareVersion = 0; % Default EyeLink version in dummy mode
[ver, versionstring] = Eyelink('GetTrackerVersion');
if dummymode == 0 % If connected to EyeLink
    % Extract software version number.
    [~, vnumcell] = regexp(versionstring,'.*?(\d)\.\d*?','Match','Tokens'); % Extract EL version before decimal point
    ELsoftwareVersion = str2double(vnumcell{1}{1}); % Returns 1 for EyeLink I, 2 for EyeLink II, 3/4 for EyeLink 1K, 5 for EyeLink 1KPlus, 6 for Portable Duo
    % Print some text in Matlab's Command Window
    fprintf('Running experiment on %s version %d\n', versionstring, ver );
end
% Add a line of text in the EDF file to identify the current experimemt name and session. This is optional.
% If your text starts with "RECORDED BY " it will be available in DataViewer's Inspector window by clicking
% the EDF session node in the top panel and looking for the "Recorded By:" field in the bottom panel of the Inspector.
preambleText = sprintf('RECORDED BY Psychtoolbox demo %s session name: %s', mfilename, edfFile);
Eyelink('Command', 'add_file_preamble_text "%s"', preambleText);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% SELECT AVAILABLE SAMPLE/EVENT DATA
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% See EyeLinkProgrammers Guide manual > Useful EyeLink Commands > File Data Control & Link Data Control

% Select which events are saved in the EDF file. Include everything just in case
Eyelink('Command', 'file_event_filter = LEFT,RIGHT,FIXATION,SACCADE,BLINK,MESSAGE,BUTTON,INPUT');
% Select which events are available online for gaze-contingent experiments. Include everything just in case
Eyelink('Command', 'link_event_filter = LEFT,RIGHT,FIXATION,SACCADE,BLINK,BUTTON,FIXUPDATE,INPUT');
% Select which sample data is saved in EDF file or available online. Include everything just in case
if ELsoftwareVersion > 3  % Check tracker version and include 'HTARGET' to save head target sticker data for supported eye trackers
    Eyelink('Command', 'file_sample_data  = LEFT,RIGHT,GAZE,HREF,RAW,AREA,HTARGET,GAZERES,BUTTON,STATUS,INPUT');
    Eyelink('Command', 'link_sample_data  = LEFT,RIGHT,GAZE,GAZERES,AREA,HTARGET,STATUS,INPUT');
else
    Eyelink('Command', 'file_sample_data  = LEFT,RIGHT,GAZE,HREF,RAW,AREA,GAZERES,BUTTON,STATUS,INPUT');
    Eyelink('Command', 'link_sample_data  = LEFT,RIGHT,GAZE,GAZERES,AREA,STATUS,INPUT');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Get user input
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Orient to the Matlab command window for user input.
commandwindow;

%% Set session information: user input.

% Input
prefs.subID = deblank(input('\nPlease enter the subID number (e.g., SS09): ', 's'));%'101';
prefs.day = str2num(deblank(input('\nPlease enter the MRI day (e.g., 1, 2, 3, etc.): ', 's')));%'1';
prefs.run = str2num(deblank(input('\nPlease enter the MRI run number (e.g., 0, 1, 2, 3, or 4): ', 's')));%'1';

% Ask user to check.
ch = input(['\nCHECK: Participant ' prefs.subID ', Day ' num2str(prefs.day) ', Run ' num2str(prefs.run) ', on 3T' prefs.scanner '. Is this entirely correct [y, n]? '], 's');
if strcmp(ch, 'no') || strcmp(ch, 'NO') || strcmp(ch, 'n') || strcmp(ch, 'N')
    error('Please start over and be sure to enter the information correctly.');
elseif ~strcmp(ch, 'yes') && ~strcmp(ch, 'YES') && ~strcmp(ch, 'y') && ~strcmp(ch, 'Y')
    error('Your response must be either y or n. Please start over and be sure to enter the information correctly.');
end
clear ch;

% Check to see if a file already exists for this sub, day, and run number. 
% If yes, ask the user to double check that they entered everything correctly.
stringtocheck = ['sub-' prefs.subID '_ses-' num2str(prefs.day) '_task-street_run-' num2str(prefs.run) '_scanner-' prefs.scanner '_*.txt'];
prerun = dir(fullfile(localDir, 'output', stringtocheck));
if ~isempty(prerun)
    disp('');
    disp('*** A file exists for this run ***'); pause(1);
    ch = input(['\*** DOUBLE CHECK: Participant ' prefs.subID ', Day ' num2str(prefs.day) ', Run ' num2str(prefs.run) ', on 3T' prefs.scanner '. Is this entirely correct [y, n]? '], 's');
    if strcmp(ch, 'no') || strcmp(ch, 'NO') || strcmp(ch, 'n') || strcmp(ch, 'N')
        error('Please start over and be sure to enter the information correctly.');
    elseif ~strcmp(ch, 'yes') && ~strcmp(ch, 'YES') && ~strcmp(ch, 'y') && ~strcmp(ch, 'Y')
        error('Your response must be either y or n. Please start over and be sure to enter the information correctly.');
    end
clear ch
end
clear prerun;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Set up stimuli lists, import images
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Read in the image annotation file.
ia = readtable(fullfile(localDir, 'stimuli-3TB-new', ['images-ssmri-wstars-new-wfreq-visit' num2str(prefs.day) '.csv']));

% Select only images for this run.
idx_thisrun = find(ia.run == prefs.run);
ia = ia(idx_thisrun, :);
clear idx_thisrun

% Randomize the order of the images.
nTrials = size(ia, 1);
randomizedTrials = randperm(nTrials); %randomize

% Insert 5 blank trials pseudo-randomly, so that the number of trials between
% blanks ranges from 9-14 trials with a sum limit
% so that it won't go over the full number of trials.
if prefs.run ~= 0
    while true
        r = randi([9 14], [1 5]);
        if (sum(r) < length(randomizedTrials))
            break;
        end
    end
    for k = 1:length(r)
        if k == 1
            idx_blank(k) = r(k);
        else
            idx_blank(k) = r(k) + idx_blank(k-1);
        end
    end
    clear k;
end

% Insert blank trials, coded here as 999.
if prefs.run ~= 0
    randomizedTrials2 = [randomizedTrials(1:idx_blank(1)-1) 999 ...
    randomizedTrials(idx_blank(1):idx_blank(2)-1) 999 ...
    randomizedTrials(idx_blank(2):idx_blank(3)-1) 999 ...
    randomizedTrials(idx_blank(3):idx_blank(4)-1) 999 ...
    randomizedTrials(idx_blank(4):idx_blank(5)-1) 999 ...
    randomizedTrials(idx_blank(5):end)];
else
    randomizedTrials2 = randomizedTrials;
end

% Identify the location of the images.
imageFolder = fullfile(localDir, 'stimuli-3TB-new', ['images' num2str(prefs.day)]);

% Import all images now to save time during experimental run.
trial = 0;
for t = randomizedTrials2

    trial = trial + 1;

    if t ~= 999 % if this is not a blank trial

        % Load image
        t_file = ia.image{t};

        % Some of the images are png and others are jpg. Keep for later, if needed.
        % if exist(fullfile(imageFolder,t_file)) ~= 0 % if there is a png file
        img{trial} = imread(fullfile(imageFolder,t_file));
        % else % if there is no png file, I know it is there as jpg
        %     t_file(end-2:end) = 'jpg';
        %     img{trial} = imread(fullfile(imageFolder,t_file));
        % end

    else

        img{trial} = {};

    end

    clear t_file;

end
clear trial;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Set up output file
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

outputfile = fopen([localDir '/output/sub-' prefs.subID '_ses-' num2str(prefs.day) '_task-street' ...
    '_run-' num2str(prefs.run) '_scanner-' prefs.scanner '_' datestr(now,'mm.dd.yyyy.HH.MM') '.txt'],'a');
fprintf(outputfile, 'subID\t day\t run\t stim_file\t trial_type\t label2\t sublabel1\t targetx\t targety\t aspectratio\t imagename\t trial\t onset\t off\t duration');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Set up screen and keyboard
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% If the screen resolution is 1024 x 768, prefs.w1Size should look like this:
prefs.w1Size = [0 0 1024 768]; %[0 0 460 300]; %[0 0 1440 900];

% % for debugging, turn this option on:
% prefs.w1Size = [0 0 460 300]; ShowCursor;

% Screen.
prefs.s0 = min(Screen('Screens')); % Find primary screen.

% Dimensions of window.
prefs.w1Width = prefs.w1Size(3);
prefs.w1Height = prefs.w1Size(4);

% Locatoin of center of window.
prefs.xcenter = prefs.w1Width/2;
prefs.ycenter = prefs.w1Height/2;

% Dimensions of stimulus presentation area.
prefs.rectForStim = [prefs.imgbuffer prefs.imgbuffer prefs.w1Width-prefs.imgbuffer prefs.w1Height-prefs.imgbuffer];

% Keyboard setup
KbName('UnifyKeyNames');
KbCheckList = [KbName('g'),KbName('ESCAPE')];
RestrictKeysForKbCheck(KbCheckList);

% Screen setup
clear screen
whichScreen = prefs.s0;
[window1, ~] = Screen('Openwindow',prefs.s0,prefs.backColor,prefs.w1Size,[],2);
slack = Screen('GetFlipInterval', window1)/2;
prefs.w1 = window1;
W=prefs.w1Width; % screen width
H=prefs.w1Height; % screen height
Screen(prefs.w1,'FillRect',prefs.backColor);
Screen('Flip', prefs.w1);
HideCursor([], prefs.w1);

% Screen priority
Priority(MaxPriority(prefs.w1));
Priority(2); % i.e., real time priority level (highest priority)

% Return width and height of the graphics window/screen in pixels
width = W;
height = H;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% SET CALIBRATION SCREEN COLOURS; PROVIDE WINDOW SIZE TO EYELINK HOST & DATAVIEWER; SET CALIBRATION PARAMETERS; CALIBRATE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Provide EyeLink with some defaults, which are returned in the structure "el".
el = EyelinkInitDefaults(window1);
% set calibration/validation/drift-check(or drift-correct) size as well as background and target colors.
% It is important that this background colour is similar to that of the stimuli to prevent large luminance-based
% pupil size changes (which can cause a drift in the eye movement data)
el.calibrationtargetsize = 3;% Outer target size as percentage of the screen
el.calibrationtargetwidth = 0.7;% Inner target size as percentage of the screen
el.backgroundcolour = [100 100 100];%[128 128 128];% RGB grey
el.calibrationtargetcolour = [255 255 255];%[0 0 0];% RGB black
% set "Camera Setup" instructions text colour so it is different from background colour
el.msgfontcolour = [0 0 0];% RGB black
% You must call this function to apply the changes made to the el structure above
EyelinkUpdateDefaults(el); % this line is important to apply changes above

% Set display coordinates for EyeLink data by entering left, top, right and bottom coordinates in screen pixels
Eyelink('Command','screen_pixel_coords = %ld %ld %ld %ld', 0, 0, width-1, height-1);
% Write DISPLAY_COORDS message to EDF file: sets display coordinates in DataViewer
% See DataViewer manual section: Protocol for EyeLink Data to Viewer Integration > Pre-trial Message Commands
Eyelink('Message', 'DISPLAY_COORDS %ld %ld %ld %ld', 0, 0, width-1, height-1);
% Set number of calibration/validation dots and spread: horizontal-only(H) or horizontal-vertical(HV) as H3, HV3, HV5, HV9 or HV13
Eyelink('Command', 'calibration_type = HV5'); % horizontal-vertical 9-points

% Optional: shrink the spread of the calibration/validation targets <x, y display proportion>
% if default outermost targets are not all visible in the bore.
% Default spread is 0.88, 0.83 (88% of the display horizontally and 83% vertically)
Eyelink('command', 'calibration_area_proportion 0.88 0.83');
Eyelink('command', 'validation_area_proportion 0.88 0.83');

%-------------------------------------------------------------------------------------------
% Optional: online drift correction. See section 3.11.2 in the EyeLink 1000 / EyeLink 1000 Plus User Manual
% Best to try not to use this unless needed
%   % Online drift correction to mouse-click position:
%     Eyelink('Command', 'driftcorrect_cr_disable = OFF');
%     Eyelink('Command', 'normal_click_dcorr = ON');
%
%   % Online drift correction to a fixed location:
%     Eyelink('Command', 'driftcorrect_cr_disable = OFF');
%     Eyelink('Command', 'online_dcorr_refposn 512,384'); %this the xy location of the fixation/target where you expect them to look for calibration
%     Eyelink('Command', 'online_dcorr_button = ON');
%     Eyelink('Command', 'normal_click_dcorr = OFF');
%-------------------------------------------------------------------------------------------

% Hide mouse cursor
% HideCursor;
% Start listening for keyboard input. Suppress keypresses to Matlab windows.
% ListenChar(-1);
Eyelink('Command', 'clear_screen 0'); % Clear Host PC display from any previus drawing
% Put EyeLink Host PC in Camera Setup mode for participant setup/calibration
EyelinkDoTrackerSetup(el);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Draw reference box/line and drift check and start recording eye-tracking data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Put tracker in idle/offline mode before Host PC feedback graphics drawing
Eyelink('SetOfflineMode');

% Optional: draw feedback graphics on Host PC interface
% See section 25.7 'Drawing Commands' in the EyeLink Programmers Guide manual
imgSize = [1024, 768]; % Use stimulus image size for drawing feedback graphics
Eyelink('Command', 'clear_screen 0'); %Clear Host screen to black
Eyelink('Command', 'draw_box %d %d %d %d 15', round(width/2-imgSize(1)/2), round(height/2-imgSize(2)/2), round(width/2+imgSize(1)/2), round(height/2+imgSize(2)/2));
Eyelink('Command', 'draw_line %d %d %d %d 15', width/2, 1, width/2, height); % left-top to right-bottom
Eyelink('Command', 'draw_line %d %d %d %d 15', 1, height/2, width, height/2);
% Supply the block number as a line of text on Host PC screen
Eyelink('Command', 'record_status_message "RUN %d"', prefs.run);

% Perform a drift check/correction. EyeLink 1000 and 1000 Plus perform a drift-check by default
% Optionally provide x y target location, otherwise target is presented at screen centre
% EyelinkDoDriftCorrection(el, round(width/2), round(height/2));%turning of because it will not let the experiment progress if not accurate, re:kids

% Write TRIALID message to EDF file: marks the start of first trial for DataViewer
% See DataViewer manual section: Protocol for EyeLink Data to Viewer Integration > Defining the Start and End of a Trial.
% TRIALID before StartRecording prevents extra initial trial in DataViewer when recording continuously
% trialCount = trialCount + 1; % Add 1 to trial counter
Eyelink('Message', 'TRIALID %d', 0);

% Put tracker in idle/offline mode before recording. Eyelink('SetOfflineMode') is recommended
% however if Eyelink('Command', 'set_idle_mode') is used allow 50ms before recording as shown in the commented code:
% Eyelink('Command', 'set_idle_mode');% Put tracker in idle/offline mode before recording
% WaitSecs(0.05); % Allow some time for transition
Eyelink('SetOfflineMode');% Put tracker in idle/offline mode before recording
Eyelink('StartRecording'); % Start tracker recording
WaitSecs(0.1); % Allow some time to record a few samples before presenting first stimulus

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Run experiment -- display Ready? screen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Orient to the Matlab command window for user/trigger input.
commandwindow;

% Initiate timestamp counter.
tscount = 0;

% Get ready.
Screen('FillRect', prefs.w1, prefs.backColor);
PresentCenteredText(prefs.w1,'Ready?', 60, prefs.foreColor, prefs.w1Size);
Screen('Flip',prefs.w1);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Run experiment -- go
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%Wait for RA to press g for "go"
while 1
    [keyIsDown,secs,keyCode] = KbCheck;
    if keyCode(KbName('g'))==1 %% Note, not the trigger key.
        break
    end
end
runstart = secs;
Eyelink('Message', 'Trigger.');

%% Show initial fixation cross, 14 seconds.
Screen('FillRect', prefs.w1, prefs.backColor);
draw_fixation(prefs.w1, [W/2 H/2], []);
Screen('Flip', prefs.w1);
Eyelink('Message', 'Beginning of initial fixation period.');

timekeys = {};
if prefs.run == 0
    pre = 5;
    post = 5;
else
    pre = 14;
    post = 16;
end
while (GetSecs - runstart) < pre

    [keyIsDown, secs, keyCode, deltaSecs] = KbCheck(-3); % all devices
    if keyIsDown
        % get name of the key and record it
        kn = KbName(keyCode);
        timekeys = [timekeys; {secs kn}];
        % check if ESCAPE was pressed
        if isequal(kn, 'ESCAPE')
            % clear all
            % close all
            %sca
            transferFile(dummymode, window1, height, status, edfFile);
            fprintf('Escape key detected. Exiting prematurely.\n')
            return;
        end

    end

end

Eyelink('Message', 'TRIAL_RESULT 0');

%% Run experimental trials
for t = 1:length(randomizedTrials2)

    % if i ~= 1 % If not first trial in a block
    % Write TRIALID message to EDF file: marks the start of a trial for DataViewer
    % TRIALID message for first trial in the block was written before recording began
    % See DataViewer manual section: Protocol for EyeLink Data to Viewer Integration > Defining the Start and End of a Trial
    % trialCount = trialCount + 1; % Add 1 to trial counter
    Eyelink('Message', 'TRIALID %d', t);
    % end

    if randomizedTrials2(t) ~= 999 % if this is not a blank trial

        % Load image
        t_file = ia.image{randomizedTrials2(t)};
        td_imageDisplay = Screen('MakeTexture', prefs.w1, img{t});

    end

    % Show fixation cross.
    Screen('FillRect', prefs.w1, prefs.backColor);
    draw_fixation(prefs.w1, [W/2 H/2], []);
    fixationstart = Screen('Flip', prefs.w1);
    Eyelink('Message', 'Beginning of fixation period within a trial.');

    % Keep start of trials time stamp.
    if t == 1; startoftrials = fixationstart; end

    % Trial start timestamp
    tscount = tscount + 1;
    timestamp(tscount) = fixationstart;

    % Keep the fixation for this trial visible for the length of the fixation duration.
    while (GetSecs - runstart) < (pre + fixationduration*t + imagonduration*(t-1))

        [keyIsDown,secs,keyCode] = KbCheck;
        pressedKeys = find(keyCode);

        % ESC key quits the experiment
        if keyCode(KbName('ESCAPE')) == 1
            % clear all
            % close all
            %sca
            transferFile(dummymode, window1, height, status, edfFile);
            return;
        end

    end

    if randomizedTrials2(t) ~= 999 % if this is not a blank trial

        % Show the image for this trial at 1 second from start of trial.
        Screen('FillRect', prefs.w1, prefs.backColor);
        Screen('DrawTexture', prefs.w1, td_imageDisplay, [], prefs.rectForStim);
        % draw_fixation(prefs.w1, [W/2 H/2], []);%central fixation on image
        startimg = Screen('Flip', prefs.w1); % Start of image presentation
        Eyelink('Message', 'Beginning of image period within a trial.');

        % Write !V IMGLOAD message to EDF file: creates backdrop image for DataViewer
        % See DataViewer manual section: Protocol for EyeLink Data to Viewer Integration > Image Commands
        % Eyelink('Message', '!V IMGLOAD CENTER %s %d %d', t_file, width/2, height/2);

    elseif randomizedTrials2(t) == 999 % if this is a blank trial

        Eyelink('Message', 'Beginning of blank period within a trial.');

        Screen('FillRect', prefs.w1, prefs.backColor);
        draw_fixation(prefs.w1, [W/2 H/2], []);%central fixation on background
        startimg = Screen('Flip', prefs.w1); % Start of image presentation

    end

    % Keep the start time of the image presentation.
    ontime = startimg-startoftrials;

    % Keep the image for this trial visible for the trial length (i.e., fixationduration + imageduration).
    while (GetSecs - runstart) < (pre + fixationduration*t + imagonduration*(t))

        [keyIsDown,secs,keyCode] = KbCheck;
        pressedKeys = find(keyCode);

        % ESC key quits the experiment
        if keyCode(KbName('ESCAPE')) == 1
            % clear all
            % close all
            %sca
            transferFile(dummymode, window1, height, status, edfFile);
            return;
        end
    end

    % Keep the off time of the images presentation and the duration.
    offtime = GetSecs-startoftrials;
    durationtime = offtime-ontime;

    % Write !V TRIAL_VAR messages to EDF file: creates trial variables in DataViewer
    % See DataViewer manual section: Protocol for EyeLink Data to Viewer Integration > Trial Message Commands
    Eyelink('Message', '!V TRIAL_VAR image %s', t_file);
    Eyelink('Message', '!V TRIAL_VAR ontime %s', num2str(ontime));
    Eyelink('Message', '!V TRIAL_VAR offtime %s', num2str(offtime));
    Eyelink('Message', '!V TRIAL_VAR trialduration %s', num2str(durationtime));

    % Write TRIAL_RESULT message to EDF file: marks the end of a trial for DataViewer
    % See DataViewer manual section: Protocol for EyeLink Data to Viewer Integration > Defining the Start and End of a Trial
    Eyelink('Message', 'TRIAL_RESULT 0');
    WaitSecs(0.01); % Allow some time before ending the trial

    % Save results to file
    if randomizedTrials2(t) ~= 999 % if this is not a blank tria
        fprintf(outputfile, '\n%s\t %d\t %d\t %s\t %s\t %s\t %s\t %d\t %d\t %d\t %s\t %d\t %1.2f\t %1.2f\t %1.2f\t', ...
            prefs.subID, prefs.day, prefs.run, [imageFolder '/' t_file], ia.label1{randomizedTrials2(t)}, ia.label2{randomizedTrials2(t)}, ia.sublabel1{randomizedTrials2(t)}, ...
            ia.x(randomizedTrials2(t)), ia.y(randomizedTrials2(t)), ia.aspectratio(randomizedTrials2(t)), t_file, t, ontime+pre, offtime+pre, durationtime);
    else
        fprintf(outputfile, '\n%s\t %d\t %d\t %s\t %s\t %s\t %s\t %s\t %d\t %d\t %d\t %d\t %1.2f\t %1.2f\t %1.2f\t', ...
            prefs.subID, prefs.day, prefs.run, [imageFolder '/' t_file], 'blank', 'blank', 'blank', 'blank', W/2, H/2, 0, t, ontime+pre, offtime+pre, durationtime);
    end

end

%% Show final fixation cross, 16 seconds.
Screen('FillRect', prefs.w1, prefs.backColor);
draw_fixation(prefs.w1, [W/2 H/2], []);
fixationstart = Screen('Flip', prefs.w1);

% Trial final fixation start timestamp
tscount = tscount + 1;
Eyelink('Message', 'TRIALID %d', tscount);
Eyelink('Message', 'Beginning of final fixation.');

timestamp(tscount) = fixationstart;

while (GetSecs - runstart) < (pre + fixationduration*t + imagonduration*(t) + post)

    [keyIsDown,secs,keyCode] = KbCheck;
    pressedKeys = find(keyCode);

    % ESC key quits the experiment
    if keyCode(KbName('ESCAPE')) == 1
        % clear all
        % close all
        %sca
        transferFile(dummymode, window1, height, status, edfFile);
        return;
    end

end

Eyelink('Message', 'TRIAL_RESULT 0');
Eyelink('StopRecording'); % Stop tracker recording

%% Close down and save.

% Blank screen
Screen(prefs.w1, 'FillRect', prefs.backColor);
tscount = tscount + 1;
timestamp(tscount) = Screen('Flip', prefs.w1); %run end time
%toc

% End of run, Great job.
Screen('FillRect', prefs.w1, prefs.backColor);
PresentCenteredText(prefs.w1, 'Great job!', 60, prefs.foreColor, prefs.w1Size);
Screen('Flip', prefs.w1);

% Wait for RA to close out from final "Great job!" screen.
waitForTrigger2('g');

% Save timing file.
save(fullfile([localDir '/output/sub-' prefs.subID '_ses-' num2str(prefs.day) '_task-street' ...
    '_run-' num2str(prefs.run) '_scanner-' prefs.scanner '_' datestr(now,'mm.dd.yyyy.HH.MM') '.mat']))

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% CLOSE EDF FILE. TRANSFER EDF COPY TO DISPLAY PC. CLOSE EYELINK CONNECTION. FINISH UP
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Put tracker in idle/offline mode before closing file. Eyelink('SetOfflineMode') is recommended.
% However if Eyelink('Command', 'set_idle_mode') is used, allow 50ms before closing the file as shown in the commented code:
% Eyelink('Command', 'set_idle_mode');% Put tracker in idle/offline mode
% WaitSecs(0.05); % Allow some time for transition
Eyelink('SetOfflineMode'); % Put tracker in idle/offline mode
Eyelink('Command', 'clear_screen 0'); % Clear Host PC backdrop graphics at the end of the experiment
WaitSecs(0.5); % Allow some time before closing and transferring file
Eyelink('CloseFile'); % Close EDF file on Host PC

transferFile(dummymode, window1, height, status, edfFile);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% End the experiment
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
RestrictKeysForKbCheck([]);
fclose(outputfile);
% Screen(prefs.w1,'Close');
close all; clc; ShowCursor;
sca;
return

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Functions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
function transferFile(dummymode, window1, height, status, edfFile)

global edfFile height status window1;

% Transfer a copy of the EDF file to Display PC
% Function for transferring copy of EDF file to the experiment folder on Display PC.
% Allows for optional destination path which is different from experiment folder
try
    if dummymode == 0 % If connected to EyeLink
        % Show 'Receiving data file...' text until file transfer is complete
        Screen('FillRect', window1, [100 100 100]); % Prepare background on backbuffer
        Screen('DrawText', window1, 'Receiving data file...', 5, height-35, 0); % Prepare text
        Screen('Flip', window1); % Present text
        fprintf('Receiving data file ''%s.edf''\n', edfFile); % Print some text in Matlab's Command Window

        % Transfer EDF file to Host PC
        % [status =] Eyelink('ReceiveFile',['src'], ['dest'], ['dest_is_path'])
        status = Eyelink('ReceiveFile');

        % Check if EDF file has been transferred successfully and print file size in Matlab's Command Window
        if status > 0
            fprintf('EDF file size: %.1f KB\n', status/1024); % Divide file size by 1024 to convert bytes to KB
        end
        % Print transferred EDF file path in Matlab's Command Window
        fprintf('Data file ''%s.edf'' can be found in ''%s''\n', edfFile, pwd);
    else
        fprintf('No EDF file saved in Dummy mode\n');
    end
    cleanup;
catch % Catch a file-transfer error and print some text in Matlab's Command Window
    fprintf('Problem receiving data file ''%s''\n', edfFile);
    cleanup;
    psychrethrow(psychlasterror);
end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Cleanup function used throughout the script above
function cleanup
try
    Screen('CloseAll'); % Close window if it is open
end
Eyelink('Shutdown'); % Close EyeLink connection
% ListenChar(0); % Restore keyboard output to Matlab
ShowCursor; % Restore mouse cursor
if ~IsOctave; commandwindow; end % Bring Command Window to front
end

