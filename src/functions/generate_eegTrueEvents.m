function EEG = generate_eegTrueEvents(EEG,shape,overlap,overlapdistribution,noise,overlapModifier,T_event,durEffect)
% Generate single EEG channel based on real dataset (ERP Core P3 dataset)
% event latencies. 
% If overlap = 0 then there is no overlap between any of the events. If
% overlap = 1 then ONLY the stimulus pairs are overlapped (stimulus +
% buttonpress).
% Names:
% target; distractor; respC; respE

options = struct();
options.overlap = overlap; % 0 deactivates overlap
options.shape = shape;
options.noise = noise;
options.overlapdistribution = overlapdistribution;
options.overlapModifier= overlapModifier;
options.durEffect = durEffect;

event_lat = round(extractfield(EEG.event, 'latency'));
event_type = extractfield(EEG.event, 'type');
meanDur = mean(diff([EEG.event.latency])) / 2; %changed to something closer to the mean duration of stimuli


%----------------------------
% generate signal and add them to a continuous EEG


sig1_tmp = zeros(1,EEG.pnts);
sigAll = zeros(length(event_lat)-1,T_event);
for e = 1:length(event_lat(1:end))
    evt1 = event_lat(e); %EEG.event(e).latency;
    
    % Generate Target and distractor
    if (any(1:55 == event_type(e)))
        
        EEG.event(e).type = 'stimulus';
        % Check if next event is a response and assign Event duration
        if any(event_type(e+1) == [201 202])
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
        % Decide if target or distractor
        if  any(11:11:55 == event_type(e))
            EEG.event(e).trialtype = 'target';
        else
            EEG.event(e).trialtype = 'distractor';
        end
        start = find(sig1~=0,1);
        EEG.event(e).dur = dur./EEG.srate; % Convert duration to ms
        EEG.event(e).sigdur = (find(sig1(start:end)==0,1)+start)./EEG.srate;
        
        % Generate Event B, i.e. Response
    elseif (event_type(e) == 201) || (event_type(e) == 202)
        sig1 = generate_signal_kernel(meanDur, 'posNeg', EEG.srate);
        
        EEG.event(e).type = 'button';
        % Decide if correct or error
        if event_type(e) == 201
            EEG.event(e).trialtype = 'responseC';
        else 
            EEG.event(e).trialtype = 'responseE';
        end
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