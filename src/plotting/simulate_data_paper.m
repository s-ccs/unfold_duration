function [EEG] = simulate_data_paper(varargin)

% 'eventname', 'stimulusA', 'type','intercept', 'overlap',0 [range 0 1],

% 'eventname', 'stimulusA', 'type','1x2', 'overlap',0 [range 0 1], 'eventname','factorA', 'effectsize', 1 (a basis of 1, +1 for if the effect is active)

% 'eventname', 'stimulusA', 'type','continuous', 'overlap',0 [correlation
% range 0 1], 'eventname','continuousA', 'effectsize', 1 (slope), 'range', [0,100]

% 'eventname', 'stimulusA', 'type','spline', 'overlap',0 [not sure how to do this], 'eventname','splineA', 'range', [-10,10], 'function', @(x)x^3

simCFG= finputcheck(varargin,...
    {'datalength','integer',[],60;
    'noise','boolean',[],1;
    'overlap','real',[],[0.4 0.6];
    'srate','integer',[],100;
    'condition','string',{'buttonpress','eyemovements'},'eyemovements';
    'rtA', 'real', [], [];
    'rtB', 'real', [], [];
    },'mode','ignore');

assert(~ischar(simCFG),simCFG)

% mean interstimulus interval
cfg = [];
cfg.srate = simCFG.srate; %Hz
cfg.pnts= simCFG.datalength*cfg.srate; % default: 10 times 60s, thus 10minute of data
cfg.noise = simCFG.noise;


%% ###############################################################
% create response function for 3 events

sig = struct();
sig.time= -0.5:1/cfg.srate:(0.5-1/cfg.srate); % 1 second stimulus


% Init variables
sig.shape=zeros(1,length(sig.time),1);
sig.amplituderesponse = zeros(1,length(sig.time),1);
sig.n170 = zeros(1,length(sig.time),1);
sig.button = zeros(1,length(sig.time),1);

% First half of response
% timePosPeak = sig.time>0.05 & sig.time < 0.15;
% sig.shape(timePosPeak) = 2.5*hanning(sum(timePosPeak)); % This is the original first positive peak; uncomment for more realistic ERP
% sig.shape(timePosPeak) = zeros(timePosPeak,1); % This was done to get one hanning as response
% sig.amplituderesponse(timePosPeak) = 1*hanning(sum(timePosPeak));

% timeNegPeak = sig.time>0.13 & sig.time < 0.23;
% sig.shape(timeNegPeak) =   sig.shape(timeNegPeak)-0.5*hanning(sum(timeNegPeak))';
% sig.shape(timeNegPeak) =   zeros(timeNegPeak)';
% sig.n170(timeNegPeak ) = hanning(sum(timeNegPeak))';
% sig.n170(timeNegPeak ) = zeros(timeNegPeak)';


% Buttonpress
timeButtonpress = sig.time>-0.2 & sig.time<0.2; % 400ms buttonpress
sig.button(timeButtonpress) = 4*hanning(sum(timeButtonpress));

% Second half of response/ "Effect"
% timePosPeak2 = sig.time>0.21 & sig.time < 0.5;
timePosPeak2 = sig.time>0.05 & sig.time < 0.45;
sig.shape(timePosPeak2) = sig.shape(timePosPeak2) + 0.75*hanning(sum(timePosPeak2))';
sig.amplituderesponse(timePosPeak2) = 0.75*hanning(sum(timePosPeak2)); % This will be used to show the effect


tmpshape = sig.shape;
sig.shape = [];
sig.shape{1} = tmpshape;
sig.shape{2} = sig.amplituderesponse;
sig.shape{3} = sig.n170;
sig.shape{4} = sig.button;

%% ##################
intercept = struct();
intercept.eventname = 'stimulusA';
intercept.type = 'intercept';
intercept.predictorName = 'intercept';
intercept.overlap = 0; % note that 0, means that the AVERAGE overlap is exactly one signal-length (i.e. 1s in our simulations). That means if we do not want ANY overlap, we specify -1 here!
intercept.effectsize =1;
intercept.range = [];
intercept.function = [];


