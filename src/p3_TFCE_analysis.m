%  Script to analyse P3 results using TFCE

% First we need to load the data and make it usable for ept_TFCE
% Data needs to be in format Sub X Chan X Times
%%
tmp_fn_p3 = dir(fullfile('/store/projects/unfold_duration/local','p3','*.mat'));
tmp_fn_p3 = {tmp_fn_p3.name};
fn_p3 = cellfun(@(x)strsplit(x,'_'),tmp_fn_p3,'UniformOutput',false);
fn_p3 = cell2table(cat(1,fn_p3{:}),'VariableNames',{'sub','formula'});

% Chan of interest, PZ
chan = 13; 

%fn_p3 = parse_column(fn_p3,'overlap');
%fn_p3 = parse_column(fn_p3,'noise');
fn_p3.filename = tmp_fn_p3';
fn_p3.folder = repmat({'p3'},1,height(fn_p3))';
%% Load data
all_b = nan(height(fn_p3),31,512,10);
all_bnodc = nan(height(fn_p3),31,512,10);
del_idx =[];
for r = [1:height(fn_p3)] %[1:75 79:height(fn_p3)] 
    fprintf("Loading :%i/%i\n",r,height(fn_p3))
    
    if fn_p3.sub{r} == "sub-37"
        del_idx = [del_idx r];
        continue
    end
    
    tmp = load(fullfile('/store/projects/unfold_duration/local',fn_p3.folder{r},fn_p3.filename{r}));
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

% This takes care of subject 37; Has only 30 channels and throws an error.
% Will be investigated...
fn_p3(del_idx,:) = [];
all_b(del_idx,:,:,:) = [];
all_bnodc(del_idx,:,:,:) = [];

% Transfer betas to table
fn_p3.beta = squeeze(all_b);
fn_p3.beta_nodc = squeeze(all_bnodc);

%% Get data into right format
% Format will be sub X chan X data
% To find non-linear and not modelled
groupIx = findgroups(fn_p3.formula);

dataNoRT = {};
dataRT = {};


% Reaction time NOT modelled
dataNoRT{1} = fn_p3.beta_nodc(fn_p3.formula=="formula-y~1+cat(trialtype).mat",chan,:,1); % Target; no DC
dataNoRT{2} = fn_p3.beta_nodc(fn_p3.formula=="formula-y~1+cat(trialtype).mat",chan,:,8); % Distractor; no DC
dataNoRT{3} = fn_p3.beta(fn_p3.formula=="formula-y~1+cat(trialtype).mat",chan,:,1); % Target; y DC
dataNoRT{4} = fn_p3.beta(fn_p3.formula=="formula-y~1+cat(trialtype).mat",chan,:,8); % Distractor; y DC

% Reaction time modelled
dataRT{1} = fn_p3.beta_nodc(fn_p3.formula=="formula-y~1+cat(trialtype)+spl(rt,4).mat",chan,:,1); % Target; no DC
dataRT{2} = fn_p3.beta_nodc(fn_p3.formula=="formula-y~1+cat(trialtype)+spl(rt,4).mat",chan,:,8); % Distractor; no DC
dataRT{3} = fn_p3.beta(fn_p3.formula=="formula-y~1+cat(trialtype)+spl(rt,4).mat",chan,:,1); % Target; y DC
dataRT{4} = fn_p3.beta(fn_p3.formula=="formula-y~1+cat(trialtype)+spl(rt,4).mat",chan,:,8); % Distractor; y DC


%% Take care of NaN's
for k = 1:4
    dataRT{k}(any(any(isnan(dataRT{k}),3),2),:,:)   = [];    
    dataNoRT{k}(any(any(isnan(dataNoRT{k}),3),2),:,:) = [];    
end

%% Baseline
%bsl = @(data,times) data - mean(data(:,:,times<0),3); Results in NaNs


