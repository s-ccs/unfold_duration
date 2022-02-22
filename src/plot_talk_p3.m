%%
tmp_fn_p3 = dir(fullfile('/store/projects/unfold_duration/local','p3','*.mat')); % Folders: p3; p3_button; p3_Stim+Button
tmp_fn_p3 = {tmp_fn_p3.name};
fn_p3 = cellfun(@(x)strsplit(x,'_'),tmp_fn_p3,'UniformOutput',false);
fn_p3 = cell2table(cat(1,fn_p3{:}),'VariableNames',{'sub','formula'});


%fn_p3 = parse_column(fn_p3,'overlap');
%fn_p3 = parse_column(fn_p3,'noise');
fn_p3.filename = tmp_fn_p3';
fn_p3.folder = repmat({'p3'},1,height(fn_p3))';
%
if fn_p3.folder{1} == "p3_Stim+Button"
    all_b = nan(height(fn_p3),31,512,20);
    all_bnodc = nan(height(fn_p3),31,512,20);
else
    all_b = nan(height(fn_p3),31,512,10);
    all_bnodc = nan(height(fn_p3),31,512,10);
end

for r = [1:75 79:height(fn_p3)] % Jump over sets with only 3 betas, only subject 37
    fprintf("Loading :%i/%i\n",r,height(fn_p3))
    
    tmp = load(fullfile('/store/projects/unfold_duration/local',fn_p3.folder{r},fn_p3.filename{r}));
    b = tmp.ufresult_a.beta(:,:,:);
    b_nodc = tmp.ufresult_a.beta_nodc(:,:,:);
    if strcmp(fn_p3{r,'formula'},'formula-y~1+cat(trialtype).mat')
        if fn_p3.folder{r} == "p3_Stim+Button"
            b(:,:,8:10) = b(:,:,2:4);
            b(:,:,2:7) = repmat(b(:,:,1),1,1,6);
            b(:,:,20) = b(:,:,10);
            b(:,:,10:19) = repmat(b(:,:,9),1,1,10);
            b_nodc(:,:,8:10) = b_nodc(:,:,2:4);
            b_nodc(:,:,2:7) = repmat(b_nodc(:,:,1),1,1,6);
            b_nodc(:,:,20) = b_nodc(:,:,10);
            b_nodc(:,:,10:19) = repmat(b_nodc(:,:,9),1,1,10);
        else
            b(:,:,8:10) = b(:,:,2:4);
            b(:,:,2:7) = repmat(b(:,:,1),1,1,6);
            b_nodc(:,:,8:10) = b_nodc(:,:,2:4);
            b_nodc(:,:,2:7) = repmat(b_nodc(:,:,1),1,1,6);
        end
    end
    
    
    all_b(r,:,:,:) = b;
    all_bnodc(r,:,:,:) =  b_nodc;

    %fn_p3{r,'ufresult'} = tmp.ufresult_marginal;
end
fn_p3.beta = squeeze(all_b);
fn_p3.beta_nodc = squeeze(all_bnodc);

%
% plot_result(fn_p3(1,:),'channel',21)

% GA
groupIx = findgroups(fn_p3.formula);
GA = splitapply(@(x)trimmean(x,10),fn_p3.beta,groupIx);
GA_nodc = splitapply(@(x)trimmean(x,10),fn_p3.beta_nodc,groupIx);
fn_p3_ga = table(unique(fn_p3.formula),GA,GA_nodc,'VariableNames',{'formula','beta','beta_nodc'});
fn_p3_ga.folder = repmat({'p3'},1,height(fn_p3_ga))';
fn_p3_ga.filename = fn_p3{1:3,'filename'};

GA_mean = splitapply(@(x)mean(x),fn_p3.beta,groupIx);
GA_median = splitapply(@(x)median(x),fn_p3.beta,groupIx);
fn_p3_ga_outlier= table(unique(fn_p3.formula),GA,GA_mean,GA_median,'VariableNames',{'formula','beta_trimmean','beta_mean','beta_median'});
%%
figure,plot(linspace(-1,1,512),squeeze(fn_p3_ga_outlier.beta_trimmean(1,21,:,1)));
hold all, 
plot(linspace(-1,1,512),squeeze(fn_p3_ga_outlier.beta_mean(1,21,:,1)))
plot(linspace(-1,1,512),squeeze(fn_p3_ga_outlier.beta_median(1,21,:,1)))
legend('20% trimmed mean','mean','median')
box off
%%
tmp =  load(fullfile("/store/projects/unfold_duration/local",fn_p3.folder{1},fn_p3.filename{2}));
uf = tmp.ufresult_a;
d = permute(fn_p3_ga{3,'beta_nodc'},[2 3 4 1]);
colors = [2 219 240;2 75 120;255 181 91;186 88 0]./255;

