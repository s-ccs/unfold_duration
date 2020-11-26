function EEG = generate_eegTrueEvents(EEG,shape,overlap,overlapdistribution,noise,overlapModifier,T_event,durEffect)
% Generate one EEG channel with "event pairs". Basically a simulation of a
% stimulus + buttonpress experiment. The second Event is (for now) always
% generated using a posNeg Kernel.
% If overlap = 0 then there is no overlap between any of the events. If
% overlap = 1 then ONLY the stimulus pairs are overlapped (stimulus +
% buttonpress).
% Names:
% eventA; eventB

options = struct();
options.overlap = overlap; % 0 deactivates overlap
options.shape = shape;
options.noise = noise;
options.overlapdistribution = overlapdistribution;
options.overlapModifier= overlapModifier;
options.durEffect = durEffect;

%-------------------------------
% % generate event-timings
% switch options.overlapdistribution
%     case "halfnormal"
%         spread = abs(randn(N_event,1))./0.6;
%     case "uniform"
%         spread = abs(rand(N_event,1))./0.2887;
% end
%
% event_lat = (.15+.20*spread);
% event_lat = ceil(event_lat * EEG.srate); % convert to samples
% event_lat(event_lat>T_event) = [];
% event_lat = cumsum(event_lat);
% event_lat(event_lat>EEG.pnts-T_event) = []; % limit the signalsize

% Generate events
% for e = 1:2:length(event_lat)
%     EEG.event(e).latency = event_lat(e);
%     EEG.event(e).type = 'eventA';
%     if (e+1) <= length(event_lat)
%         EEG.event(e+1).latency = event_lat(e+1);
%         EEG.event(e+1).type = 'eventB';
%     end
% end

event_lat = extractfield(EEG.event, 'latency');
event_type = extractfield(EEG.event, 'type');
meanDur = mean(diff([EEG.event.latency]));

% Make sure last event is not eventA
% if strcmp(EEG.event(end).type,'eventA')
%     EEG.event(end) = [];
% end

%----------------------------
% generate signal and add them to a continuous EEG


sig1_tmp = zeros(1,EEG.pnts);
sigAll = zeros(length(event_lat)-1,T_event);
for e = 1:length(event_lat(1:end))
    evt1 = event_lat(e); %EEG.event(e).latency;
    
    % Generate Event A; No matter the Stimulus
    if (any(1:80 == event_type(e)) || any(101:180 == event_type(e)))
        % Check if next event is a response and assign Event duration
        if event_type(e+1) == (201 || 202)
            evt2 = event_lat(e + 1);
            dur = evt2-evt1;
            if options.durEffect
                % duration affects shape
                sigduration = dur*options.overlapModifier;
            else
                % duration does not affect shape
                sigduration = meanDur;
            end
        else % If there is no response shape is not affected by duration; Does this bias the regression?
            sigduration = meanDur;
            dur = meanDur;
        end
        
        sig1 = generate_signal_kernel(sigduration,options.shape,EEG.srate);
        EEG.event(e).type = 'eventA';
        start = find(sig1~=0,1);
        EEG.event(e).dur = dur./EEG.srate; % Convert duration to ms
        EEG.event(e).sigdur = (find(sig1(start:end)==0,1)+start)./EEG.srate;
        
        % Generate Event B, i.e. Response
    elseif (event_type(e) == 201) || (event_type(e) == 202)
        sig1 = generate_signal_kernel(meanDur, 'posNeg', EEG.srate);
        EEG.event(e).type = 'eventB';
        start1 = find(sig1~=0,1);
        EEG.event(e).dur = [];
        EEG.event(e).sigdur = (find(sig1(start1:end)==0,1)+start1)./EEG.srate;
    end
    
    sigAll(e,1:length(sig1)) = sig1;
    
    % Overlap
    if options.overlap == 0
        %evt1 = evt1 + sum(event_lat(1:e)); % shift to generate no overlap
        event_lat(e+1:end) = event_lat(e+1:end) + length(sig1);
    end
    
    % make sure event latency is correct
    EEG.event(e).latency = evt1;
    
    % automatically prolong the signal
    if ~((evt1+size(sig1,1))<size(sig1_tmp,2))%((evt1+T_event-1)<size(sig1_tmp,2))  <--- Check if this is valid!!
        sig1_tmp(size(sig1_tmp,2)+1:(evt1+size(sig1,1)-1)) = 0;
    end
    % Add current sig to total sig
    sig1_tmp(evt1:evt1+size(sig1,1)-1) = sig1_tmp(evt1:evt1+size(sig1,1)-1)'+sig1;
end



EEG.event(end) = [];

EEG.data(1,:) = sig1_tmp;%(1:EEG.pnts);
EEG.data(1,:) = EEG.data(1,:) + options.noise * randn(size(EEG.data));
EEG.pnts = size(EEG.data,2);
EEG.sim.sigAll = sigAll;
EEG = eeg_checkset(EEG);