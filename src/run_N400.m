%% Script running on custom-preprocessed ERP-Core-preprocessed data
% re-filters
% auto clean via ASR - could be removed because it was run in preprocess_p3
% and saved to EEG.reject.rejmanual 
% run unfold


ufresult_all = [];
ufresult_all_a = [];
badS = [];

for sub = [6 9]%:40
    %%
    if sub < 10
        s = ['0' num2str(sub)];
    else
        s = num2str(sub);
    end
    
    % Load data
    filename = ['/store/data/erp-core/derivatives/autopreprocess/sub-0' s '/ses-N400/eeg/sub-0' s '_ses-N400_task-N400_eeg.mat'];
    try
        mydata = load('-mat', filename);
    catch
        badS = [badS sub];
        continue
    end
    EEG = mydata.EEG;
    EEG.data = double(EEG.data);
    EEG = pop_resample(EEG, 512);
    
    % Check for rejection
    winrej = uf_continuousArtifactDetectASR(EEG);
    
    % rename to be used in EEG
    EEG = recode_N400(EEG);
%     badIx = cellfun(@(x)isnan(x),{EEG.event.rt});
%     EEG.event(badIx) = [];
    %EEG = pop_reref(EEG);
    %%
    for formula = {'y~1+cat(eventtype)'
            'y~1+cat(eventtype)+rt'
            'y~1+cat(eventtype)+spl(rt,4)'
            ...%'y~1+cat(trialtype)+spl(rtDis,4) + spl(rtTar,4)'
            }'
        %for k = 1:2
        EEG = uf_designmat(EEG,'eventtypes',{'stimulus', 'response'},'formula',...
            {formula{1}, 'y~1'});
       
        EEG = uf_timeexpandDesignmat(EEG,'timelimits',[-1 1]);
        EEG = uf_continuousArtifactExclude(EEG,'winrej',winrej);
        
        EEG = uf_glmfit(EEG,'channel',21);
        
        EEGe = uf_epoch(EEG,'timelimits',[-1 1]);
        predictAt = {{'rt',[200 250 300 350 400 450]}};
        EEGe = uf_glmfit_nodc(EEGe,'method','matlab');
        
        ufresult = uf_condense(EEGe);
        ufresult_a = uf_addmarginal(uf_predictContinuous(ufresult,'predictAt',predictAt));
  
%         EEG = uf_glmfit(EEG,'channel',21,'method','glmnet','glmnetalpha',0);
%         EEGe = uf_glmfit_nodc(EEGe,'method','glmnet','glmnetalpha',0,'channel',21);
        
        filename = sprintf('sub-%i_formula-%s.mat',sub,formula{1});
        if ~exist(fullfile('local','N400'),'dir')
            mkdir(fullfile('local','N400'))
        end
        save(fullfile('local','N400',filename),'ufresult_a')
        
    end
    
end

