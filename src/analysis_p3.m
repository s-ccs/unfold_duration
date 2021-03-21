%% Collect data
tmp_fn_p3 = dir(fullfile('store/projects/unfold_duration/local','p3','*.mat'));
tmp_fn_p3 = {tmp_fn_p3.name};
fn_p3 = cellfun(@(x)strsplit(x,'_'),tmp_fn_p3,'UniformOutput',false);
fn_p3 = cell2table(cat(1,fn_p3{:}),'VariableNames',{'sub','formula'});


%fn_p3 = parse_column(fn_p3,'overlap');
%fn_p3 = parse_column(fn_p3,'noise');
fn_p3.filename = tmp_fn_p3';
fn_p3.folder = repmat({'p3'},1,height(fn_p3))';
%%
all_b = nan(height(fn_p3),31,512,10);
all_bnodc = nan(height(fn_p3),31,512,10);
for r = [1:75 79:height(fn_p3)] % Jump over sets with only 3 betas, only subject 37
    fprintf("Loading :%i/%i\n",r,height(fn_p3))
    
    tmp = load(fullfile('local',fn_p3.folder{r},fn_p3.filename{r}));
    b = tmp.ufresult_a.beta(:,:,:);
    b_nodc = tmp.ufresult_a.beta_nodc(:,:,:);
    if strcmp(fn_p3{r,'formula'},'formula-y~1+cat(trialtype).mat')
        b(:,:,8:10) = b(:,:,2:4);
        b(:,:,2:7) = repmat(b(:,:,1),1,1,6);
        b_nodc(:,:,8:10) = b_nodc(:,:,2:4);
        b_nodc(:,:,2:7) = repmat(b_nodc(:,:,1),1,1,6);
    end
    
    
    all_b(r,:,:,:) = b;
    all_bnodc(r,:,:,:) =  b_nodc;

    %fn_p3{r,'ufresult'} = tmp.ufresult_marginal;
end
fn_p3.beta = squeeze(all_b);
fn_p3.beta_nodc = squeeze(all_bnodc);

%% plot intermediate step
plot_result(fn_p3(1,:),'channel',21)

%% generate GA
groupIx = findgroups(fn_p3.formula);
GA = splitapply(@(x)trimmean(x,0.2),fn_p3.beta,groupIx);
GA_nodc = splitapply(@(x)trimmean(x,0.2),fn_p3.beta_nodc,groupIx);
fn_p3_ga = table(unique(fn_p3.formula),GA,GA_nodc,'VariableNames',{'formula','beta','beta_nodc'});
fn_p3_ga.folder = repmat({'p3'},1,height(fn_p3_ga))';
fn_p3_ga.filename = fn_p3{1:3,'filename'};
%% plot GA
plot_result(fn_p3_ga(2,:),'channel',21)


%%
%uf_plotParam(ufresult_a,'channel',21)