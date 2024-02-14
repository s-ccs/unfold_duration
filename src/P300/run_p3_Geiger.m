%% Script running on custom-preprocessed ERP-Core-preprocessed data
% re-filters
% and saved to EEG.reject.rejmanual
% run unfold


ufresult_all = [];
ufresult_all_a = [];
badSubject = [];

% parpool(10)
for sub = 1:40
    %%

    if sub < 10
%         filename = ['/store/data/MSc_EventDuration/derivatives/preprocessed_Oddball/sub-00' num2str(sub) '/eeg/sub-00' num2str(sub) '_ses-001_task-Oddball_run-001_eeg.set'];
        filename = ['/store/data/MSc_EventDuration/derivatives/RS_replication/preprocessed/sub-00' num2str(sub) '/eeg/sub-00' num2str(sub) '_ses-001_task-Oddball_run-001_eeg.set']; % New data/ filter bug fixed
    else
%         filename = ['/store/data/MSc_EventDuration/derivatives/preprocessed_Oddball/sub-0' num2str(sub) '/eeg/sub-0' num2str(sub) '_ses-001_task-Oddball_run-001_eeg.set'];
        filename = ['/store/data/MSc_EventDuration/derivatives/RS_replication/preprocessed/sub-0' num2str(sub) '/eeg/sub-0' num2str(sub) '_ses-001_task-Oddball_run-001_eeg.set']; % New data/ filter bug fixed

    end
    
    try
        EEG= pop_loadset(filename);
    catch e
        warning(e.message)
%         badSubject = unique([badSubject sub]);
        continue
    end
     
    EEG = pop_eegfiltnew(EEG,0.5,[]);
    
    EEG.uf_winrej = uf_continuousArtifactDetectASR(EEG,'channel',find({EEG.chanlocs.type} == "EEG"),'cutoff',30);

    
    badIx = cellfun(@(x)isnan(x),{EEG.event.response_time});
    EEG.event(badIx) = [];
    %EEG = pop_reref(EEG);
    %% run for different conditions
    cond_folder = {'p3_geiger_rsRep', 'p3_button_geiger_rsRep', 'p3_Stim+Button_geiger_rsRep'};
    for folder = cond_folder
        for formula = {'y~1+cat(condition)'
                'y~1+cat(condition)+response_time'
                'y~1+cat(condition)+spl(response_time,4)'
                ...%'y~1+cat(trialtype)+spl(rtDis,4) + spl(rtTar,4)'
                }'
            %for k = 1:2
            
            switch folder{1}
                % Model RT in respect to both stimulus and button press
                case cond_folder{3}
                    EEG = uf_designmat(EEG,'eventtypes',{'stimOnset','buttonpress'},'formula',...
                        {formula{1}, formula{1}});
                    
                    % Model RT in respect to the button press
                case cond_folder{2}
                    EEG = uf_designmat(EEG,'eventtypes',{'stimOnset','buttonpress'},'formula',...
                        {'y~1+cat(condition)', formula{1}});
                    
                    % Model RT in respect to Stimulus
                case cond_folder{1}
                    EEG = uf_designmat(EEG,'eventtypes',{'stimOnset','buttonpress'},'formula',...
                        {formula{1},'y~1+cat(condition)'});
            end
            
            EEG = uf_timeexpandDesignmat(EEG,'timelimits',[-1 1]);
            EEG = uf_continuousArtifactExclude(EEG,'winrej',EEG.uf_winrej);
%             commented out for now cause no asr was done
            
            EEG = uf_glmfit(EEG);
            
            EEGe = uf_epoch(EEG,'timelimits',[-1 1]);
            predictAt = {{'response_time',[200 250 300 350 400 450]}};
            EEGe = uf_glmfit_nodc(EEGe,'method','matlab');
            
            ufresult = uf_condense(EEGe);
            ufresult_a = uf_addmarginal(uf_predictContinuous(ufresult,'predictAt',predictAt));
            
            %         EEG = uf_glmfit(EEG,'channel',21,'method','glmnet','glmnetalpha',0);
            %         EEGe = uf_glmfit_nodc(EEGe,'method','glmnet','glmnetalpha',0,'channel',21);
            
            filename = sprintf('sub-%i_formula-%s.mat',sub,formula{1});
            if ~exist(fullfile('/store/projects/unfold_duration/local', folder{1}),'dir')
                mkdir(fullfile('/store/projects/unfold_duration/local', folder{1}))
            end
            save(fullfile('/store/projects/unfold_duration/local', folder{1}, filename),'ufresult_a')
            
        end % end formula loop
    end % condition loop
end % End subject loop

% for bSet = betaSetName
%     ufresult_all.(bSet{1}) = ufresult_all.(bSet{1})(:,:,:,setdiff(1:40,badSubject));
%     ufresult_all_a.(bSet{1}) = ufresult_all_a.(bSet{1})(:,:,:,setdiff(1:40,badSubject));
% end
% %%

%% Do some plotting to inspect the data

for sub = 5%:40
    %%

    if sub < 10
%         filename = ['/store/data/MSc_EventDuration/derivatives/preprocessed_Oddball/sub-00' num2str(sub) '/eeg/sub-00' num2str(sub) '_ses-001_task-Oddball_run-001_eeg.set'];
        filename = ['/store/data/MSc_EventDuration/derivatives/RS_replication/preprocessed/sub-00' num2str(sub) '/eeg/sub-00' num2str(sub) '_ses-001_task-Oddball_run-001_eeg.set']; % New data/ filter bug fixed
    else
%         filename = ['/store/data/MSc_EventDuration/derivatives/preprocessed_Oddball/sub-0' num2str(sub) '/eeg/sub-0' num2str(sub) '_ses-001_task-Oddball_run-001_eeg.set'];
        filename = ['/store/data/MSc_EventDuration/derivatives/RS_replication/preprocessed/sub-0' num2str(sub) '/eeg/sub-0' num2str(sub) '_ses-001_task-Oddball_run-001_eeg.set']; % New data/ filter bug fixed

    end
    
    try
        EEG= pop_loadset(filename);
    catch e
        warning(e.message)
%         badSubject = unique([badSubject sub]);
        continue
    end
     
    EEG = pop_eegfiltnew(EEG,0.5,[]);
   
    eegplot(EEG.data, 'srate', EEG.srate, 'events', EEG.event)
    
end