for k = 1:4
    dataRT{k}   = bsxfun(@minus, dataRT{k}, mean(dataRT{k}(:,:, tmp.ufresult_a.times<0),3));    
    dataNoRT{k} = bsxfun(@minus, dataNoRT{k}, mean(dataNoRT{k}(:,:,tmp.ufresult_a.times<0),3));   
end

%% Also need to load chanlocs to calculate the neighbours
eLoc = tmp.ufresult_a.chanlocs;
chanNeighbours = ept_ChN2(eLoc);
times = tmp.ufresult_a.times;

%% TFCE
cfg = struct('nperm', 1500, 'neighbours', chanNeighbours(chan,:));

% Calculate differences (distractor minus target)
Data_noDC_noRT = squeeze(dataNoRT{2} - dataNoRT{1}); % No RT modelling + No Overlap correction
Data_yDC_noRT = squeeze(dataNoRT{4} - dataNoRT{3}); % Overlap corrected + No RT modeling
Data_noDC_yRT = squeeze(dataRT{2} - dataRT{1}); % No Overlap correction + RT modelled
Data_yDC_yRT = squeeze(dataRT{4} - dataRT{3}); % Overlap correction + RT modelled

% Delete the ones containing NaN (!!!!hotfix!!!!!)
% Data_noDC_noRT(any(isnan(Data_noDC_noRT), 2),:) = [];
% Data_yDC_noRT(any(isnan(Data_yDC_noRT), 2),:) = [];
% Data_noDC_yRT(any(isnan(Data_noDC_yRT), 2),:) = [];
% Data_yDC_yRT(any(isnan(Data_yDC_yRT), 2),:) = [];


% Results = ept_TFCE(dataNoRT{1}, dataNoRT{2}, eLoc(chan), 'rsample', 512, 'chn', chanNeighbours(chan,:), 'nperm', 5000, 'flag_save', 0);
disp('**************************************************')
disp('Classical approach')
disp('**************************************************')
[res_noDC_noRT, info] = be_ept_tfce_diff(cfg, squeeze(Data_noDC_noRT));
disp('**************************************************')
disp('Data deconvolved but no reaction time modeled')
disp('**************************************************')
[res_yDC_noRT, info] = be_ept_tfce_diff(cfg, squeeze(Data_yDC_noRT));
disp('**************************************************')
disp('No deconcolution but reaction time modelled')
disp('**************************************************')
[res_noDC_yRT, info] = be_ept_tfce_diff(cfg, squeeze(Data_noDC_yRT));
disp('**************************************************')
disp('Data deconvolved and reaction time modeled')
disp('**************************************************')
[res_yDC_yRT, info] = be_ept_tfce_diff(cfg, squeeze(Data_yDC_yRT));
disp('**************************************************')

%%
figure
for k = {"Data_noDC_noRT","Data_yDC_noRT","Data_noDC_yRT","Data_yDC_yRT";1,2,3,4}
    eval(strjoin(["d = ",k{1}, ";"]))
    subplot(2,2,k{2})
    plot(times, trimmean(squeeze(d),20), '-r', 'DisplayName','yDC-yoRT')
    hold on,plot(times, mean(squeeze(d)), '-g', 'DisplayName','yDC-yoRT')
    hold on,plot(times, median(squeeze(d)), '-b', 'DisplayName','yDC-yoRT')
    ylim([-3,10])
end

%% Plottin for sanity checks
figure;
hold all
% plot(times, mean(squeeze(dataNoRT{2})))
% plot(times, mean(squeeze(dataNoRT{1})))
legend
plot(times, mean(squeeze(Data_noDC_noRT)), '--y', 'DisplayName','NoDC-NoRT')
plot(times, mean(squeeze(Data_yDC_noRT)), '--g', 'DisplayName','yDC-NoRT')
plot(times, mean(squeeze(Data_noDC_yRT)), '-b', 'DisplayName','NoDC-yRT')
plot(times, mean(squeeze(Data_yDC_yRT)), '-r', 'DisplayName','yDC-yoRT')


