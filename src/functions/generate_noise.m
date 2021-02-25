
% Function to generate noise based on real datasets; from ERP-Core P3
% datasets.

% First get path to P3 raw data; is in BIDS format
core_path = dir(fullfile('/store/data','erp-core','sub-*'));

% Subjects
sub = 1:size(core_path, 1);

% Init noise matrix
% noise = zeros(1,1,length(sub));

% Run through subjects; preprocess
for i = sub
    % Load data
    filename_csv= ['/store/projects/skukies/unfold_duration/local/P3_clean/csv/' num2str(sub) '_P3_shifted_ds_reref_ucbip_hpfilt_ica_weighted_clean.set.csv'];
    
    EEG = pop_loadset([core_path(i).folder '/' core_path(i).name 'ses-P3/eeg/' core_path(i).name '_ses-P3_task-P3_eeg.set']);
    csv = readtable(filename_csv);
    
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
    
    % Epoch
    EEG = pop_epoch( EEG, {  }, [-0.2           1], 'epochinfo', 'yes');
    
    % Baseline
    EEG = pop_rmbase( EEG, [-200 0] ,[]);
    
    % Artefact detection, erplab peak-to-peak moving window
    EEG  = pop_artmwppth( EEG , 'Channel',  1:33, 'Flag',  1, 'Threshold',  100, 'Twindow', [ -200 996], 'Windowsize',  200, 'Windowstep',  100 );
    
    
end