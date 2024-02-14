function Noise = resting_state_noise(srate)
% Function to load resting state data into memory to be used as noise
% during the simulations.

% Path to data and list of subject folders
path = "/store/data/non-bids/non-bids_anesthesia_resting_state/eyes_closed/derivatives/";
list = dir(fullfile(path, "*.set"));

Noise = {};
% Run through subjects
for s = 1:length(list)  
   % Load file
   EEG = pop_loadset('filepath',list(s).folder, 'filename',list(s).name);
   EEG = pop_resample(EEG, srate);
   Noise(s) = {EEG.data};

end