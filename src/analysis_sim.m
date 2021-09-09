%% -----------
%load data
folder = 'sim_realNoise'; % Change to desired folder;
                   % sim = initial simulation; sim2 = 2 event simulations; 
                   % sim2-1 = 2 events, double trials; sim3 = real events;
                   % sim_regularize = reularization
                   % sim_realNoise = real EEG noise used
                   % sim_newNoise = With SEREEGA noise
                   % sim_realNoise_regularize = real noise with
                   %                   regularization (only noise condition)

tmp_fn = dir(fullfile('/store/projects/unfold_duration/local',folder, '*.mat'));
tmp_fn = {tmp_fn.name};
fn = cellfun(@(x)strsplit(x,'_'),tmp_fn,'UniformOutput',false);
fn = cell2table(cat(1,fn{:}),'VariableNames',{'shape','overlap','overlapdist','noise','formula','durEffect','iter','overlapmod'});

%fn = parse_column(fn,'overlap');
%fn = parse_column(fn,'noise');
fn.filename = tmp_fn';

%% Load data
fn = load_sim_data(fn, folder, "box");

%%
%tmp = load(fullfile('local',folder,fn.filename{1}));

% ix  =fn.iter=="iter-10" & fn.overlapdist=="uniform" & fn.overlapmod == "overlapmod-2.0.mat" & fn.shape == "box" & fn.noise=="noise-0.00"&fn.overlap=="overlap-1";
ix  = fn.shape=="posHalf" & fn.durEffect == "durEffect-1" & fn.iter=="iter-42" & fn.overlapdist=="uniform" & fn.overlapmod == "overlapmod-1.5.mat" & fn.noise=="noise-1.00" & fn.overlap=="overlap-1" & fn.formula ~= "y~1";
% ix  =fn.iter=="iter-10" & fn.overlapdist=="uniform" & fn.overlapmod == "overlapmod-1.5.mat" & fn.noise=="noise-0.00"&fn.overlap=="overlap-0"& fn.formula ~= "y~1";
% ix  = fn.shape=="posNegPos" & fn.durEffect == "durEffect-1" & fn.iter=="iter-10" & fn.overlapdist=="uniform" & fn.overlapmod == "overlapmod-1.5.mat" & fn.noise=="noise-1.00"& fn.overlap=="overlap-1";
% ix  = fn.shape=="posNegPos" & fn.durEffect == "durEffect-0" & fn.iter=="iter-10" & fn.overlapdist=="uniform" & fn.overlapmod == "overlapmod-1.5.mat" & fn.noise=="noise-0.00"& fn.overlap=="overlap-1";

% ix = fn.overlapdist == "uniform" & fn.shape=="posNegPos" & fn.overlapmod == "overlapmod-1.5.mat" & fn.formula == "y~1";
plot_result(fn(ix,:))

%% Calculate some kind of deviance
% calculate MSE and Normalize toward y~1
fn = calc_sim_MSE(fn, folder);

%% Display MSE results
figure
fn_plot = fn(fn.overlapmod=="overlapmod-1.5.mat" & fn.durEffect == "durEffect-1",:);
g = gramm('x',fn_plot.shape,'y',fn_plot.normMSE,'color',fn_plot.formula,'marker',fn_plot.shape);

%g.stat_violin('dodge',1,'width',0.3)
g.geom_jitter('dodge',1);
%g.geom_line()
g.facet_grid(fn_plot.noise,fn_plot.overlap,'scale','free_y')
g.fig(fn_plot.overlapdist)
g.axe_property('ylim',[-0.1 1.5])
g.draw()
%% Display MSE results (section to change and plot specific results)
figure
fn_plot = fn(fn.overlapmod=="overlapmod-1.5.mat" & fn.durEffect == "durEffect-1" & fn.overlap == "overlap-1" & fn.shape == "posNegPos",:);
g = gramm('x',fn_plot.shape,'y',fn_plot.normMSE,'color',fn_plot.formula,'marker',fn_plot.shape);

%g.stat_violin('dodge',1,'width',0.3)
g.geom_jitter('dodge',1);
%g.geom_line()c
g.facet_grid(fn_plot.noise,fn_plot.overlap,'scale','free_y')
g.fig(fn_plot.overlapdist)
g.axe_property('ylim',[-0.1 1.5])
g.draw()
%% save table and ERPs individually
% writetable(fn(:,[1:8 11 12]),'local/2020-12-14_simulationResults_real_Noise.csv')

% fn= removevars(fn,{'beta', 'beta_nodc'});
%% duration distributions
% 
% all_splines(height(fn)) = struct();
% for r = 1:height(fn)
%     fprintf("Loading paramValues:%i/%i\n",r,height(fn))
%     tmp = load(fullfile('local',folder,fn.filename{r}));
%     % No splines in y ~1 (+ dur) so need to skip those
%     try
%         all_splines(r).paramValues = tmp.ufresult_marginal.unfold.splines{1}.paramValues;
%     catch
%         continue
%     end
%     clear tmp
% end
% 
% fn.paramValues = all_splines(:);
% figure()
% ix = fn.filename == "box_overlap-0_halfnormal_noise-0.00_y~1+spl(dur,10)_durEffect-1_iter-42_overlapmod-1.5.mat";
% histogram(fn{ix,'paramValues'}.paramValues,100)
% figure()
% ix = fn.filename == "box_overlap-0_uniform_noise-0.00_y~1+spl(dur,10)_durEffect-1_iter-42_overlapmod-1.5.mat";
% histogram(fn{ix,'paramValues'}.paramValues,100)

