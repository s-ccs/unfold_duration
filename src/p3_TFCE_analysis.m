%  Script to analyse P3 results using TFCE

% First we need to load the data and make it usable for ept_TFCE
% Data needs to be in format Sub X Chan X Times
%%
tmp_fn_p3 = dir(fullfile('/store/projects/unfold_duration/local','p3','*.mat'));
tmp_fn_p3 = {tmp_fn_p3.name};
fn_p3 = cellfun(@(x)strsplit(x,'_'),tmp_fn_p3,'UniformOutput',false);
fn_p3 = cell2table(cat(1,fn_p3{:}),'VariableNames',{'sub','formula'});


%fn_p3 = parse_column(fn_p3,'overlap');
%fn_p3 = parse_column(fn_p3,'noise');
fn_p3.filename = tmp_fn_p3';
fn_p3.folder = repmat({'p3'},1,height(fn_p3))';
%% Load data
all_b = nan(height(fn_p3),31,512,10);
all_bnodc = nan(height(fn_p3),31,512,10);
for r = 1:height(fn_p3) %[1:75 79:height(fn_p3)] % Jump over sets with only 3 betas, only subject 37
    fprintf("Loading :%i/%i\n",r,height(fn_p3))
    
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
fn_p3.beta = squeeze(all_b);
fn_p3.beta_nodc = squeeze(all_bnodc);

%% Get data into right format
% Format will be sub X chan X data
% To find non-linear and not modelled
groupIx = findgroups(fn_p3.formula);

dataNoRT = {};
dataRT = {};
for modelRT = [3 2]
    tmp_ix = find(groupIx == modelRT);
    dataTarget = zeros(length(tmp_ix), 1, size(fn_p3{1,'beta'},3)); 
    dataDistractor = zeros(length(tmp_ix), 1, size(fn_p3{1,'beta'},3)); 
    dataTarget_beta = zeros(length(tmp_ix), 1, size(fn_p3{1,'beta'},3)); 
    dataDistractor_beta = zeros(length(tmp_ix), 1, size(fn_p3{1,'beta'},3)); 
    for subject = 1:length(tmp_ix)
    for beta = {'beta_nodc','beta'}
        d = permute(fn_p3{tmp_ix(subject),beta{1}},[2 3 4 1]); % Just to take care of singleton dimension
        
        % d_sub = squeeze(fn_p3.beta(groupIx == 3,21,:,1:2));
        switch beta{1}
            case 'beta_nodc'
                for k = 1:2
                    if k == 1
                        ix = 1;
                        dataTarget(subject,:,:) = squeeze(d(21,:,ix));
                    else
                        ix = 8;
                        dataDistractor(subject,:,:) = squeeze(d(21,:,ix));
                    end
                end
            case 'beta'
                for k = 1:2
                    if k == 1
                        ix = 1;
                        dataTarget_beta(subject,:,:) = squeeze(d(21,:,ix));
                    else
                        ix = 8;
                        dataDistractor_beta(subject,:,:) = squeeze(d(21,:,ix));
                    end
                end
        end
       
    end
    end
    if modelRT == 3
        % reaction Time not modelled
        dataTarget(any(any(isnan(dataTarget),3),2),:,:) = [];
        dataDistractor(any(any(isnan(dataDistractor),3),2),:,:) = [];
        dataNoRT{1} = dataTarget; % No overlap correction
        dataNoRT{2} = dataDistractor; % No overlap correction
        dataNoRT{3} = dataTarget_beta; % With overlap correction
        dataNoRT{4} = dataDistractor_beta; % With overlap correction
    else
        % Reaction time modelled
        dataRT{1} = dataTarget; 
        dataRT{2} = dataDistractor;
        dataRT{3} = dataTarget_beta;
        dataRT{4} = dataDistractor_beta;
    end
end

%% Baseline

dataRT{1} = bsxfun(@minus, dataRT{1}, mean(dataRT{1}(:,:, tmp.ufresult_a.times<0),3));
dataRT{2} = bsxfun(@minus, dataRT{2}, mean(dataRT{2}(:,:,tmp.ufresult_a.times<0),3));
dataRT{3} = bsxfun(@minus, dataRT{3}, mean(dataRT{3}(:,:, tmp.ufresult_a.times<0),3));
dataRT{4} = bsxfun(@minus, dataRT{4}, mean(dataRT{4}(:,:,tmp.ufresult_a.times<0),3));

dataNoRT{1} = bsxfun(@minus, dataNoRT{1}, mean(dataNoRT{1}(:,:,tmp.ufresult_a.times<0),3));
dataNoRT{2} = bsxfun(@minus, dataNoRT{2}, mean(dataNoRT{2}(:,:,tmp.ufresult_a.times<0),3));
dataNoRT{3} = bsxfun(@minus, dataNoRT{3}, mean(dataNoRT{3}(:,:,tmp.ufresult_a.times<0),3));
dataNoRT{4} = bsxfun(@minus, dataNoRT{4}, mean(dataNoRT{4}(:,:,tmp.ufresult_a.times<0),3));


%% Also need to load an EEG file to calculate the neighbours
eLoc = tmp.ufresult_a.chanlocs;
chanNeighbours = ept_ChN2(eLoc);

%%
cfg = struct('nperm', 1500, 'neighbours', chanNeighbours(21,:));
NoDC_NoRT = dataNoRT{1} - dataNoRT{2};

% Results = ept_TFCE(dataNoRT{1}, dataNoRT{2}, eLoc(21), 'rsample', 512, 'chn', chanNeighbours(21,:), 'nperm', 5000, 'flag_save', 0);
[res, info] = be_ept_tfce_diff(cfg, NoDC_NoRT);





