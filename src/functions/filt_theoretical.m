function sig = filt_theoretical(sig, filter)
% Function to filter the theoretical shape during simulations of Unfold
% duration Project. Applies eegfilt_new with low pass as given by [filter]
%
% As the theoretical shape itself is too short for a low-pass filter the
% signal will be zero padded and then cut back to its original length.

% Get original sig length
l = size(sig, 2);
size_3D = size(sig, 3);

%Zero Pad
sig = [zeros(1, l, size_3D) sig zeros(1, l, size_3D)];

% EEG struct needed for filtering
sigEEG = eeg_emptyset();
sigEEG.srate = 100; %Hz
sigEEG.pnts  = length(sig);
sigEEG.data = sig;
sigEEG = eeg_checkset(sigEEG);

% Filter
sigEEG.data(isnan(sigEEG.data(:))) = 0;
sigEEG = pop_eegfiltnew(sigEEG,filter,[]);

% Get back original signal length
sig = sigEEG.data(1, l+1:end-l, :);

return