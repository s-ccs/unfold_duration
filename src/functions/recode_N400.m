function EEG = recode_N400(EEG)
% Recode events to be used with the unfold toolbox

event = EEG.event;

% Delete first button presses because they only mark start of experiment
flag = 0;
n = 1;
idx = [];
while ~flag
    if any(event(n).type == [201 202])
        idx = [idx n];
        n = n+1;
    else
        flag = 1;
    end
end
event(idx) = [];

% Recode events
for e = 1:length(event)
    switch event(e).type
        % Primer
        case {111, 112}
            event(e).eventtype = 'Prime';
            event(e).pairtype = 'related';
            event(e).rt = 0;
        case {121, 122}
            event(e).eventtype = 'Prime';
            event(e).pairtype = 'unrelated';
            event(e).rt = 0;
            
        % Target stimuli    
        case {211, 212}
            event(e).eventtype = 'Target';
            event(e).pairtype = 'related';
            % Check response
            if any(event(e+1).type == [201 202])
                event(e).rt = event(e+1).latency - event(e).latency;
                if event(e+1).type == 201
                    event(e).accuracy = 'correct';
                else
                    event(e).accuracy = 'incorrect';
                end
            else
                event(e).rt = 0;
            end
        case {221, 222}
            event(e).eventtype = 'Target';
            event(e).pairtype = 'unrelated';
            if any(event(e+1).type == [201 202])
                event(e).rt = event(e+1).latency - event(e).latency;
                if event(e+1).type == 201
                    event(e).accuracy = 'correct';
                else
                    event(e).accuracy = 'incorrect';
                end
            else
                event(e).rt = 0;
            end
        % Responses
        case 201
            event(e).accuracy = 'correct';
            event(e).eventtype = 'response';
            event(e).rt = event(e).latency - event(e-1).latency;
        case 202
            event(e).accuracy = 'incorrect';
            event(e).eventtype = 'response';
            event(e).rt = event(e).latency - event(e-1).latency;
    end
    
    
    % Decide on event type
    if any(event(e).type == [111 112 121 122 211 212 221 222])
        event(e).type = 'stimulus';
    elseif any(event(e).type == [201 202])
        event(e).type = 'response';
    end
end

EEG.event = event;