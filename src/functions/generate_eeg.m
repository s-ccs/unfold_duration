function EEG = generate_eeg(EEG,shape,overlap,overlapdistribution,noise,overlapModifier,N_event,T_event,durEffect,harmonize,tmpNoise, N)

options = struct();
options.overlap = overlap; % 0 deactivates overlap
options.shape = shape;
options.noise = noise;
options.overlapdistribution = overlapdistribution;
options.overlapModifier= overlapModifier;
options.durEffect = durEffect;
options.realNoise = tmpNoise;

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

% Calculate scaling factor for upward scaling of shape (only for scaled
% Hannaing)

dur_all = zeros(length(event_lat(1:end-1)),1);
for e = 1:length(event_lat(1:end-1))
    evt1 = EEG.event(e).latency;
    evt2 = event_lat(e + 1);
    tmp_dur = evt2-evt1;
    dur_all(e) = tmp_dur;
end
sorted_dur = sort(unique(dur_all));
scale_factors = linspace(1,2, length(sorted_dur));

%----------------------------
% generate signal and add them to a continuous EEG


sig1_tmp = zeros(1,EEG.pnts);
sigAll = zeros(length(event_lat)-1,T_event);
for e = 1:length(event_lat(1:end-1))
    evt1 = EEG.event(e).latency;
    evt2 = event_lat(e + 1);
    dur = evt2-evt1;
    
    % Decide on scaling factor here; Use linspace variable from above
    tmp_scale_factor = scale_factors(dur == sorted_dur);
    
    if options.durEffect
        % duration effects shape
          sigduration = dur*options.overlapModifier;
    else
        % duration does not effect shape
        sigduration = mean(diff([EEG.event.latency]));
    end
    
    % Check if real noise is used, if yes multiply and cancel SEEREGA noise
    if ~options.realNoise{1}
        rNoise = 0;
    else
        options.noise = 0;
        rNoise = 1;
    end
    
    % starting sample
    sig = generate_signal_kernel(sigduration, options.shape, EEG.srate, harmonize, rNoise, tmp_scale_factor);
    start = find(sig~=0,1);
    EEG.event(e).dur = dur./EEG.srate;
    EEG.event(e).sigdur = (find(sig(start:end)==0,1)+start)./EEG.srate;
    
    sigAll(e,1:length(sig)) = sig;
    if options.overlap == 0
        evt1 = evt1 + sum(event_lat(1:e)); % shift to generate no overlap
        EEG.event(e).latency = evt1;
    end
    % automatically prolong the signal
    if ~((evt1+size(sig,1)-1)<size(sig1_tmp,2))%((evt1+T_event-1)<size(sig1_tmp,2))  <--- Check if this is valid!!
        sig1_tmp(size(sig1_tmp,2)+1:(evt1+size(sig,1)-1)) = 0;
    end
    sig1_tmp(evt1:evt1+size(sig,1)-1) = sig1_tmp(evt1:evt1+size(sig,1)-1)'+sig;
end
EEG.event(end) = [];

EEG.data(1,:) = sig1_tmp;%(1:EEG.pnts);
%EEG.data(1,:) = EEG.data(1,:) + options.noise * randn(size(EEG.data));
% Add noise
if options.noise
    EEG.data = utl_add_sensornoise(EEG.data, N.mode, N.value);
elseif options.realNoise{1}
    x = tmpNoise{1}(randperm(size(tmpNoise,1),1),:);
    if length(EEG.data) <= length(x)
    EEG.data = EEG.data(1,:) + x(1:length(EEG.data));
    else
        
        lx = ceil(length(EEG.data)/length(x));
        x = repmat(x,1,lx); % Prolong noise to be used on EEG data
       EEG.data = EEG.data(1,:) + x(1:length(EEG.data));
    end
    
end
EEG.pnts = size(EEG.data,2);
EEG.sim.sigAll = sigAll;
EEG = eeg_checkset(EEG);