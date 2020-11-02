ix  =fn.iter=="iter-10" & fn.overlapdist=="uniform" & fn.overlapmod == "overlapmod-1.5.mat" & fn.noise=="noise-0.00"&fn.shape=="posNeg";
%ix = fn.overlapdist == "uniform" & fn.shape=="box" & fn.overlapmod == "overlapmod-1.5.mat" 


ix = ix & (fn.formula == "y~1+spl(dur,10)" | fn.formula == "y~1+dur" | fn.formula == "theoretical");
plot_result(fn(ix,:),'deconv',0)

plot_result(fn(ix,:),'deconv',1)

%%
ix = fn.iter=="iter-10" & fn.overlapdist=="uniform" & fn.overlapmod == "overlapmod-1.5.mat" & fn.noise=="noise-0.00"& fn.formula == "theoretical";
plot_result(fn(ix,:),'deconv',0)


%% Plot a single trial
durations = [ufresult_all{k}.param(2:end).value];
tmin = sum(ufresult_all{k}.times<=0);
sig = nan(size(ufresult_all{k}.beta));
for d = 1:length(durations)
    tmp= generate_signal_kernel(durations(d)*EEG.srate*options.overlapModifier,options.shape,EEG.srate);
    sig(1,tmin+1:min(tmin+length(tmp),end),d+1) = tmp(1:min(end,size(sig,2)-tmin));
end


ufresult_all{k}.abeta_original = sig;

%%
rng(1) % same seed

N_event = 500; % max number of events
emptyEEG = eeg_emptyset();
emptyEEG.srate = 100; %Hz
emptyEEG.pnts  = emptyEEG.srate*500; % total length in samples
T_event   = emptyEEG.srate*1.5; % total length of event-signal in samples


EEG = generate_eeg(emptyEEG,'posNeg',1,'uniform',0,1.5,N_event,T_event);
%%
figure,
ax = []
ax(1)= subplot(2,1,1)
plot(EEG.data)
ax(2) = subplot(2,1,2)
for e = 1:length(EEG.event)
    s = EEG.event(e).latency;
   
    dur = size(EEG.sim.sigAll,2);
    plot(s:s+dur-1,EEG.sim.sigAll(e,:))
    hold on
end
linkaxes(ax)