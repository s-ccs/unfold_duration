%% -----------
%load data
folder = '20240618_sim_realNoise_HanningShapes_filtered_blockdesign'; % Change to desired folder;
                   % sim = initial simulation; sim2 = 2 event simulations; 
                   % sim2-1 = 2 events, double trials; sim3 = real events;
                   % sim_regularize = reularization
                   % sim_realNoise = real EEG noise used
                   % sim_realNoise_filtered = filtered at 0.5
                   % sim_newNoise = With SEREEGA noise
                   % sim_realNoise_regularize = real noise with
                   %    regularization (only noise condition)
                   % sim_realNoise_regularize_filtered = filtered at 0.5
                   % sim_realNoise_regularize_filtered01 = filtered at 0.1
                   % sim_realNoise_scaledHanning_regularize_filtered =
                   %    scaled Hanning shape only; regularized
                   %
                   % "sim_realNoise_HanningShapes_filtered"= final three shapes used
                   % 20240227_sim_realNoise_HanningShapes_filtered = after
                   % theoretical filter bugfix
                   % 20240315_sim_realNoise_HanningShapes_regularize_filtered
                   % sim_realNoise_HanningShapes
                   % sim_realNoise_HanningShapes_regularize_filtered
                   % 'sim_realNoise_playground' = various;
                   % 20240416_sim_realNoise_HanningShapes_regularize_filtered_jittered
                   % 20240422_sim_realNoise_HanningShapes_filtered_highSNR
                   % 20240424_sim_realNoise_HanningShapes_filtered_onlyNoise
                   % 20240429_sim_realNoise_HanningShapes_filtered_1.0_onlyNoise
                   % 20240508_sim_realNoise_HanningShapes_filtered_blockdesign_onlyNoise
                   % 20240508_sim_realNoise_HanningShapes_filtered_blockdesign
                   % 20240618_sim_realNoise_HanningShapes_filtered_blockdesign
                   % (20240618 after bugfix where only one shape was
                   % shifted)
                   % 20240618_sim_realNoise_HanningShapes_filtered_blockdesign_onlyNoise
                   % 20240618_sim_realNoise_HanningShapes_filtered_onlyNoise
                    
csv_flag = 0; % Indicate if loading should NOT (= 0) look for an existing csv Result/MSE file; overwrites existing CSV results;
tmp_fn = dir(fullfile('/store/projects/unfold_duration/local',folder, '*.mat'));
tmp_fn = {tmp_fn.name};
fn = cellfun(@(x)strsplit(x,'_'),tmp_fn,'UniformOutput',false);
fn = cell2table(cat(1,fn{:}),'VariableNames',{'shape','overlap','overlapdist','noise','formula','durEffect','iter','overlapmod'});

%fn = parse_column(fn,'overlap');
%fn = parse_column(fn,'noise');
fn.filename = tmp_fn';

%% Load data
fn = load_sim_data(fn, folder, csv_flag);

%%
%tmp = load(fullfile('local',folder,fn.filename{1}));

% ix  =fn.iter=="iter-10" & fn.overlapdist=="uniform" & fn.overlapmod == "overlapmod-2.0.mat" & fn.shape == "box" & fn.noise=="noise-0.00"&fn.overlap=="overlap-1";
% ix  = fn.shape=="posHalf" & fn.durEffect == "durEffect-1" & fn.iter=="iter-42" & fn.overlapdist=="uniform" & fn.overlapmod == "overlapmod-1.5.mat" & fn.noise=="noise-1.00" & fn.overlap=="overlap-1" & fn.formula ~= "y~1";
% ix  =fn.iter=="iter-10" & fn.overlapdist=="uniform" & fn.overlapmod == "overlapmod-1.5.mat" & fn.noise=="noise-0.00"&fn.overlap=="overlap-0"& fn.formula ~= "y~1";
% ix  = fn.shape=="posHalf" & fn.durEffect == "durEffect-1" & fn.iter=="iter-48" & fn.overlapdist=="halfnormal" & fn.overlapmod == "overlapmod-1.5.mat" & fn.noise=="noise-1.00"& fn.overlap=="overlap-0" & fn.formula ~= "y~1";
% ix  = fn.shape=="posNegPos" & fn.durEffect == "durEffect-0" & fn.iter=="iter-10" & fn.overlapdist=="uniform" & fn.overlapmod == "overlapmod-1.5.mat" & fn.noise=="noise-0.00"& fn.overlap=="overlap-1";
% ix  = fn.shape=="scaledHanning" & fn.durEffect == "durEffect-0" & fn.iter=="iter-27" & fn.overlapdist=="halfnormal" & fn.overlapmod == "overlapmod-1.5.mat" & fn.noise=="noise-1.00"& fn.overlap=="overlap-1" & fn.formula ~= "y~1"; % This one was used for the Figure in paper
ix  = fn.shape=="scaledHanning" & fn.durEffect == "durEffect-0" & fn.iter=="iter-40" & fn.overlapdist=="uniform" & fn.overlapmod == "overlapmod-1.5.mat" & fn.noise=="noise-1.00"& fn.overlap=="overlap-1" & fn.formula ~= "y~1"; 


