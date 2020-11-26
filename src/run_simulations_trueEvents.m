% Run a bunch of simulations (~20GB space if all combinations are used)
% Use Events from a real dataset for simulation

%% Initilize some stuff
rng(1) % same seed
ufresult_all = {};
% N_event = 500; % max number of events
emptyEEG = eeg_emptyset();

% Get Events from real dataset
EEGN = pop_loadset('filename','7_N170.set','filepath','C:\\Users\\ReneS\\Desktop\\N170_7\\');
pop_resample(EEGN, 500); % Resample to 500 instead of 1024 for faster computation
emptyEEG.srate = EEGN.srate;
emptyEEG.pnts = EEGN.pnts;
emptyEEG.event.type = extractfield(EEGN.event,'type');
emptyEEG.event.latency = extractfield(EEGN.event, 'latency');
T_event   = emptyEEG.srate*1.5;
%% Run simulations
for iter = 1%1:50
for durEffect = [0 1]
for shape = {'box','posNeg','posNegPos','hanning'}
    for overlap = [0 1]
        for overlapdistribution ={'uniform','halfnormal'}
            for noise = [0 1]
                for overlapModifier = [1 1.5 2]
                    rng(iter) % same seed
                    %% Simulate data with the given properties
                    EEG = generate_eegTrueEvents(emptyEEG,shape{1},overlap,overlapdistribution{1},noise,overlapModifier,T_event,durEffect);
                    tmp_T_event = EEG.srate*1.5;
                    center= quantile([EEG.event.dur],linspace( 1/(10+1), 1-1/(10+1), 10));
                    binEdges = conv([-inf center inf], [0.5, 0.5], 'valid');
                    [~,~,indx] = histcounts([EEG.event.dur],binEdges);
                    % Maybe check binning later... Bugged for now
%                     for e = 1:length(EEG.event)
%                         try
%                             EEG.event(e).durbin = binEdges(indx(e));
%                         catch
%                             EEG.event(e).durbin = [];
%                         end
%                     end
                    
                    
                    for formula = {'y~1'
                            'y~1+dur'
                            'y~1+spl(dur,5)'
                            'y~1+spl(dur,10)'
                            'theoretical'}' %'y~1+cat(durbin)'
                        
                        %% Fit Signal
                        if formula{1} == "theoretical"
                            % in this case we produce the "ideal" simulation
                            % kernel
                            assert(length(ufresult_marginal.param) == 11) % make sure we are correct here
                            durations = [ufresult_marginal.param(2:end).value];
                            tmin = sum(ufresult_marginal.times<=0);
                            sig = nan(size(ufresult_marginal.beta));
                            for d = 1:length(durations)
                                tmp= generate_signal_kernel(durations(d)*EEG.srate*overlapModifier,shape{1},EEG.srate);
                                sig(1,tmin+1:min(tmin+length(tmp),end),d+1) = tmp(1:min(end,size(sig,2)-tmin));
                            end
                            
                            
                            ufresult_marginal.beta      = sig;
                            ufresult_marginal.beta_nodc = sig;
                        else
                            ufresult_marginal = fit_unfold(EEG,formula{1},T_event);
                        end
                        
                        %% save it
                        filename = sprintf('%s_overlap-%i_%s_noise-%.2f_%s_durEffect-%i_iter-%i_overlapmod-%.1f.mat',shape{1},overlap,overlapdistribution{1},noise,formula{1},durEffect,iter,overlapModifier);
                        if ~exist(fullfile('local','sim3'),'dir')
                            mkdir(fullfile('local','sim3'))
                        end
                        save(fullfile('local','sim3',filename),'ufresult_marginal')
                    end
                    
                end
            end
        end
    end
end
end
end