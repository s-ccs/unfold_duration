%%
tmp =  load(fullfile("local",fn.folder{1},fn.filename{1}));
uf = tmp.ufresult_a;
d = permute(fn_ga{3,'beta_nodc'},[2 3 4 1]);
colors = [2 219 240;2 75 120;255 181 91;186 88 0]./255;

%% ERP Plot Stimulus

times = repmat(uf.times,2,1)';


group = repmat([1:2],512,1);
grouplist ={'distractor','target'};
group = grouplist(group);

% d_sub = squeeze(fn.beta(groupIx == 3,21,:,1:2));

for k = 1:2
    if k == 1
        ix = 1:2;
    else
        ix = 3:4;
    end
    data = squeeze(d(21,:,ix));
    figure
    g = gramm('x',times(:),'y',data(:),'color',group(:));
    
    g.geom_line()
    g.set_text_options('base_size',14)
    g.set_color_options('map', colors(ix,:))
    ax = g.draw();
    xlabel(ax.facet_axes_handles(1),'time [s]');
    ylabel(ax.facet_axes_handles(1),'ERP [µV]');
end


%% RT distributions
% collect all RTs
tablesplines= fn(groupIx == 2,:);
grouplist ={'distractor','target'};

t = [];
for k = 1:height(tablesplines)
    tmp = load(fullfile('local','p3',tablesplines.filename{k}));
    paramval = tmp.ufresult_a.unfold.splines{1}.paramValues;
    type = tmp.ufresult_a.unfold.X(:,2);
    type(isnan(paramval(1:length(type)))) = [];
    paramval(isnan(paramval)) = [];
    
    tSingle = table(repmat({fn.sub{k}},length(paramval),1),paramval',grouplist(type+1)','VariableNames',{'sub','rt','condition'});
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

%% Draw nodc comparison
d = permute(fn_ga{:,'beta_nodc'},[2 3 4 1]);
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
    ax.facet_axes_handles(1).YLim = [-6.5 6.5];
    
    ax.facet_axes_handles(1).YLim = [-4 2];
    ax.facet_axes_handles(1).XLim = [0.1 0.3];
    
end
%%
%% ERP Plot Stimulus
times = repmat(uf.times,2,1)';
group = repmat([1:2],512,1);
grouplist ={'distractor','target'};
group = grouplist(group);
d_dc = permute(fn_ga{3,'beta'},[2 3 4 1]);

% d_sub = squeeze(fn.beta(groupIx == 3,21,:,1:2));

for k = 1:2
    if k == 1
        ix = [1 8];
    else
        ix = 9:10;
    end
    data = squeeze(d_dc(21,:,ix));
    figure
    g = gramm('x',times(:),'y',data(:),'color',group(:));
    
    g.geom_line()
    g.set_text_options('base_size',14)
    g.set_color_options('map', colors((k-1)*2+(1:2),:))
    ax = g.draw();
    xlabel(ax.facet_axes_handles(1),'time [s]');
    ylabel(ax.facet_axes_handles(1),'ERP [µV]');
end
%%
%% Draw DC comparison
d = permute(fn_ga{:,'beta'},[2 3 4 1]);
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
    
    ax.facet_axes_handles(1).YLim = [-8 -2];
    ax.facet_axes_handles(1).XLim = [0.1 0.3];
    
end