spline = struct();
spline.eventname = 'stimulusA';
spline.type = 'spline';
spline.overlap  = 0;
spline.predictorName = 'splineA';
spline.effectsize = 5;
spline.range = [100,1000];
spline.function = [];
%%
% v = 1^2;
% m = 2;
% mu = log((m^2)/sqrt(v+m^2));
% sigma = sqrt(log(v/(m^2)+1));
% figure,histogram(lognrnd(0.5,0.5,1000,1),100)
%%
% %%


signals{1} = struct();
signals{2} = struct();

signals{1} = intercept;
signals{1}.overlap = simCFG.overlap(1);
signals{1}(2) = spline;
signals{1}(3) = intercept;
signals{1}(3).effectsize = 0.5;
signals{1}(2).rt = simCFG.rtA;

signals{2} = intercept;
signals{2}.overlap = simCFG.overlap(2);
signals{2}.eventname = 'stimulusB';
signals{2}(2) = spline;
signals{2}(2).rt = simCFG.rtB; % +150ms to increase effect


if strcmp(simCFG.condition,'eyemovements')
    signals{1}(2).function = @(x)lognrnd(0.5,0.5,1);
    signals{2}(2).function = @(x)lognrnd(0.8,0.5,1);
elseif strcmp(simCFG.condition,'buttonpress')
    signals{1}(2).function = @(x)randn(1)*0.1 + 1.25; % This is not actually used in the end
    signals{2}(2).function = @(x)randn(1)*0.1 + 1.3;
%     signals{1}(2).function = @(x)randn(1)/0.1 + 1.25;
%     signals{2}(2).function = @(x)randn(1)/0.1 + 1.3;
    signals{2}(2).effectsize = 5;
    signals{1}(2).effectsize = 5;
    % at the end we want Stimulus A, Buttonpress, Stimulus B, Buttonpress
    signals{3} = signals{2};
    signals{2} = struct();
    signals{2} = intercept;
    signals{2}.overlap = simCFG.overlap(1);
    signals{2}.eventname = 'buttonpress';
    
    signals{1}(1).overlap = -1; % no overlap of consecutive trials
    signals{3}(1).overlap = -1; % no overlap of consecutive trials
    signals{1}(1).effectsize = 2; 
    signals{3}(1).effectsize = 2; 
    signals{4} = signals{2};
    signals{4}.overlap = simCFG.overlap(2);
    
else
    error('wrong condition')
end

%% function to generate one row of X for a single event
    function X = generateX(signals)
        X = nan(1,length(signals));
        for variable = 1:length(signals)
            
            switch signals(variable).type
                case 'intercept'
                    X(variable) = 1;
                case '1x2'
                    X(variable) = binornd(1,0.5);
                case 'continuous'
                    r = signals(variable).range;
                    X(variable) = rand(1)*(r(2)-r(1))+r(1);
                case 'spline'
                    r = signals(variable).range;
%                     X(variable) = rand(1)*(r(2)-r(1))+r(1);
                    X(variable) = signals(variable).rt(randi(length(signals(variable).rt))) / 1000;
