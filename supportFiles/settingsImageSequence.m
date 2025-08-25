%% Settings for image sequence experiment
% Change these to suit your experiment!

% Path to text file input (optional; for no text input set to 'none')
% textFile = 'searchPrompt.txt';
textFile = 'none';

% Response keys (optional; for no subject response use empty list)
responseKeys = {'1', '2', '3', '4', '5'}; % 'f = no' 'j = yes'
%responseKeys = {};

% Number of trials to show before a break (for no breaks, choose a number
% greater than the number of trials in your experiment)
breakAfterTrials = 100;

% Background color: choose a number from 0 (black) to 255 (white)
backgroundColor = 255;

% Text color: choose a number from 0 (black) to 255 (white)
textColor = 0;

% Image format of the image files in this experiment (eg, jpg, gif, png, bmp)
% imageFormat = 'bmp';

% How long to wait (in seconds) for subject response before the trial times out
trialduration = 4;

% How long to pause in between trials (if 0, the experiment will wait for
% the subject to press a key before every trial)
timeBetweenTrials = 0;

% How long to show (in seconds) a symbol in each trial (must be less than
% the trialduration)
imgdisplayduration = 3.00;

% Length of fixation in seconds
fixationduration = 1.5;

