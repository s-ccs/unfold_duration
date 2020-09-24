%% Generate Signal

rng(1) % same seed
ufresult_all = {};
N_event = 500; % max number of events
emptyEEG = eeg_emptyset();
emptyEEG.srate = 100; %Hz
emptyEEG.pnts  = emptyEEG.srate*500; % total length in samples
T_event   = emptyEEG.srate*1.5; % total length of event-signal in samples


for iter = 1:50
for shape = {'box','posNeg','posNegPos','hanning'}
    for overlap = [0 1]
        for overlapdistribution ={'uniform','halfnormal'}
            for noise = [0 1]
                for overlapModifier = [1 1.5 2]
                    rng(iter) % same seed
                    %% Simulate data with the given properties
                    EEG = generate_eeg(emptyEEG,shape{1},overlap,overlapdistribution{1},noise,overlapModifier,N_event,T_event);
                    center= quantile([EEG.event.dur],linspace( 1/(10+1), 1-1/(10+1), 10));
                    binEdges = conv([-inf center inf], [0.5, 0.5], 'valid');
                    [~,~,indx] = histcounts([EEG.event.dur],binEdges);
                    for e = 1:length(EEG.event)
                        EEG.event(e).durbin = binEdges(indx(e));
                    end
                    
                    
                    for formula = {'y~1'
                            'y~1+cat(durbin)'
                            'y~1+dur'
                            'y~1+spl(dur,5)'
                            'y~1+spl(dur,10)'
                            'theoretical'}'
                        
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
                        filename = sprintf('%s_overlap-%i_%s_noise-%.2f_%s_iter-%i_overlapmod-%.1f.mat',shape{1},overlap,overlapdistribution{1},noise,formula{1},iter,overlapModifier);
                        if ~exist(fullfile('local','sim'),'dir')
                            mkdir(fullfile('local','sim'))
                        end
                        save(fullfile('local','sim',filename),'ufresult_marginal')
                    end
                    
                end
            end
        end
    end
end
end

%%
%% -----------
%load data
tmp_fn = dir(fullfile('local','sim','*.mat'));
tmp_fn = {tmp_fn.name};
fn = cellfun(@(x)strsplit(x,'_'),tmp_fn,'UniformOutput',false);
fn = cell2table(cat(1,fn{:}),'VariableNames',{'shape','overlap','overlapdist','noise','formula','iter','overlapmod'});

%fn = parse_column(fn,'overlap');
%fn = parse_column(fn,'noise');
fn.filename = tmp_fn';
%%
all_b = nan(height(fn),1,200,11);
all_bnodc = nan(height(fn),1,200,11);
for r = 1:height(fn)
    fprintf("Loading :%i/%i\n",r,height(fn))
    
    tmp = load(fullfile('local','sim',fn.filename{r}));
    b = tmp.ufresult_marginal.beta;
    b_nodc = tmp.ufresult_marginal.beta_nodc;
    if strcmp(fn{r,'formula'},'y~1')
        b = repmat(b,1,1,11);
        b_nodc = repmat(b_nodc,1,1,11);
    end
    
    if strcmp(fn{r,'formula'},'y~1+cat(durbin)')
        b(:,:,2:end+1) = b(:,:,1:end);
        b_nodc(:,:,2:end+1) = b_nodc(:,:,1:end);
    end
    
    all_b(r,:,:,:) = b;
    all_bnodc(r,:,:,:) =  b_nodc;

    %fn{r,'ufresult'} = tmp.ufresult_marginal;
end

%      fn.beta = all_b;
%      fn.beta_nodc = all_bnodc;
    
%%
%tmp = load(fullfile('local','sim',fn.filename{1}));

ix  =fn.overlapmod == "overlapmod-1.5.mat" & fn.shape == "box" & fn.noise=="noise-0.00"&fn.overlap=="overlap-0";
%ix = fn.overlapdist == "uniform" & fn.shape=="box" & fn.overlapmod == "overlapmod-1.5.mat" 
plot_result(fn(ix,:))

%% Calculate some kind of deviance
for r = 1:height(fn)
    fprintf("Deviance :%i/%i\n",r,height(fn))
    row = fn(r,:);
    % we have to find the corresponding theoretical result to calculate the
    % deviance function
    
    % check rows except formula
    ix = cellfun(@(x,ix)strcmp(x,fn{:,ix}),row{:,[1:4 6:7]},num2cell([1:4 6:7]),'UniformOutput',false);
    ix_theo = all(cat(2,ix{:}),2) & fn.formula == "theoretical";
    assert(sum(ix_theo) == 1)
    y_true = fn{ix_theo,'beta'}(:,:,2:end);
    y_true(isnan(y_true(:))) = 0;
    y_est = row.beta(:,:,2:end);
    y_est(isnan(y_est(:))) = 0; % can happen in case of theoretical
    dev = sum((y_true(:) - y_est(:)).^2);
    fn{r,'MSE'} = dev;
end
for r = 1:height(fn)
        fprintf("Deviance :%i/%i\n",r,height(fn))
    row = fn(r,:);
    ix = cellfun(@(x,ix)strcmp(x,fn{:,ix}),row{:,[1:4 6:7]},num2cell([1:4 6:7]),'UniformOutput',false);

    % normalize MSE by y~1
    ix_intercept = all(cat(2,ix{:}),2) & fn.formula == "y~1";
    assert(sum(ix_intercept) == 1)
    
    fn{r,'normMSE'} = fn{r,'MSE'}/fn{ix_intercept,'MSE'};
    
end

%% Display MSE results
figure
fn_plot = fn(fn.overlapmod=="overlapmod-1.5.mat"&fn.overlapdist=="uniform"&fn.overlap=="overlap-1",:);
g = gramm('x',fn_plot.shape,'y',fn_plot.normMSE,'color',fn_plot.formula,'marker',fn_plot.shape);

%g.stat_violin('dodge',1,'width',0.3)
g.geom_jitter('dodge',1);
%g.geom_line()
%g.facet_grid(fn_plot.shape,fn_plot.overlap,'scale','free_y')
g.draw()

%% duration distributions
ix = fn.filename == "box_overlap-0_halfnormal_noise-0.00_y~1+spl(dur,10)_overlapmod-1.500000e+00.mat";
histogram(fn{ix,'ufresult'}.unfold.splines{1}.paramValues,100)
ix = fn.filename == "box_overlap-0_uniform_noise-0.00_y~1+spl(dur,10)_overlapmod-1.500000e+00.mat";
histogram(fn{ix,'ufresult'}.unfold.splines{1}.paramValues,100)