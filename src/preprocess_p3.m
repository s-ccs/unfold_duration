
for sub = 1:40
%%
    filename = ['C:/Users/behinger/Downloads/P3_clean/' num2str(sub) '_P3_shifted_ds_reref_ucbip_hpfilt_ica_weighted.set'];
    EEG_org = pop_loadset(filename);


    % detect & reject bad segments to improve ICLabel features
    EEG_org = pop_select(EEG_org,'nochannel',[ 32 33]);  % delete HEOG, they are not referenced
    evalc(sprintf("EEG_clean = clean_asr(EEG_org,%f,[],[],[],[],[],[],[],0);",30)); % last argument activates riemann
    sample_mask = ~(sum(abs(EEG_org.data-EEG_clean.data),1) < 1e-10);
    % build winrej
    winrej = reshape(find(diff([false sample_mask false])),2,[])';
    winrej(:,2) = winrej(:,2)-1;
    EEG_clean = eeg_eegrej(EEG_clean,winrej);
    EEG_clean = pop_iclabel(EEG_clean,'Default');
    EEG_clean = pop_icflag(EEG_clean, [0 0;.9 1; 0.9 1;0.9 1;0.9 1; 0.9 1; 0 0]);

    EEG = pop_subcomp(EEG_org,find(EEG_clean.reject.gcompreject),0);
    EEG = eeg_checkset(EEG);
    
    % remove channels
    EEG = clean_channels(EEG);
    % interpolate
    EEG = pop_interp(EEG,EEG_org.chanlocs,'spherical');
    % find bad segments in IC cleaned data
    winrej_asr = uf_continuousArtifactDetectASR(EEG,'channel',1:size(EEG.data,1)-4);
    EEG.reject.rejmanual = winrej_asr;

    pop_saveset(EEG,[filename(1:end-4) '_clean.set'])
end
