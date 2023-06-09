function fn = load_sim_data(fn, folder, csv_flag, jump_shape)
% Loads data from the simulations during the unfold duration project.
%
% fn = table
% folder = string containing simulation instance
% jump_shape = shape which should be ignored when loading
% csv flag = Indicate whether function should look for a result csv file;
%           Can be 0 or 1; WARNING: If set to 0 and csv file exists it will
%           be overwritten!!!
%
% R.Skukies; 07/09/2021


% Check if results for simulation already exist as tabel
if isfile(['/store/projects/unfold_duration/local/simulationResults/' folder '/simulationResults_' folder '.csv']) && csv_flag
    disp('Loading data from CSV file. This might take a while...')
    
    fn = readtable(['/store/projects/unfold_duration/local/simulationResults/' folder '/simulationResults_' folder '.csv'], 'Delimiter', ',');
    all_b = load(['/store/projects/unfold_duration/local/simulationResults/' folder '/simulationResults_beta_' folder '.mat']);
    all_bnodc = load(['/store/projects/unfold_duration/local/simulationResults/' folder '/simulationResults_beta_nodc_' folder '.mat']);
    fn.beta = all_b.all_b;
    fn.beta_nodc = all_bnodc.all_bnodc;
    
    disp('Data loaded from CSV file')
    return

% Otherwise load results from .mat files
else
    if (regexp(folder, regexptranslate('wildcard', '**HanningShapes')))
        all_b = nan(height(fn),1,250,16); % size based on dataset used: sim/sim/_harm (1,250,11); sim2 (1,250,12)
        all_bnodc = nan(height(fn),1,250,16);
        num_flag = 2;
    elseif any(strcmp({'sim', 'sim_regularize'}, folder)) || (regexp(folder, regexptranslate('wildcard', '**realNoise')))
        all_b = nan(height(fn),1,250,11); % size based on dataset used: sim/sim/_harm (1,250,11); sim2 (1,250,12)
        all_bnodc = nan(height(fn),1,250,11);
        num_flag = 1;
    else
        all_b = nan(height(fn),1,250,12);
        all_bnodc = nan(height(fn),1,250,12);
        num_flag = 0;
    end
    
    N_files = height(fn);
    for r = 1:N_files
        
        %Check if current shape should be ignored
        if exist("jump_shape")
            if fn.shape{r} == jump_shape %~(fn.overlap{r}=="overlap-1" && fn.durEffect{r} == "durEffect-0" && fn.shape{r} =="posNegPos")
                continue
            end
        end
        
        fprintf("Loading :%i/%i\n",r,N_files)
        
        tmp = load(fullfile('/store/projects/unfold_duration/local',folder,fn.filename{r}));
        b = tmp.ufresult_marginal.beta;
        b_nodc = tmp.ufresult_marginal.beta_nodc;
        
        % Artificially lengthen y~1 results
        if strcmp(fn{r,'formula'},'y~1')
            %         continue
            if num_flag == 2
                b = repmat(b(:,:,1),1,1,16); % Change according to line 16
                b_nodc = repmat(b_nodc(:,:,1),1,1,16);
            elseif num_flag
                b = repmat(b(:,:,1),1,1,11); % Change according to line 16
                b_nodc = repmat(b_nodc(:,:,1),1,1,11);
            else
                b = repmat(b(:,:,1),1,1,12); % Change according to line 16
                b_nodc = repmat(b_nodc(:,:,1),1,1,12);
            end
        end
        
        if strcmp(fn{r,'formula'},'y~1+cat(durbin)')
            b(:,:,2:end+1) = b(:,:,1:end);
            b_nodc(:,:,2:end+1) = b_nodc(:,:,1:end);
            
            % When incoherent number of number of parameters preset extent
            % based on values from tmp_theo
            if num_flag == 2
                [b, b_nodc] = extend_bin(fn, tmp, folder, b, b_nodc, r);
            end
            
        end
        
        all_b(r,:,:,:) = b;
        all_bnodc(r,:,:,:) =  b_nodc;
        
        clear tmp b b_nodc
    end
    
    fn.folder =repmat({folder},1,height(fn))';
    all_b = squeeze(all_b);
    fn.beta = all_b;
    all_bnodc = squeeze(all_bnodc);
    fn.beta_nodc = all_bnodc;
    
    % Save to csv file
    if ~exist(['/store/projects/unfold_duration/local/simulationResults/' folder], 'dir')
        mkdir(['/store/projects/unfold_duration/local/simulationResults/' folder])
    end
    
    writetable(fn(:,[1:10]),['/store/projects/unfold_duration/local/simulationResults/' folder '/simulationResults_' folder '.csv']);
    save(['/store/projects/unfold_duration/local/simulationResults/' folder '/simulationResults_beta_' folder '.mat'], 'all_b');
    save(['/store/projects/unfold_duration/local/simulationResults/' folder '/simulationResults_beta_nodc_' folder '.mat'], 'all_bnodc');
    
    return
end