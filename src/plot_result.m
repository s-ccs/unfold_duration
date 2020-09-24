function plot_result(fn_small)

for k = 1:height(fn_small)
    u = fn_small{k,'ufresult'};
    if length(u.param) == 1
        u.param.name = fn_small{k,'formula'}{1};
        u.param.event = table2cell(fn_small(k,[1:4 6:7]));
    else
        if length(u.param) == 11
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
            u.param(j).name = fn_small{k,'formula'}{1};
            u.param(j).event = table2cell(fn_small(k,[1:4 6:7]));
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
uf_plotParam(uf,'plotSeparate','event')
%%
end
