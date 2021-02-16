%% -----------
%load data
folder = 'sim_harm'; % Change to desired folder;
                   % sim = initial simulation; sim2 = 2 event simulations; 
                   % sim2-1 = 2 events, double trials; sim3 = real events
                   
tmp_fn = dir(fullfile('local',folder,'*.mat'));
tmp_fn = {tmp_fn.name};
fn = cellfun(@(x)strsplit(x,'_'),tmp_fn,'UniformOutput',false);
fn = cell2table(cat(1,fn{:}),'VariableNames',{'shape','overlap','overlapdist','noise','formula','durEffect','iter','overlapmod'});

%fn = parse_column(fn,'overlap');
%fn = parse_column(fn,'noise');
fn.filename = tmp_fn';

all_b = nan(height(fn),1,250,11); % needed change to 250 (maybe because of durEffect); was 200
all_bnodc = nan(height(fn),1,250,11);
for r = 1:height(fn)
    if ~mod(r, 500)
    fprintf("Loading :%i/%i\n",r,height(fn))
    end
    tmp = load(fullfile('local',folder,fn.filename{r}));
    b = tmp.ufresult_marginal.beta;
    b_nodc = tmp.ufresult_marginal.beta_nodc;
    if strcmp(fn{r,'formula'},'y~1')
        %         continue
        b = repmat(b(:,:,1),1,1,11);
        b_nodc = repmat(b_nodc(:,:,1),1,1,11);
%     else
%         b = tmp.ufresult_marginal.beta(:,:,1:11);
%         b_nodc = tmp.ufresult_marginal.beta_nodc(:,:,1:11);
    end
    
    if strcmp(fn{r,'formula'},'y~1+cat(durbin)')
%         continue
        b(:,:,2:end+1) = b(:,:,1:end);
        b_nodc(:,:,2:end+1) = b_nodc(:,:,1:end);
    end
    
    all_b(r,:,:,:) = b;
    all_bnodc(r,:,:,:) =  b_nodc;

    %fn{r,'ufresult'} = tmp.ufresult_marginal;
end

fn.beta = squeeze(all_b);
fn.beta_nodc = squeeze(all_bnodc);
fn.folder =repmat({folder},1,height(fn))';
%%
%tmp = load(fullfile('local',folder,fn.filename{1}));

% ix  =fn.iter=="iter-10" & fn.overlapdist=="uniform" & fn.overlapmod == "overlapmod-2.0.mat" & fn.shape == "box" & fn.noise=="noise-0.00"&fn.overlap=="overlap-1";
ix  = fn.shape=="hanning" & fn.durEffect == "durEffect-1" & fn.iter=="iter-42" & fn.overlapdist=="uniform" & fn.overlapmod == "overlapmod-1.5.mat" & fn.noise=="noise-0.00"& fn.overlap=="overlap-1" & fn.formula ~= "y~1";
% ix  =fn.iter=="iter-10" & fn.overlapdist=="uniform" & fn.overlapmod == "overlapmod-1.5.mat" & fn.noise=="noise-0.00"&fn.overlap=="overlap-0"& fn.formula ~= "y~1";
%ix = fn.overlapdist == "uniform" & fn.shape=="box" & fn.overlapmod == "overlapmod-1.5.mat" 
plot_result(fn(ix,:))

%% Calculate some kind of deviance
for r = 1:height(fn)
    if ~mod(r,500)
    fprintf("Deviance :%i/%i\n",r,height(fn))
    end
    row = fn(r,:);
    % we have to find the corresponding theoretical result to calculate the
    % deviance function
    
    % check rows except formula
    ix = cellfun(@(x,ix)strcmp(x,fn{:,ix}),row{:,[1:4 6:8]},num2cell([1:4 6:8]),'UniformOutput',false);
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
    if ~mod(r,500)
        fprintf("Normalize :%i/%i\n",r,height(fn))
    end
    row = fn(r,:);
    ix = cellfun(@(x,ix)strcmp(x,fn{:,ix}),row{:,[1:4 6:8]},num2cell([1:4 6:8]),'UniformOutput',false)

    % normalize MSE by y~1
    ix_intercept = all(cat(2,ix{:}),2) & fn.formula == "y~1";
    assert(sum(ix_intercept) == 1)
    
    fn{r,'normMSE'} = fn{r,'MSE'}/fn{ix_intercept,'MSE'};
    
end

%% Display MSE results
figure
fn_plot = fn(fn.overlapmod=="overlapmod-1.5.mat" & fn.durEffect == "durEffect-0",:);
g = gramm('x',fn_plot.shape,'y',fn_plot.normMSE,'color',fn_plot.formula,'marker',fn_plot.shape);

%g.stat_violin('dodge',1,'width',0.3)
g.geom_jitter('dodge',1);
%g.geom_line()
g.facet_grid(fn_plot.noise,fn_plot.overlap,'scale','free_y')
g.fig(fn_plot.overlapdist)
g.axe_property('ylim',[-0.1 1.5])
g.draw()

%% duration distributions
ix = fn.filename == "box_overlap-0_halfnormal_noise-0.00_y~1+spl(dur,10)_overlapmod-1.500000e+00.mat";
histogram(fn{ix,'ufresult'}.unfold.splines{1}.paramValues,100)
ix = fn.filename == "box_overlap-0_uniform_noise-0.00_y~1+spl(dur,10)_overlapmod-1.500000e+00.mat";
histogram(fn{ix,'ufresult'}.unfold.splines{1}.paramValues,100)

%% save table and ERPs individually
% writetable(fn(:,[1:8 11 12]),'local/2020-12-14_simulationResults_harm.csv')
