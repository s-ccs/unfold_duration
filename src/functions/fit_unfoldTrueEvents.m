function ufresult_marginal = fit_unfoldTrueEvents(EEG,formula)
cfgDesign = [];
cfgDesign.formula = {{formula}, {'y~1'}};
cfgDesign.eventtypes = {'stimulus', 'button'};
EEG = uf_designmat(EEG,cfgDesign);


%     fun = 'splines';
cfgTimeexpand = struct();
cfgTimeexpand.timelimits = [-.5 2];

EEG = uf_timeexpandDesignmat(EEG,cfgTimeexpand);
% end


EEG = uf_glmfit(EEG);
EEG = uf_epoch(EEG,cfgTimeexpand);
EEG = uf_glmfit_nodc(EEG);
ufresult = uf_condense(EEG);
ufresult_marginal = uf_addmarginal(uf_predictContinuous(ufresult));