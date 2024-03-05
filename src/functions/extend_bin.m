function [b, b_nodc] = extend_bin(fn, tmp, folder, b, b_nodc, r)
% To extend the binned duration (only 10 bins) we need the predict_at
% values from one theoretical simulation:

% First we need the parameters to find the right theoretical iteration
bin_shape = convertCharsToStrings(fn.shape{r});
bin_iter = convertCharsToStrings(fn.iter{r});
bin_overlap = convertCharsToStrings(fn.overlap{r});
bin_overlapdist = convertCharsToStrings(fn.overlapdist{r});
bin_durEffect = convertCharsToStrings(fn.durEffect{r});
bin_overlapmod = convertCharsToStrings(fn.overlapmod{r});
bin_noise = convertCharsToStrings(fn.noise{r});

% Find exact theoretical instance
ix  = fn.shape==bin_shape & fn.iter == bin_iter & fn.formula == "theoretical" & fn.overlap == bin_overlap...
    & fn.overlapdist == bin_overlapdist & fn.overlapmod == bin_overlapmod & fn.durEffect == bin_durEffect & fn.noise == bin_noise;

tmp_theo = load(fullfile('/store/projects/unfold_duration/local',folder,fn.filename{ix}));
tmp_theo = extractfield(tmp_theo.ufresult_marginal.param, "value");
tmp_theo(1) = []; % First one is NAN because of intercept

bin_param = extractfield(tmp.ufresult_marginal.param, "name");
bin_param = bin_param(2:end);

% Init new beta matrices
b_tmp = zeros(size(b));
b_nodc_tmp = zeros(size(b_nodc));
% Set first parameter because of intercept & delete intercept
b_tmp(:,:,1) = b(:,:,1);
b_nodc_tmp(:,:,1) = b_nodc(:,:,1);

for i = 1:length(bin_param)
    
    % Find Value of current bin
    tmp_value = strsplit(bin_param{i}, '_');
    tmp_value = str2num(tmp_value{2});
    
    % find indecies which are in bin
    if i == 1
        tmp_ix = find(tmp_theo <= tmp_value);
    else
        tmp_ix = find(tmp_theo <= tmp_value & tmp_theo > old_value);
    end
    
    % repeat the value of the bin to match length
    b_tmp(:,:,tmp_ix+1) = repmat(b(:,:,i+1), 1, 1, length(tmp_ix));
    b_nodc_tmp(:,:,tmp_ix+1) = repmat(b_nodc(:,:,i+1), 1, 1, length(tmp_ix));
    
    old_value = tmp_value;
    
end

% Add entries for values greater than the last bin
tmp_ix = find(tmp_theo > tmp_value);
b_tmp(:,:,tmp_ix+1) = repmat(b(:,:,end), 1, 1, length(tmp_ix));
b_nodc_tmp(:,:,tmp_ix+1) = repmat(b_nodc(:,:,end), 1, 1, length(tmp_ix));

b = b_tmp;
b_nodc = b_nodc_tmp;

return