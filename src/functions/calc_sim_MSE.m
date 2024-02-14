function fn = calc_sim_MSE(fn, folder, csv_flag)
% Calculates the MSE for simulation results during the Unfold duration
% project.
% fn = table
% folder = string containing simulation instance
% csv flag = Indicate whether function should look for a result csv file;
%           Can be 0 or 1; WARNING: If set to 0 and csv file exists it will
%           be overwritten!!!
%
% R.Skukies; 07/09/2021


% Check if results for simulation already exist as tabel
if isfile(['/store/projects/unfold_duration/local/simulationResults/' folder '/simulationResults_' folder '_MSE.csv']) && csv_flag
    disp('Loading data from CSV file. This might take a while...')
    fn = readtable(['/store/projects/unfold_duration/local/simulationResults/' folder '/simulationResults_' folder '_MSE.csv']);
    all_b = load(['/store/projects/unfold_duration/local/simulationResults/' folder '/simulationResults_beta_' folder '.mat']);
    all_bnodc = load(['/store/projects/unfold_duration/local/simulationResults/' folder '/simulationResults_beta_nodc_' folder '.mat']);
    fn.beta = all_b.all_b;
    fn.beta_nodc = all_bnodc.all_bnodc;
    disp('MSE - Data loaded from CSV file')
    return
    
else
    
    for r = 1:height(fn)
        
        fprintf("Deviance :%i/%i\n",r,height(fn))
        
        row = fn(r,:);
        % we have to find the corresponding theoretical result to calculate the
        % deviance function
        
        % check rows except formula
        ix = cellfun(@(x,ix)strcmp(x,fn{:,ix}),row{:,[1:4 6:8]},num2cell([1:4 6:8]),'UniformOutput',false);
        ix_theo = all(cat(2,ix{:}),2) & fn.formula == "theoretical";
        assert(sum(ix_theo) == 1)
        
        if (regexp(folder, regexptranslate('wildcard', '**realNoise'))) || any(strcmp({'sim', 'sim_regularize', 'sim_realNoise', 'sim_realNoise_regularize'}, folder))
            y_true = fn{ix_theo,'beta'}(:,:,2:end); % For normal one event simulation
            y_est = row.beta(:,:,2:end); % For normal one event simulation
            
            if strcmp(row.formula, 'theoretical')
                y_est_nodc = row.beta(:,:,2:end);
            else
                y_est_nodc = row.beta_nodc(:,:,2:end); % no DC condition
            end
        else
            y_true = fn{ix_theo,'beta'}(:,:,2:end-1);
            y_est = row.beta(:,:,2:end-1); % For two event simulation
        end
        y_true(isnan(y_true(:))) = 0;
        y_est(isnan(y_est(:))) = 0; % can happen in case of theoretical
        y_est_nodc(isnan(y_est_nodc(:))) = 0;
        dev = mean((y_true(:) - y_est(:)).^2., "all");%mse(y_true, y_est_nodc); %sum((y_true(:) - y_est(:)).^2);
        dev_nodc = mean((y_true(:) - y_est_nodc(:)).^2, "all");%mse(y_true, y_est_nodc); %sum((y_true(:) - y_est_nodc(:)).^2);
        fn{r,'MSE'} = dev;
        fn{r,'MSE_nodc'} = dev_nodc;
    end
    
    % Normalize MSE
    for r = 1:height(fn)
        fprintf("Normalize :%i/%i\n",r,height(fn))
        row = fn(r,:);
        ix = cellfun(@(x,ix)strcmp(x,fn{:,ix}),row{:,[1:4 6:8]},num2cell([1:4 6:8]),'UniformOutput',false);
        
        % normalize MSE by y~1
        ix_intercept = all(cat(2,ix{:}),2) & fn.formula == "y~1";
        assert(sum(ix_intercept) == 1)
        
        fn{r,'normMSE'} = fn{r,'MSE'}/fn{ix_intercept,'MSE'};
        fn{r,'normMSE_nodc'} = fn{r,'MSE_nodc'}/fn{ix_intercept,'MSE'};
    end
    writetable(fn(:,[1:10 13:16]),['/store/projects/unfold_duration/local/simulationResults/' folder '/20240214simulationResults_' folder '_MSE.csv'])
end