%                     X(variable) = signals(variable).function(X(variable));
                otherwise
                    error('unknown variable type: %s', signals(variable).type)
            end
        end
        
    end

    function O = generateO(signals,oneX)
        O = 0;
        for variable = 1%:length(signals)
            ov = (1-signals(variable).overlap);
            switch signals(variable).type
                case 'intercept'
                    O = O + 1000 * ov; %the basis
                case '1x2'
                    O = O + 1000 * ov*oneX(variable); % in addition to that (oneX has to be 0 or 1
                case 'continuous'
                    r = signals(variable).range;
                    O = O + 1000 *  ov * oneX(variable)/(r(2)-r(1));
                    
                case 'spline'
                    '';
                    
                otherwise
                    error('unknown variable type: %s', signals(variable).type)
            end
        end
        
    end
%%


timeToNextEvent = [];
eventSignal = [];
X = cell(size(signals));
runner = 1;
breakFlag = 0;
while sum(timeToNextEvent)<cfg.pnts
    if breakFlag == 1
        break
    end
    for sIx = 1:length(signals) % in case of multiple events
        XoneRow = generateX(signals{sIx});
        
        % Save the "designMatrix"
        if isempty(X{sIx})
            X{sIx} = XoneRow;
        else
            X{sIx}(end+1,:) = XoneRow;
        end
        % generate overlap (i.e. when the next signal should occur)
        % actually this generates the mean of the distribution of distance.
        % if this mean is very small, lots of overlap
        try
            XrowBefore = X{sIx}(end-1,:);
        catch
            XrowBefore = XoneRow;
        end
        overlap = generateO(signals{sIx},XrowBefore);
        
        m = overlap;
        
        if m <= 0
            %            warning('mean of log-distributed distances was smaller equal 0, forcing to be at least 1ms: %f',m)
            m = 1;
        end
        
        v = 100^2;
        % taken from 'lognstat' matlab help:
        mu = log((m^2)/sqrt(v+m^2));
        sigma = sqrt(log(v/(m^2)+1));
        % to visualize adapt accordingly:
        % figure,hist([lognrnd(mu,sigma,1,1000)*0.01;lognrnd(9.5,0.5,1,1000)*0.01]',100)
        nextTrigger = lognrnd(mu,sigma,1,1)/1000*cfg.srate;
        
        t = ceil(nextTrigger);
        
        if (sum(timeToNextEvent)+t)>cfg.pnts
            breakFlag = 1;
            break
        end
        
        %fprintf('%i from %i \n',sum(timeToNextEvent),cfg.pnts)
        runner = runner+1;
        eventSignal = [eventSignal sIx];
        timeToNextEvent = [timeToNextEvent t];
    end
end
% this gives the event times, in "eventSignal" is written, which times
% belong to which events
eventTimes = cumsum(timeToNextEvent);
%%
for sIx = 1:length(signals)
    
    % generate the simulated data
    if strcmp(simCFG.condition,'eyemovements')
            EEG_tmp=generate_signal_paper(X{sIx},eventTimes(eventSignal==sIx),sig,signals{sIx},cfg);
    elseif strcmp(simCFG.condition,'buttonpress')
        tmpsig = sig;
        
        if sIx == 4 | sIx == 2  % in case of buttonpress
            tmpsig.shape = tmpsig.shape(4) ;
             EEG_tmp=generate_signal_paper(X{sIx},eventTimes(eventSignal==sIx),tmpsig,signals{sIx},cfg);
        else
            tmpsig.shape = tmpsig.shape(1:3);
            EEG_tmp=generate_signal_paper(X{sIx},eventTimes(eventSignal==sIx),tmpsig,signals{sIx},cfg,@(x)(log(x+0.5)-log(0.1)));
%             EEG_tmp=generate_signal_paper(X{sIx},eventTimes(eventSignal==sIx),tmpsig,signals{sIx},cfg,@(x)((x).^2)-1.5);
        end
    end
    [~,zeropoint] = min(abs(sig.time));
    for e = 1:length(EEG_tmp.event)
    EEG_tmp.event(e).latency = EEG_tmp.event(e).latency + zeropoint;
    end
    % concatenate multiple signals
    if sIx == 1
        EEG = EEG_tmp;
        EEG.sim.signals = signals;
    else
        % Combine events (can have different fields which makes
        % concatenation difficult)
        fnB = fieldnames(EEG_tmp.event);
        fnA = fieldnames(EEG.event);
        
        fnAinB = find(~ismember(fnA,fnB));
        fnBinA = find(~ismember(fnB,fnA));
        
        ev1= EEG.event;
        ev2 = EEG_tmp.event;
        ev1 = rmfield(ev1,fnA(fnAinB));
        ev2 = rmfield(ev2,fnB(fnBinA));
        ev = [ev1;ev2];
        % Now fill in all of A, that was not in B
        for e =1:length(ev1)
            for f = fnAinB'
                ev(e).(fnA{f}) = EEG.event(e).(fnA{f});
            end
        end
        for e =1:length(ev2)
            for f = fnBinA'
                ev(e+length(EEG.event)).(fnB{f}) = EEG_tmp.event(e).(fnB{f});
            end
        end
        %%
        EEG.event = ev;%[EEG.event;EEG_tmp.event];
        % Combine Simulation
        EEG.sim.X = X;
        EEG.sim.separateSignal = [EEG.sim.separateSignal; EEG_tmp.sim.separateSignal];
        EEG.sim.noOverlapSignal = [EEG.sim.noOverlapSignal; EEG_tmp.sim.noOverlapSignal];
        EEG.eventTimes = eventTimes;
        % Combine Data
        EEG.data = EEG.data + EEG_tmp.data;
        EEG = eeg_checkset(EEG,'eventconsistency');
    end
end

end
%%
