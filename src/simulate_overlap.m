%% Generate Signal

rng(1) % same seed
ufresult_all = {};

for is_overlap = [1 0];
    rng(1) % same seed
    options = struct();
    options.overlap = is_overlap; % 0 deactivates overlap
    options.shape = "box";
    options.shape = "posNeg";
    options.shape = "posNegPos";
%      options.shape = "hanning";
    
    options.overlapdistribution = "uniform";
%     options.overlapdistribution = "halfnormal";
    options.overlapModifier= 1.5;
    
    options.noise = 0;
    N_event = 500; % max number of events
    EEG = eeg_emptyset();
    
    EEG.srate = 100; %Hz
    EEG.pnts  = EEG.srate*500; % total length in samples
    T_event   = EEG.srate*1.5; % total length of event-signal in samples
    
    
    % event_lat = randi(EEG.pnts - T_event,N_event);
    %-------------------------------
    % generate event-timings
    switch options.overlapdistribution
        case "halfnormal"
            spread = abs(randn(N_event,1))./0.6;
        case "uniform"
            spread = abs(rand(N_event,1))./0.2887;
    end
    
    event_lat = (.15+.20*spread);
    event_lat = ceil(event_lat * EEG.srate); % convert to samples
    event_lat(event_lat>T_event) = [];
    event_lat = cumsum(event_lat);
    event_lat(event_lat>EEG.pnts-T_event) = []; % limit the signalsize
    
    for e = 1:length(event_lat)
        EEG.event(e).latency = event_lat(e);
        EEG.event(e).type = 'eventA';
    end
    
    %----------------------------
    % generate signal and add them to a continuous EEG
    
    
    sig1_tmp = zeros(1,EEG.pnts);
    sigAll = zeros(length(event_lat)-1,T_event);
    for e = 1:length(event_lat(1:end-1))
        evt1 = EEG.event(e).latency;
        evt2 = event_lat(e + 1);
        dur = evt2-evt1;
        
        % starting sample
        sig = generate_signal_kernel(dur*options.overlapModifier,options.shape,EEG.srate);
        start = find(sig~=0,1);
        EEG.event(e).dur = dur./EEG.srate;
        EEG.event(e).sigdur = (find(sig(start:end)==0,1)+start)./EEG.srate;
        
        sigAll(e,1:length(sig)) = sig;
        if options.overlap == 0
            evt1 = evt1 + sum(event_lat(1:e)); % shift to generate no overlap
            EEG.event(e).latency = evt1;
        end
        % automatically prolong the signal
        if ~((evt1+T_event-1)<size(sig1_tmp,2))
            sig1_tmp(size(sig1_tmp,2)+1:(evt1+size(sig,1)-1)) = 0;
        end
        sig1_tmp(evt1:evt1+size(sig,1)-1) = sig1_tmp(evt1:evt1+size(sig,1)-1)'+sig;
    end
    EEG.event(end) = [];
    
    EEG.data(1,:) = sig1_tmp;%(1:EEG.pnts);
    EEG.data(1,:) = EEG.data(1,:) + options.noise * randn(size(EEG.data));
    EEG.pnts = size(EEG.data,2);
    EEG = eeg_checkset(EEG);
    
    %% -------------------
    % Intermediate Plotting
    %     [dursort,ixsort] = sort([EEG.event.dur]);
    %     sigdursort = [EEG.event(ixsort).sigdur];
    %     figure,a1 = subplot(2,1,1);
    %     imagesc((1:size(sigAll,2))./EEG.srate,dursort,sigAll(ixsort,:))
    %     hold on
    %     plot(dursort,sigdursort,'o-')
    %
    %
    %     subplot(2,1,2),ksdensity((diff(event_lat))./EEG.srate)
    %     xlim(a1.XLim)
    %% -------------------
    % Fit Signal
    % and save results
    
    for k = 1:4
        cfgDesign = struct();
        switch k
            case 1
                cfgDesign.formula = 'y~1';
            case 2
                cfgDesign.formula = 'y~1+dur';
            case 3
                cfgDesign.formula = 'y~1+spl(dur,5)';
            case 4
                cfgDesign.formula = 'y~1+spl(dur,10)';
        end
        % cfgDesign.formula = 'y~1';
        cfgDesign.eventtypes = 'eventA';
        EEG = uf_designmat(EEG,cfgDesign);
        
        
        %     fun = 'splines';
        cfgTimeexpand = struct();
        cfgTimeexpand.timelimits = [-.5 T_event/EEG.srate];
        
        EEG_loop = uf_timeexpandDesignmat(EEG,cfgTimeexpand);
        % end
        
        
        EEG_loop = uf_glmfit(EEG_loop);
        if is_overlap
            % without overlap we don't need to run the nodc, it will be
            % equivalent to the dc
            EEG_loop = uf_epoch(EEG_loop,cfgTimeexpand);
            EEG_loop = uf_glmfit_nodc(EEG_loop);
        end
        ufresult = uf_condense(EEG_loop);
        ufresult_marginal = uf_addmarginal(uf_predictContinuous(ufresult));
        if is_overlap == 1 || size(ufresult_all,2)<k
            ufresult_all{k} = ufresult_marginal;
        elseif is_overlap == 0 && k==1
            
            ufresult_all{k}.a_no_simulated_overlap= ufresult_marginal.beta;
        else
            continue
        end
        if k>1
            durations = [ufresult_all{k}.param(2:end).value];
            tmin = sum(ufresult_all{k}.times<=0);
            sig = nan(size(ufresult_all{k}.beta));
            for d = 1:length(durations)
                tmp= generate_signal_kernel(durations(d)*EEG.srate*options.overlapModifier,options.shape,EEG.srate);
                sig(1,tmin+1:min(tmin+length(tmp),end),d+1) = tmp(1:min(end,size(sig,2)-tmin));
            end
            
            
            ufresult_all{k}.abeta_original = sig;
            
            %%
            sigAll = [];
            tmin = 20;%sum(ufresult_all{4}.times<=0);
            durlist = [6 11 2];
            for d = durlist
                %[0.4,0.8,0.2,0.4]
                dur = ufresult_all{k}.param(d).value*EEG.srate;
                
                generated_sig = generate_signal_kernel(dur*options.overlapModifier,options.shape,EEG.srate);
                
                
                sig = zeros(size(ufresult_all{k}.beta(:,:,1)));
                sig(tmin+1:min(tmin+length(generated_sig),end)) = generated_sig(1:min(end,size(sig,2)-tmin));
                sigAll(1,:,end+1) = sig;
                tmin = tmin+dur;

            end
            ufresult_all{k}.aexplain = nan(size(ufresult_all{k}.abeta_original));
            ufresult_all{k}.aexplain(1,:,durlist) = sigAll(:,:,2:end);%first one is empty
            
            
        end
    end
end
%% -----------
% Plotting
for k = [1 4]
    ufresult_all{k} = renameStructField(ufresult_all{k},'beta','d_overlap_correction');
    ufresult_all{k} = renameStructField(ufresult_all{k},'beta_nodc','c_no_overlap_correction');
    ufresult_all{k} = renameStructField(ufresult_all{k},'abeta_original','a_simulation_kernel');
    ufresult_all{k} = renameStructField(ufresult_all{k},'aexplain','b_example_plot');
    if k == 1
        uf_plotParam(ufresult_all{k},'dataField','d_overlap_correction')
    else
        g = uf_plotParam(ufresult_all{k},'plotParam','dur','dataField','d_overlap_correction');
    end
end

%%