%% ERP Plot Stimulus
tmp =  load(fullfile("/store/projects/unfold_duration/local",fn_p3.folder{1},fn_p3.filename{2}));
uf = tmp.ufresult_a;
times = repmat(uf.times,3,1)';
group = repmat([1:3],512,1);
grouplist ={'distractor','target', 'difference'};
group = grouplist(group);

% Colour scheme in RGB [N by 3]
colors = [2 219 240; 2 75 120; 255 181 91; 186 88 0; 190 190 190]./255;

% For pure diff plot
diff_mat = [];
diff_times = repmat(uf.times,4,1)';
diff_group = repmat([1:4],512,1);
diff_list = {'classical', 'overlap modelled', 'reaction-time modelled', 'reaction-time and overlap modelled'};
diff_group = diff_list(diff_group);
diff_colors = [0 255 255;
               0 255 128;
               0 128 255;
               0 0 255]./255;

for modelRT = [3 2]
    if modelRT == 3
        RTmodelled = "no-RT";
    else
        RTmodelled = "yes-RT";
    end
for beta = {'beta_nodc','beta'}
    d = permute(fn_p3_ga{modelRT,beta{1}},[2 3 4 1]); % Just to take care of singleton dimension
    
    % d_sub = squeeze(fn_p3.beta(groupIx == 3,21,:,1:2));
    
    for k = 1%:2
        if k == 1
            ix = [1 8];
        else
            if fn_p3.folder{1} == "p3_Stim+Button"
                ix = [9 20];
                ixd{2} = [9 20];
            else
                ix = 9:10;
            end
        end
        
        data = squeeze(d(21,:,ix));
        data_diff = data(:,2) - data(:,1);%calculate difference wave
        data = [data data_diff];
        diff_mat = [diff_mat, data_diff];
        
        figure
        g = gramm('x',times(:),'y',data(:),'color',group(:));
        
        g.geom_line()
        g.set_text_options('base_size',14)
        g.set_color_options('map', colors([5 (k-1)*2+(1:2)],:))
        ax = g.draw();
%         ax.facet_axes_handles(1).YLim = [-6 15];
        
        xlabel(ax.facet_axes_handles(1),'time [s]');
        ylabel(ax.facet_axes_handles(1),'ERP [µV]');
%         ax.facet_axes_handles(1).YLim = [-6.5 12];
        if k == 1
            ax.facet_axes_handles(1).XLim = [-0.2 1];
            ax.facet_axes_handles(1).YLim = [-10 12];
        else
            ax.facet_axes_handles(1).XLim = [-1 1];
        end
        set(gcf,'name',sprintf('beta-%s_%s',beta{1}, RTmodelled))

    end
end
end

% 
% Figure for Difference waves on one plot
figure
g = gramm('x',diff_times(:),'y',diff_mat(:),'color',diff_group(:));

g.geom_line()
g.set_text_options('base_size',14)
g.set_color_options('map', diff_colors)
ax = g.draw();

xlabel(ax.facet_axes_handles(1),'time [s]');
ylabel(ax.facet_axes_handles(1),'ERP [µV]');
ax.facet_axes_handles(1).YLim = [-6.5 12];
ax.facet_axes_handles(1).XLim = [-0.2 1];
set(gcf,'name','Difference Waves')
        
       
%% RT distributions
% collect all RTs
tablesplines= fn_p3(groupIx == 2,:);
grouplist ={'distractor','target'};

t = [];
for k = 1:height(tablesplines)
    tmp = load(fullfile('local','p3',tablesplines.filename{k}));
    paramval = tmp.ufresult_a.unfold.splines{1}.paramValues;
    type = tmp.ufresult_a.unfold.X(:,2);    
    type(isnan(paramval(1:length(type)))) = [];
    paramval(isnan(paramval)) = [];
    
    tSingle = table(repmat({fn_p3.sub{k}},length(paramval),1),paramval',grouplist(type+1)','VariableNames',{'sub','rt','condition'});
    t = [t;tSingle];
end
%% Draw Reaction Time Density distributions
figure,
g = gramm('x',t.rt/1000,'group',t.sub,'color',t.condition);
g.stat_density()
g.set_color_options('map', colors(1:2,:));
% g.set_color_options('map', [0.5 0.5 0.5])

g.set_text_options('base_size',14)

ax = g.draw();
xlabel(ax.facet_axes_handles(1),'reaction time [s]');

%% Draw RT effects
for inset = [0 1];
for beta = {'beta_nodc','beta'}

