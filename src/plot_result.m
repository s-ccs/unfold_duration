function plot_result(fn_small,varargin)

for k = 1:height(fn_small)
    u = load(fullfile("local",fn_small.folder{k},fn_small{k,'filename'}));
    fn = fieldnames(u);
    u = u.(fn{1});
    % matlab table is currentlz 1 x chan x time x pred, to remove the 1x
    % but not potential chan == 1, we use permute
    if fn_small.folder{k} == "p3"
        % some transformation have been made
        u.beta = permute(fn_small.beta(k,:,:,:),[2 3 4 1]);
        u.beta_nodc = permute(fn_small.beta_nodc(k,:,:,:),[2 3 4 1]);
    end
    [indicatorNames,indicatorCols] = setdiff(fn_small.Properties.VariableNames,"formula");
    rem = strcmp(indicatorNames,"beta")| strcmp(indicatorNames,"beta_nodc") | strcmp(indicatorNames,"MSE")| strcmp(indicatorNames,"filename");
    indicatorCols(rem) = [];
    
    if length(u.param) == 1
        % simulation
        u.param.name = fn_small{k,'formula'}{1};
        u.param.event = table2cell(fn_small(k,indicatorCols));
    else
        if length(u.param) == 11
            % simulation
            % spline case, remove the intercept
           del = ~strcmp({u.param.name},'dur');
        else
            % categorical binned case, remove nothing
            del = []; 
            
        end
    
        
        u.param(del) = [];        
        u.beta(:,:,del) = [];
        u.beta_nodc(:,:,del) = [];
        for j = 1:length(u.param)
               if fn_small.folder{k} == "p3"
                   % this should be refactored to be a plotting option
                   u.param(j).name = strjoin([u.param(j).name,fn_small{k,'formula'}(1)]);
                   
                   u.param(j).event = strjoin([u.param(j).event,{':'},table2cell(fn_small(k,indicatorCols))]);
               else
                   u.param(j).name = strjoin([fn_small{k,'formula'}(1)]);
                   
                   u.param(j).event = strjoin([table2cell(fn_small(k,indicatorCols))]);
               end
               
            if strcmp(fn_small{k,'formula'},'y~1+cat(durbin)')
                rtList =[0.1900    0.2223    0.2600    0.3000    0.3500    0.3900    0.4500    0.5200    0.5800    0.6914];

               u.param(j).value =  rtList(j);
            end

        end
    end
    if k == 1
        uf = u;
        uf.unfold = []; % just to be sure
    else
    uf.param(end+1:end+length(u.param)) = u.param;
    uf.beta(:,:,end+1:end+length(u.param)) = u.beta;
    uf.beta_nodc(:,:,end+1:end+length(u.param)) = u.beta_nodc;
    end
end
uf_plotParam(uf,'plotSeparate','event',varargin{:})
%%
end
