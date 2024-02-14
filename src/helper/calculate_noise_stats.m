% Parameters & loading
emptyEEG.srate = 100; %Hz

if ~exist('Noise')
    Noise = resting_state_noise(emptyEEG.srate); 
    genNoise = 1;
end

% Plot stats
f = figure();
hold on

for i = 1:size(Noise,2)
    
    t_mean = zeros(size(Noise{i},1),1); 
    t_std = zeros(size(Noise{i},1),1);
    t_var = zeros(size(Noise{i},1),1);
    t_max = zeros(size(Noise{i},1),1);
    t_min = zeros(size(Noise{i},1),1);
    
    for j = 1:size(Noise{i},1)
       
        t_mean(j) = mean(Noise{i}(j,:));
        t_std(j) = std(Noise{i}(j,:));
        t_var(j) = var(Noise{i}(j,:));
        t_max(j) = max(Noise{i}(j,:));
        t_min(j) = min(Noise{i}(j,:));
        
    end
    
    subplot(2, 2, 1)
    hold on
    
    scatter(i,t_mean)
    title('Mean')
    xlim([0 12])
    
    
    subplot(2, 2, 2)
    scatter(i,t_std)
    xlim([0 12])
    title('Std')
    hold on
    
    subplot(2, 2, 3)
    scatter(i,t_var)
    xlim([0 12])
    title('Variance')
    hold on
    
    subplot(2, 2, 4)
    scatter(i,t_min, "red")
    scatter(i,t_max, "blue")
    xlim([0 12])
    title('Min/Max')
    hold on
    
%     tab = table(t_mean, t_std, t_var, t_max, t_min);
%     disp(tab)
    
    %waitforbuttonpress()
    
end