d = permute(fn_p3_ga{:,beta{1}},[2 3 4 1]);
times = repmat(uf.times,6,1)';
group = repmat([1:6],512,1);
grouplist = [200:50:450];
group = grouplist(group);
for k = 3%[2 1 3]
    if k == 3 & inset == 1
        continue
    end
    if k == 2
    data = squeeze(d(21,:,3:8,k));
    else
    data = squeeze(d(21,:,2:7,k));
    end
    figure
    g = gramm('x',times(:),'y',data(:),'color',group(:),'group',group(:));
    
    g.geom_line()
    g.set_names('color','RT')
    g.set_text_options('base_size',14)
     if k == 3
       
        g.set_continuous_color('LCH_colormap', [0 0; 0 1; 0 1])
     else
    g.set_continuous_color('colormap','bamako')
     end
    ax = g.draw();
    xlabel(ax.facet_axes_handles(1),'time [s]');
    ylabel(ax.facet_axes_handles(1),'ERP [µV]');
    ax.facet_axes_handles(1).YLim = [-6.5 6.5];
    
    if inset
        ax.facet_axes_handles(1).YLim = [-4 2];
        ax.facet_axes_handles(1).XLim = [0.1 0.3];
    else
        ax.facet_axes_handles(1).XLim = [-0.2 1.0];
    end
    set(gcf,'name',sprintf('beta-%s_%s',beta{1},fn_p3_ga.formula{k}(1:end-4)))
   
end
end
end
%%

%%
%% Draw DC comparison
d = permute(fn_p3_ga{:,'beta'},[2 3 4 1]);
imola = load('lib/ScientificColourMaps6/imola.mat')
times = repmat(uf.times,6,1)';
group = repmat([1:6],512,1);
grouplist = [200:50:450];
group = grouplist(group);
for k = 1:3;%[2 1 3]
    if k == 2
    data = squeeze(d(21,:,3:8,k));
    else
    data = squeeze(d(21,:,2:7,k));
    end
    figure
    g = gramm('x',times(:),'y',data(:),'color',group(:),'group',group(:));
    
    g.geom_line()
    g.set_names('color','RT')
    g.set_text_options('base_size',14)
    g.set_continuous_color('colormap','bamako')
    ax = g.draw();

    xlabel(ax.facet_axes_handles(1),'time [s]');
    ylabel(ax.facet_axes_handles(1),'ERP [µV]');
    ax.facet_axes_handles(1).YLim = [-10 3.5];
    
    %inset
    %ax.facet_axes_handles(1).YLim = [-8 -2];
    %ax.facet_axes_handles(1).XLim = [0.1 0.3];
    %ax.facet_axes_handles(1).XLim = [-0.1 0.6];
    
end
%% draw single subject estimates
d = permute(fn_p3{:,'beta'},[2 3 4 1]);
formulas = unique(fn_p3.formula);
nsub = 9; %(size(d,4)/length(formulas));
times = repmat(uf.times,6,1,nsub);
times = permute(times,[2 1 3]);
sub = repmat(1:nsub,512,1,6);
sub = permute(sub,[1 3 2]);
group = repmat([1:6],512,1,nsub);
group = permute(group,[1 2 3]);
grouplist = [200:50:450];
group = grouplist(group);
for k = 1:3;%[2 1 3]
    switch k
        case 2
    data = squeeze(d(21,:,3:8,find(fn_p3.formula == string(formulas{k}),9)));
        case 1
    
            data = squeeze(d(21,:,2:7,find(fn_p3.formula == string(formulas{k}),9)));
        case 3
            data = squeeze(d(21,:,2,find(fn_p3.formula == string(formulas{k}),9)));
            times = times(:,1,:);
            sub = sub(:,1,:);
            group = group(:,1,:);
        otherwise
            error
    end
    figure
    g = gramm('x',times(:),'y',data(:),'color',group(:));
    
    g.geom_line()
    g.facet_wrap(sub,'scale','free_y','column_labels',false)
    g.set_names('color','RT')
    g.set_text_options('base_size',14)
    g.set_continuous_color('colormap','bamako')
    ax = g.draw();

    xlabel(ax.facet_axes_handles(1),'time [s]');
    ylabel(ax.facet_axes_handles(1),'ERP [µV]');
    ax.facet_axes_handles(1).YLim = [-10 3.5];
    
    %inset
    %ax.facet_axes_handles(1).YLim = [-8 -2];
    %ax.facet_axes_handles(1).XLim = [0.1 0.3];
    %ax.facet_axes_handles(1).XLim = [-0.1 0.6];
    
end