% ix = fn.overlapdist == "uniform" & fn.shape=="posNegPos" & fn.overlapmod == "overlapmod-1.5.mat" & fn.formula == "y~1";
g = plot_result(fn(ix,:));
for a = 1:length(g.facet_axes_handles); g.facet_axes_handles(a).YLim = [-8 20]; end
% hold all
% ylim([-0.5 20])

% saveas(gcf, '20240525QualiResults', 'epsc')
%% Calculate some kind of deviance
% calculate MSE and Normalize toward y~1
fn_MSE = calc_sim_MSE(fn, folder, csv_flag);

%% Find best/ worst MSE for given ix
ix_MSE  = fn_MSE.shape=="scaledHanning" & fn_MSE.durEffect == "durEffect-1" & fn_MSE.overlapdist=="uniform" & fn_MSE.overlapmod == "overlapmod-1.5.mat" & fn_MSE.noise=="noise-1.00"& fn_MSE.overlap=="overlap-1" & fn_MSE.formula == "y~1+spl(dur,10)";
ix_MSE_noDur  = fn_MSE.shape=="scaledHanning" & fn_MSE.durEffect == "durEffect-0" & fn_MSE.overlapdist=="halfnormal" & fn_MSE.overlapmod == "overlapmod-1.5.mat" & fn_MSE.noise=="noise-1.00"& fn_MSE.overlap=="overlap-1" & fn_MSE.formula ~= "theoretical";

min_iter = find(fn_MSE.normMSE == min(fn_MSE.normMSE(ix_MSE,:)));
max_iter = find(fn_MSE.normMSE == max(fn_MSE.normMSE(ix_MSE,:)));
min_iter_noDur = find(fn_MSE.normMSE == min(fn_MSE.normMSE(ix_MSE_noDur,:)));
max_iter_noDur = find(fn_MSE.normMSE == max(fn_MSE.normMSE(ix_MSE_noDur,:)));

%%
fn_MSE.iter(min_iter)
% fn_MSE.MSE(min_iter_noDur)

%% Display MSE results
figure
fn_plot = fn_MSE;
g = gramm('x',fn_plot.shape,'y',fn_plot.normMSE,'color',fn_plot.formula,'marker',fn_plot.shape);

%g.stat_violin('dodge',1,'width',0.3)
g.geom_jitter('dodge',1);
%g.geom_line()
g.facet_grid(fn_plot.noise,fn_plot.overlap,'scale','free_y')
g.fig(fn_plot.overlapdist)
%g.axe_property('ylim',[-0.1 1.5])
g.draw()
%% Display MSE results (section to change and plot specific results)
figure
fn_plot = fn_MSE(fn_MSE.shape=="scaledHanning" & fn_MSE.overlapmod=="overlapmod-1.5.mat" & fn_MSE.durEffect == "durEffect-1" & fn_MSE.noise=="noise-1.00"& fn_MSE.overlap=="overlap-1",:);
g = gramm('x',fn_plot.shape,'y',fn_plot.MSE,'color',fn_plot.formula,'marker',fn_plot.shape);

%g.stat_violin('dodge',1,'width',0.3)
g.geom_jitter('dodge',1);
%g.geom_line()c
g.facet_grid(fn_plot.noise,fn_plot.overlap,'scale','free_y')
g.fig(fn_plot.overlapdist)
% g.axe_property('ylim',[-0.1 1.5])
g.draw()

%% Display MSE mean results with SD (section to change and plot specific results)

figure
fn_plot = fn_MSE(fn_MSE.overlapmod=="overlapmod-1.5.mat" & fn_MSE.durEffect == "durEffect-1" & fn_MSE.noise=="noise-1.00"& fn_MSE.overlap=="overlap-1",:);
g = gramm('x',fn_plot.shape,'y',fn_plot.MSE,'color',fn_plot.formula,'marker',fn_plot.shape);

% g.stat_violin('dodge',1,'width',0.3)
g.stat_violin('normalization','count');
g.stat_boxplot('width',0.15);
% g.stat_boxplot('dodge',1,'width',0.3)
% g.stat_summary('dodge',1,'width',0.3, 'type', 'quartile')
% g.geom_jitter('dodge',1);
%g.geom_line()

g.facet_grid(fn_plot.noise,fn_plot.overlap,'scale','free_y')
g.fig(fn_plot.overlapdist)
% g.axe_property('ylim',[-0.1 1.5])
g.draw()
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

