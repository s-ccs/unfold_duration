function ufresult_marginal = fit_unfold(EEG,formula, T_event, twoEvent, regularize)

% Check if regularize, else not
if ~exist('regularize')
    regularize = 0;
end

if ~twoEvent
    cfgDesign = [];
    cfgDesign.formula = {formula};
    cfgDesign.eventtypes = {'eventA'};
    EEG = uf_designmat(EEG,cfgDesign);
else
    cfgDesign = [];
    cfgDesign.formula = {formula, 'y~1'};
    cfgDesign.eventtypes = {'eventA', 'eventB'};
    EEG = uf_designmat(EEG,cfgDesign);
end

%     fun = 'splines';
cfgTimeexpand = struct();
cfgTimeexpand.timelimits = [-.5 2];

EEG = uf_timeexpandDesignmat(EEG,cfgTimeexpand);
% end

if ~regularize
    EEG = uf_glmfit(EEG);
    EEG = uf_epoch(EEG,cfgTimeexpand);
    EEG = uf_glmfit_nodc(EEG);
else
    EEG = uf_glmfit(EEG, 'method', 'glmnet', 'glmnetalpha', 0);
    EEG = uf_epoch(EEG,cfgTimeexpand);
    if formula == "y~1" 
        EEG = uf_glmfit_nodc(EEG);
    else
        EEG = uf_glmfit_nodc(EEG, 'method', 'glmnet', 'glmnetalpha', 0);
    end
end

    ufresult = uf_condense(EEG);
    % To not give a bias towards bin estimation predict more quantiles than
    % 10 
    ufresult_marginal = uf_addmarginal(uf_predictContinuous(ufresult, 'auto_n', 15));
end