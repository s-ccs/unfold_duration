% Run a bunch of simulations (~20GB space if all combinations are used)
tic;
rng(1) % same seed
ufresult_all = {};
N_event = 1000; % max number of events
emptyEEG = eeg_emptyset();
emptyEEG.srate = 100; %Hz
emptyEEG.pnts  = emptyEEG.srate*500; % total length in samples
T_event   = emptyEEG.srate*1.5; % total length of event-signal in samples


for iter = 1:50
for durEffect = [0 1]
for shape = {'box','posNeg','posNegPos','hanning'}
    for overlap = [0 1]
        for overlapdistribution ={'uniform','halfnormal'}
            for noise = [0 1]
                for overlapModifier = [1 1.5 2]
                    rng(iter) % same seed
                    %% Simulate data with the given properties
                    EEG = generate_eeg2events(emptyEEG,shape{1},overlap,overlapdistribution{1},noise,overlapModifier,N_event,T_event,durEffect);
                    center= quantile([EEG.event.dur],linspace( 1/(10+1), 1-1/(10+1), 10));
                    binEdges = conv([-inf center inf], [0.5, 0.5], 'valid');
                    [~,~,indx] = histcounts([EEG.event.dur],binEdges);
                    k = 1;
                    for e = 1:length(EEG.event)
                        if ~isempty(EEG.event(e).dur)
                            EEG.event(e).durbin = binEdges(indx(k));
                            k = k + 1;
                        end
                    end
                    
                    
                    for formula = {'y~1'
                            'y~1+dur'
                            'y~1+spl(dur,5)'
                            'y~1+spl(dur,10)'
                            'theoretical'}' %'y~1+cat(durbin)'
                        
                        %% Fit Signal
                        if formula{1} == "theoretical"
                            % in this case we produce the "ideal" simulation
                            % kernel
                            assert(length(ufresult_marginal.param) == 12) % make sure we are correct here; What is supposed to be correct?
                            durations = [ufresult_marginal.param(2:end-1).value];
                            tmin = sum(ufresult_marginal.times<=0);
                            sig = nan(size(ufresult_marginal.beta));
                            for d = 1:length(durations)
                                tmp= generate_signal_kernel(durations(d)*EEG.srate*overlapModifier,shape{1},EEG.srate);
                                sig(1,tmin+1:min(tmin+length(tmp),end),d+1) = tmp(1:min(end,size(sig,2)-tmin));
                            end
                            
                            
                            ufresult_marginal.beta      = sig;
                            ufresult_marginal.beta_nodc = sig;
                        else
                            ufresult_marginal = fit_unfold(EEG,formula{1},T_event,1);
                        end
                        
                        %% save it
                        filename = sprintf('%s_overlap-%i_%s_noise-%.2f_%s_durEffect-%i_iter-%i_overlapmod-%.1f.mat',shape{1},overlap,overlapdistribution{1},noise,formula{1},durEffect,iter,overlapModifier);
                        if ~exist(fullfile('local','sim2-1'),'dir')
                            mkdir(fullfile('local','sim2-1'))
                        end
                        save(fullfile('local','sim2-1',filename),'ufresult_marginal')
                    end
                    
                end
            end
        end
    end
end
end
end
toc