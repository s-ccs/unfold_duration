function [Noise, s, maxE] = generate_noise(srate, eTime)
% Function to generate noise based on real datasets; from ERP-Core P3
% datasets.


% First get path to P3 raw data; is in BIDS format
core_path = dir(fullfile('/store/data','erp-core','sub-*'));

% Subjects
sub = 1:size(core_path, 1);

% Run through subjects; preprocess
for i = sub
    % Load data
    filename_csv= ['/store/projects/unfold_duration/local/P3_clean/csv/' num2str(i) '_P3_shifted_ds_reref_ucbip_hpfilt_ica_weighted_clean.set.csv'];
    
    EEG = pop_loadset([core_path(i).folder '/' core_path(i).name '/ses-P3/eeg/' core_path(i).name '_ses-P3_task-P3_eeg.set']);
    try
        csv = readtable(filename_csv);
    catch
        continue
    end
    % Delete EOG channels
    EEG = pop_select( EEG, 'nochannel',{'HEOG_left','HEOG_right','VEOG_lower'});
    
    % Reref
    EEG = pop_reref(EEG,[]);
    
    % Resample
    EEG = pop_resample(EEG, srate);
    
    % High-pass
    EEG = pop_eegfiltnew(EEG, 'locutoff',0.1);
    
    % Low-passfilt
    EEG = pop_eegfiltnew(EEG, 'hicutoff',30);
    
    % rename to be used in EEG
    EEG.event = table2struct(csv);
    for e  = 1:length(EEG.event)
        EEG.event(e).type = EEG.event(e).eventtype;
        
        % manual interaction
        if EEG.event(e).trialtype == "target"
            EEG.event(e).rtDis = 0;
            EEG.event(e).rtTar = EEG.event(e).rt;
        elseif EEG.event(e).trialtype == "distractor"
            EEG.event(e).rtDis = EEG.event(e).rt;
            EEG.event(e).rtTar = 0;
        end
        
    end
    badIx = cellfun(@(x)isnan(x),{EEG.event.rt});
    EEG.event(badIx) = [];
    
    % Make Eventlist for ERPLAB artefact reject
    EEG  = pop_creabasiceventlist( EEG , 'AlphanumericCleaning', 'on', 'BoundaryNumeric', { -99 }, 'BoundaryString', { 'boundary' } );
%     EEG = basicrap(EEG, [1:30], 100);
%     EEG = basicrap(EEG, chanArray, ampth, windowms, stepms, firstdet, fcutoff, forder)
    % Epoch
    EEG = pop_epoch( EEG, {  }, eTime, 'epochinfo', 'yes');
    
    % Baseline
    EEG = pop_rmbase( EEG, [-200 0] ,[]);
    
    % Artefact detection, erplab peak-to-peak moving window
    EEG  = pop_artmwppth( EEG , 'Channel',  1:30, 'Flag',  1, 'Threshold',  100, 'Twindow', [ -200 996], 'Windowsize',  200, 'Windowstep',  100 );
 
    % Reject artefacts
    ix_reject = find(EEG.reject.rejmanual);
    EEGN = EEG;
    EEGN.data(:,:,ix_reject) = [];
    EEGN.event(ix_reject) = [];
    
    % Make Grand averages
    tmp_type = extractfield(EEGN.event, 'eventtype');
    tmp_trial = extractfield(EEGN.event, 'trialtype');
    idx_avg_target = find(tmp_type == "stimulus" & tmp_trial == "target");
    idx_avg_distractor = find(tmp_type == "stimulus" & tmp_trial == "distractor");
    idx_avg_resp_target = find(tmp_type == "button" & tmp_trial == "target");
    idx_avg_resp_distractor = find(tmp_type == "button" & tmp_trial == "distractor");
    
    tmp_epoch = extractfield(EEGN.event, 'epoch');
    noise_target = EEG.data(:,:,tmp_epoch(idx_avg_target)) - mean(EEG.data(:,:,tmp_epoch(idx_avg_target)),3);
    noise_distractor = EEG.data(:,:,tmp_epoch(idx_avg_distractor)) - mean(EEG.data(:,:,tmp_epoch(idx_avg_distractor)),3);
    noise_resp_target = EEG.data(:,:,tmp_epoch(idx_avg_resp_target)) - mean(EEG.data(:,:,tmp_epoch(idx_avg_resp_target)),3);
    noise_resp_distractor = EEG.data(:,:,tmp_epoch(idx_avg_resp_distractor)) - mean(EEG.data(:,:,tmp_epoch(idx_avg_resp_distractor)),3);
    
    tmp_Noise = cat(3, noise_target, noise_distractor, noise_resp_target, noise_resp_distractor);
    
    Noise(i) = {tmp_Noise}; 
end

% Delete empty cells because of no csv file 
idx_empty = find(cellfun('isempty',Noise));
Noise(idx_empty) = [];

% Get maximum number of epochs
s = cellfun('size',Noise,3);
maxE = max(s);