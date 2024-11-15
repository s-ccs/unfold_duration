% Run a bunch of simulations (~20GB space if all combinations are used)

%% Initialize a bunch of Options
rng(1) % same seed
ufresult_all = {};
N_event = 500; % max number of events
emptyEEG = eeg_emptyset();
emptyEEG.srate = 100; %Hz
emptyEEG.pnts  = emptyEEG.srate*500; % total length in samples
T_event   = emptyEEG.srate*1.5; % total length of event-signal in samples
harmonize = 1; % Harmonize shape of Kernel? 1 = Yes; 0 = No
saveFolder = "20240618_sim_realNoise_HanningShapes_filtered_blockdesign"; % Folder to save in; Final used one: sim_realNoise_HanningShapes
filter = 0.05; % final 0.05

%% Check if only noise condition
if regexp(saveFolder', regexptranslate('wildcard', '**onlyNoise'))
    signal_strength = 0;
else
    signal_strength = 10; % signal strength in noise condition; standard is/ was 10
end
%% Check for regularization (based on folder name)
if regexp(saveFolder', regexptranslate('wildcard', '**regularize'))
    regularize = 1;
    noiseIDX = 1;
else
    regularize = 0;
    noiseIDX = [0 1];
end
%% Noise options using SEREEGA function (deprecated)
N = struct();
N.mode = "amplitude"; % Can be either amplitude or snr
N.value = 2; % Either amplitude value or snr range; see utl_add_sensornoise

%% If real noise to be used get Noise from p3 dataset
if (regexp(saveFolder', regexptranslate('wildcard', '**realNoise')) && ~exist('Noise'))
    Noise = resting_state_noise(emptyEEG.srate);
    genNoise = 1;
end

%% blockdesign?
if (regexp(saveFolder', regexptranslate('wildcard', '**blockdesign')))
    blockdesign = 1;
else
    blockdesign = 0;
end

%% Is jitter used?
if (regexp(saveFolder', regexptranslate('wildcard', '**jittered')))
    jitter = 1;
else
    jitter = 0;
end

% Start Parpool
% parpool('local', 10)
%%
for iter = 1:50 %50
    for durEffect = 0 %[0 1]
        for shape =  {'scaledHanning'}%{'hanning', 'posHalf', 'scaledHanning'} % possible {'box','posNeg','posNegPos','hanning', 'posHalf', 'scaledHanning'}
            for overlap = [0 1]
                for overlapdistribution = {'uniform','halfnormal'}
                    for noise = noiseIDX
                        for overlapModifier = 1.5 %[1 1.5 2]
                            rng(iter) % same seed
                            %% Generate Noise
                            if (genNoise && noise == 1)
                                tmpNoise = Noise(randperm(length(Noise),1));
                            else
                                tmpNoise = {0};
                            end
                            %% Simulate data with the given properties
                            if jitter
                                EEG = generate_eeg2(emptyEEG,shape{1},overlap,overlapdistribution{1},noise,overlapModifier,N_event,T_event,durEffect,harmonize,tmpNoise,N);
                            else
                                EEG = generate_eeg(emptyEEG,shape{1},overlap,overlapdistribution{1},noise,overlapModifier,N_event,T_event,durEffect,harmonize,tmpNoise,N, signal_strength, blockdesign);
                            end
                            
                            center= quantile([EEG.event.dur],linspace( 1/(10+1), 1-1/(10+1), 10));
                            binEdges = conv([-inf center inf], [0.5, 0.5], 'valid');
                            [~,~,indx] = histcounts([EEG.event.dur],binEdges);
                            for e = 1:length(EEG.event)
                                EEG.event(e).durbin = binEdges(indx(e));
                            end
                            
                            % filter Data to get rid of the offset introduced by
                            % the simulation
                            if regexp(saveFolder', regexptranslate('wildcard', '**filtered'))
                                EEG = pop_eegfiltnew(EEG,filter,[]);
                                filtFlag = 1;
                            else
                                filtFlag = 0;
                            end
                            
                            for formula = {'y~1'
                                    'y~1+cat(durbin)'
                                    'y~1+dur'
                                    'y~1+spl(dur,5)'
                                    'y~1+spl(dur,10)'
                                    'theoretical'}'
                                %                             for formula = {'y~1+spl(dur,5)'
                                %                                 'theoretical'}'
                                %% Fit Signal
                                if formula{1} == "theoretical"
                                    % in this case we produce the "ideal" simulation
                                    % kernel
                                    assert(length(ufresult_marginal.param) == 16) % make sure we are correct here
                                    durations = [ufresult_marginal.param(2:end).value];
                                    tmin = sum(ufresult_marginal.times<=0);
                                    sig = nan(size(ufresult_marginal.beta));
                                    
                                    % For scaled hanning calculate scaling factor  
                                    sorted_dur = sort(unique(durations));
                                    scale_factors = linspace(1,2, length(sorted_dur));
                                    
                                    for d = 1:length(durations)
                                        tmp_scale_factor = scale_factors(sorted_dur == durations(d));
                                        if ~durEffect; tmp_scale_factor = 1; end; 
                                        tmp= generate_signal_kernel(durations(d)*EEG.srate*overlapModifier,shape{1},EEG.srate,harmonize, 0, tmp_scale_factor, signal_strength);
                                        sig(1,tmin+1:min(tmin+length(tmp),end),d+1) = tmp(1:min(end,size(sig,2)-tmin));
                                    end
                                    
                                    % Signal is bigger when real Noise is used, so
                                    % the theoretical one has to be multiplied as
                                    % well
                                    if (genNoise && noise == 1)
                                        sig = sig .* signal_strength;
                                    end
                                    
                                    % If filter is used during simulation zero-pad
                                    % sig and filter the theoretical shape
                                    if filtFlag
                                        sig = filt_theoretical(sig, filter);
                                    end
                                    
                                    ufresult_marginal.beta      = sig;
                                    ufresult_marginal.beta_nodc = sig;
                                else
                                    ufresult_marginal = fit_unfold(EEG,formula{1},T_event, 0, regularize);
                                end
                                
                                %% save it
                                filename = sprintf('%s_overlap-%i_%s_noise-%.2f_%s_durEffect-%i_iter-%i_overlapmod-%.1f.mat',shape{1},overlap,overlapdistribution{1},noise,formula{1},durEffect,iter,overlapModifier);
                                if ~exist(fullfile('/store/projects/unfold_duration/local',saveFolder),'dir')
                                    mkdir(fullfile('/store/projects/unfold_duration/local',saveFolder))
                                end
                                %                         parsave(fullfile('local',saveFolder,filename), ufresult_marginal)
                                save(fullfile('/store/projects/unfold_duration/local',saveFolder,filename),'ufresult_marginal');
                            end
                            
                        end
                    end
                end
            end
        end
    end
end