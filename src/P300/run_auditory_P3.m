%Load study
[STUDY ALLEEG] = pop_loadstudy('filename', 'auditory-P300.study', ...
                                'filepath', '/store/data/P300/derivatives');
CURRENTSTUDY = 1; 
EEG = ALLEEG; 
CURRENTSET = [1:length(EEG)];

%Rewrite events
for dset = 1:length(EEG)
    tmp_idx = [];
    for  e = 1:length(EEG(dset).event)
        if strcmp(EEG(dset).event(e).type, 'oddball') || strcmp(EEG(dset).event(e).type, 'noise_with_reponse') || strcmp(EEG(dset).event(e).type, 'noise')
            tmp_idx = [tmp_idx e];
            if strcmp(EEG(dset).event(e).type, 'noise_with_reponse')
                tmp_idx = [tmp_idx e+1];
            end
        elseif strcmp(EEG(dset).event(e).type, 'oddball_with_reponse')
            EEG(dset).event(e).trial_type = 'stimulus_with_response';
        end
    end
    EEG(dset).event(tmp_idx) = [];
    EEG(dset).event = renamefield(EEG(dset).event, 'type', 'trialtype');
    EEG(dset).event = renamefield(EEG(dset).event, 'trial_type', 'type');
    EEG(dset).event = renamefield(EEG(dset).event, 'response_time', 'rt');
end

%% Throw out datasets with too many non-response oddballs
x = NaN(length(EEG),1) ; 
for i = 1:length(EEG); y=0;
    for j = 1:length(EEG(i).event)
        if strcmp(EEG(i).event(j).trialtype, 'oddball_with_reponse')
            y = y+1; 
        end
    end 
    x(i) = y; 
end
idx = find(x < 70);
EEG(idx) = [];
    %%
for dset = 1:length(EEG) 
    EEGN = EEG(dset);
    for formula = {'y~1'
            'y~1+rt'
            'y~1+spl(rt,4)'
            ...%'y~1+cat(trialtype)+spl(rtDis,4) + spl(rtTar,4)'
            }'
        %for k = 1:2
        EEGN = uf_designmat(EEGN,'eventtypes',{'stimulus_with_response', 'stimulus', 'response'},'formula',...
            {formula{1}, 'y~1', 'y~1'});
       
        EEGN = uf_timeexpandDesignmat(EEGN,'timelimits',[-1 1]);
        EEGN = uf_continuousArtifactExclude(EEGN,'winrej',EEGN.uf_winrej);
        
        EEGN = uf_glmfit(EEGN,'channel',31); % Channel Pz
        
        EEGe = uf_epoch(EEGN,'timelimits',[-1 1]);
        predictAt = {{'response_time',[350 400 450 500 550 600]}};
        EEGe = uf_glmfit_nodc(EEGe,'method','matlab');
        
        ufresult = uf_condense(EEGe);
        ufresult_a = uf_addmarginal(uf_predictContinuous(ufresult,'predictAt',predictAt));
  
%         EEG = uf_glmfit(EEG,'channel',21,'method','glmnet','glmnetalpha',0);
%         EEGe = uf_glmfit_nodc(EEGe,'method','glmnet','glmnetalpha',0,'channel',21);
        
        filename = sprintf('sub-%i_formula-%s.mat',dset,formula{1});
        if ~exist(fullfile('/store/projects/unfold_duration/local','auditory_p3'),'dir')
            mkdir(fullfile('/store/projects/unfold_duration/local','auditory_p3'))
        end
        save(fullfile('/store/projects/unfold_duration/local','auditory_p3',filename),'ufresult_a')
    end
end
