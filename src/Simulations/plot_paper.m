% Make different plots for the paper; This is only an initial script for
% general structure/ design of plots/ figures and to collect ideas.

%% Plot the different shapes onto one figure with variable lengths
% Currently in subplots because nicer
figure()
hold all
ylim([-1.2 2.2])
xlim([0 150])
l = [50:10:100];
factors = linspace(1,2,6);

for shape = {'posHalf'
        'hanning'
        'scaledHanning'
        'posNeg'}'
    switch shape{1}
        case "posHalf"
            colour = '-r';
            sub = 1;
        case "hanning"
            colour = '-b';
            sub = 2;
        case "scaledHanning"
            colour = '-m'
            sub = 3;
        case "posNeg"
            colour = '-g';
            sub = 4;
    end
    subplot(2,2,sub)
    hold all
    for i = 1:length(l)
        scale_factor = factors(i);
        tmp = generate_signal_kernel(l(i),shape{1},250,1,0, scale_factor);
        plot(tmp, colour)
    end
end
hold off

%% Plot scaled hanning
figure()
% ylim([-1.2 1.2])
% xlim([0 150])
colour = 'b';
factors = linspace(1,2,6);
l = [50:10:100];
for shape = {'scaledHanning'}
    hold all
    for i = 1:length(l)
        scale_factor = factors(i);
        tmp = generate_signal_kernel(l(i),shape{1},250,1,0, scale_factor);
        plot(tmp, colour)
    end
end
hold off

%% continous simulated EEG one shape
rng(3)
% Generate EEG
N_event = 500; % max number of events
emptyEEG = eeg_emptyset();
emptyEEG.srate = 100; %Hz
emptyEEG.pnts  = emptyEEG.srate*500; % total length in samples
T_event   = emptyEEG.srate*1.5; % total length of event-signal in samples
signalstrength = 10;
blockdesign = 1;

%
N = struct();
N.mode = "amplitude"; % Can be either amplitude or snr
N.value = 2;

overlap = 1; overlapdistribution = {'uniform'}; overlapModifier = 1.5;
shape = {'scaledHanning'}; harmonize = 1; durEffect = 1;
noise = 0;

if ~exist('rNoise')
    rNoise = resting_state_noise(emptyEEG.srate);
end
if (noise == 1)
    tmpNoise = rNoise(randperm(length(rNoise),1));
else
    tmpNoise = {0};
end
%%
EEG = generate_eeg(emptyEEG,shape{1},overlap,overlapdistribution{1},noise,overlapModifier,N_event,T_event,durEffect,harmonize,tmpNoise, N, signalstrength, blockdesign);
%% 
pop_eegplot( EEG, 1, 1, 1);
%%
ix = [200 700];
figure()
hold all
plot(ix(1):ix(2),EEG.data(ix(1):ix(2)))
% ylim([0 1.3])
evts = [EEG.event(extractfield(EEG.event, 'latency') > ix(1) & extractfield(EEG.event, 'latency') < ix(2)).latency];
vline(evts, 'r')
vline(evts + 5, 'b')
%% Make Figure showing individual shapes/ no noise/ noise
rng(1)
tmpNoise = rNoise(randperm(length(rNoise),1));

EEG = generate_eeg(emptyEEG,shape{1},overlap,overlapdistribution{1},0,overlapModifier,N_event,T_event,durEffect,harmonize,{0}, N, signalstrength, blockdesign);
EEGNoise = generate_eeg(emptyEEG,shape{1},overlap,overlapdistribution{1},1,overlapModifier,N_event,T_event,durEffect,harmonize,tmpNoise, N, signalstrength, blockdesign);

%% isolated EEG
% Init matrix for all shapes
mate = zeros(length(EEG.event), length(EEG.data)); 

% Get the scale factor as defined in generate_eeg
sorted_dur = sort(unique(extractfield(EEG.event, 'dur')));
scale_factors = linspace(1,2, length(sorted_dur));

%Loop through events and generate shape for each event
for e = 1:length(EEG.event)
    sigdur = EEG.event(e).sigdur * EEG.srate;
    tmp_scale_factor = scale_factors(EEG.event(e).dur == sorted_dur);
    sig = generate_signal_kernel(sigdur, shape{1}, EEG.srate, 1, 0, tmp_scale_factor);
    mate(e, EEG.event(e).latency:(EEG.event(e).latency+length(sig)-1)) = sig';
    
end

%%
% wdw = [1 6000];
wdw = [800 1550];
% wdw = [2100 2650];
figure()
t = tiledlayout(3,1);
nexttile
hold all
first = find([EEG.event(:).latency] <= wdw(1), 1);
last = find([EEG.event(:).latency] <= wdw(2), 1, 'last');
for p = first:last
    plot(mate(p,wdw(1):wdw(2)).*10)
end
%hold off
% ylim([-20 35])

%nexttile
% plot(EEG.data(wdw(1):wdw(2)).*10, 'b')
ylim([-15 35])
hold off

% nexttile
hold all
%plot(EEGNoise.data(wdw(1):wdw(2)))
plot(EEG.data(wdw(1):wdw(2)).*10, 'b')
ylim([-15 35])
hold off

x = tmpNoise{1}(randperm(size(tmpNoise,1),1),:);
lx = ceil(length(EEG.data)/length(x));
x = repmat(x,1,lx); % Prolong noise to be used on EEG data
AddNoiseData = (EEG.data(1,:).*10) + x(1:length(EEG.data));
noiseOnly = x(1:length(EEG.data));

nexttile
hold all
plot(EEGNoise.data(wdw(1):wdw(2)))
% plot(EEG.data(wdw(1):wdw(2)).*10, 'g')
% plot(AddNoiseData(wdw(1):wdw(2)))
% plot(noiseOnly(wdw(1):wdw(2)), 'r')
ylim([-15 35])
hold off

        