%% Collect data
tmp_fn_N4 = dir(fullfile('local','N400','*.mat'));
tmp_fn_N4 = {tmp_fn_N4.name};
fn_N4 = cellfun(@(x)strsplit(x,'_'),tmp_fn_N4,'UniformOutput',false);
fn_N4 = cell2table(cat(1,fn_N4{:}),'VariableNames',{'sub','formula'});


%fn_p3 = parse_column(fn_p3,'overlap');
%fn_p3 = parse_column(fn_p3,'noise');
fn_N4.filename = tmp_fn_N4';
fn_N4.folder = repmat({'N400'},1,height(fn_N4))';
%%
all_b = nan(height(fn_N4),31,1024,9);
all_bnodc = nan(height(fn_N4),31,1024,9);
for r = 1:height(fn_N4)
    fprintf("Loading :%i/%i\n",r,height(fn_N4))
    
    if strcmp(fn_N4.sub(r), 'sub-1') % Current hot-fix because for some reason Subject 1 has Matrix dim 31x2048x9
        continue
    end
    
    tmp = load(fullfile('local',fn_N4.folder{r},fn_N4.filename{r}));
    b = tmp.ufresult_a.beta(:,:,:);
    b_nodc = tmp.ufresult_a.beta_nodc(:,:,:);
    if strcmp(fn_N4{r,'formula'},'formula-y~1+cat(eventtype).mat')
        b(:,:,8:9) = b(:,:,2:3);
        b(:,:,2:7) = repmat(b(:,:,1),1,1,6);
        b_nodc(:,:,8:9) = b_nodc(:,:,2:3);
        b_nodc(:,:,2:7) = repmat(b_nodc(:,:,1),1,1,6);
    end
    
    
    all_b(r,:,:,:) = b;
    all_bnodc(r,:,:,:) =  b_nodc;

end
fn_N4.beta = squeeze(all_b);
fn_N4.beta_nodc = squeeze(all_bnodc);

%% plot intermediate step
plot_result(fn_N4(2,:),'channel',21)

%% generate GA
groupIx = findgroups(fn_N4.formula);
GA = splitapply(@(x)trimmean(x,0.2),fn_N4.beta,groupIx);
GA_nodc = splitapply(@(x)trimmean(x,0.2),fn_N4.beta_nodc,groupIx);
fn_p4_ga = table(unique(fn_N4.formula),GA,GA_nodc,'VariableNames',{'formula','beta','beta_nodc'});
fn_p4_ga.folder = repmat({'N400'},1,height(fn_p4_ga))';
fn_p4_ga.filename = fn_N4{1:3,'filename'};
%% plot GA
plot_result(fn_p4_ga(2,:),'channel',21)


%%
%uf_plotParam(ufresult_a,'channel',21)