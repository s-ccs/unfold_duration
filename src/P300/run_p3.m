%% Script running on custom-preprocessed ERP-Core-preprocessed data
% re-filters
% auto clean via ASR - could be removed because it was run in preprocess_p3
% and saved to EEG.reject.rejmanual
% run unfold


ufresult_all = [];
ufresult_all_a = [];
badSubject = [];

for sub = 1:40
    %%
    %     filename = ['C:/Users/behinger/Downloads/P3_clean/' num2str(sub) '_P3_shifted_ds_reref_ucbip_hpfilt_ica_weighted_clean.set'];
    %     filename_csv= ['C:/Users/behinger/Downloads/P3_clean/' num2str(sub) '_P3_shifted_ds_reref_ucbip_hpfilt_ica_weighted_clean.set.csv'];
    filename = ['/store/projects/unfold_duration/local/P3_clean/' num2str(sub) '_P3_shifted_ds_reref_ucbip_hpfilt_ica_weighted_clean.set'];
    filename_csv= ['/store/projects/unfold_duration/local/P3_clean/csv/' num2str(sub) '_P3_shifted_ds_reref_ucbip_hpfilt_ica_weighted_clean.set.csv'];
    try
        csv = readtable(filename_csv);
    catch e
        warning(e.message)
        badSubject = unique([badSubject sub]);
        continue
    end
    
    
    EEG= pop_loadset(filename);
        
    EEG = pop_eegfiltnew(EEG,0.5,[]);
    
    winrej = uf_continuousArtifactDetectASR(EEG);
    
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
    %EEG = pop_reref(EEG);
    %% run for different conditions
    cond_folder = {'p3', 'p3_button', 'p3_Stim+Button'};
    for folder = cond_folder
        for formula = {'y~1+cat(trialtype)'
                'y~1+cat(trialtype)+rt'
                'y~1+cat(trialtype)+spl(rt,4)'
                ...%'y~1+cat(trialtype)+spl(rtDis,4) + spl(rtTar,4)'
                }'
            %for k = 1:2
            
            switch folder{1}
                % Model RT in respect to both stimulus and button press
                case 'p3_Stim+Button'
                    EEG = uf_designmat(EEG,'eventtypes',{'stimulus','button'},'formula',...
                        {formula{1}, formula{1}});
                    
                    % Model RT in respect to the button press
                case 'p3_button'
                    EEG = uf_designmat(EEG,'eventtypes',{'stimulus','button'},'formula',...
                        {'y~1+cat(trialtype)', formula{1}});
                    
                    % Model RT in respect to Stimulus
                case 'p3'
                    EEG = uf_designmat(EEG,'eventtypes',{'stimulus','button'},'formula',...
                        {formula{1},'y~1+cat(trialtype)'});
            end
            
            EEG = uf_timeexpandDesignmat(EEG,'timelimits',[-1 1]);
            EEG = uf_continuousArtifactExclude(EEG,'winrej',winrej);
            
            EEG = uf_glmfit(EEG);
            
            EEGe = uf_epoch(EEG,'timelimits',[-1 1]);
            predictAt = {{'rt',[200 250 300 350 400 450]}};
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
