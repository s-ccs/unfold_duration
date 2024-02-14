%%
tmp_fn_p3 = dir(fullfile('/store/projects/unfold_duration/local','p3','sub-1_*.mat')); % Folders: p3; p3_button; p3_Stim+Button
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

% GA
groupIx = findgroups(fn_p3.formula);

%% RT distributions
% collect all RTs
tablesplines= fn_p3(groupIx == 2,:);
grouplist ={'distractor','target'};
colors = [2 219 240; 2 75 120; 255 181 91; 186 88 0; 190 190 190]./255;


t = [];
for k = 1:height(tablesplines)
    tmp = load(fullfile('/store/projects/unfold_duration/local','p3',tablesplines.filename{k}));
    paramval = tmp.ufresult_a.unfold.splines{1}.paramValues;
    type = tmp.ufresult_a.unfold.X(:,2);    
    type(isnan(paramval(1:length(type)))) = [];
    paramval(isnan(paramval)) = [];
    
    tSingle = table(repmat({fn_p3.sub{k}},length(paramval),1),paramval',grouplist(type+1)','VariableNames',{'sub','rt','condition'});
    t = [t;tSingle];
end
%% Draw Reaction Time Density distributions
figure,
% g = gramm('x',t.rt/1000,'group',t.sub,'color',t.condition);
g = gramm('x',t.rt/1000,'color',t.condition);
%g.facet_grid([], t.sub)
g.stat_density()
g.stat_bin('nbins',40,'geom','overlaid_bar')
g.set_color_options('map', colors(1:2,:));
% g.set_color_options('map', [0.5 0.5 0.5])

g.set_text_options('base_size',14)

ax = g.draw();
xlabel(ax.facet_axes_handles(1),'reaction time [s]');
