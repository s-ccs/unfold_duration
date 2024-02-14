%%
rng(1) % define seed

%% get real RTs from one subject
t_rt = get_rts();
groupIx = findgroups(t_rt.condition);

%% Generate response
EEG = simulate_data_paper('overlap',[0.4 0.65],'datalength',60*10,'srate',1000,'condition','buttonpress','noise',0,... 
    'rtA', t_rt(groupIx==1,:).rt, 'rtB', t_rt(groupIx==2,:).rt);
t = struct2table(EEG.event);
%% Deconvolution
cfgDesign = [];
cfgDesign.codingschema = 'reference';
cfgDesign.formula = {'y~1','y~1','y~1'};
cfgDesign.eventtypes = {'stimulusA','stimulusB','buttonpress'};
cfgTimeexpand = [];
cfgTimeexpand.timelimits = [-0.5 0.8];
cfgTimeexpand.method = 'full';
% cfgTimeexpand.method = 'splines';
% cfgTimeexpand.timeexpandparam = 40;

% we run it once with thenon-linear effect and once without
for k = 1:2
    if k == 2
        cfgDesign.eventtypes = {'stimulusA','stimulusB',{'stimulusA','stimulusB'},'buttonpress'};

        cfgDesign.formula = {'y~1','y~1','y~1+spl(splineA,5)','y~1'};
    end
    EEG = uf_designmat(EEG,cfgDesign);

    EEG = uf_timeexpandDesignmat(EEG,cfgTimeexpand);
        EEG= uf_glmfit(EEG);
    EEG_epoch = uf_epoch(EEG,cfgTimeexpand);
    EEG_epoch = uf_glmfit_nodc(EEG_epoch); %does not overwrite
    if k == 1
        ufresult = uf_condense(EEG_epoch);
    else
        ufresult2 = uf_condense(EEG_epoch);
    end
end
%% plot results
% styling functions
% data = ufresult.beta;
bslfun = @(x)squeeze(bsxfun(@minus,x,mean(x(:,ufresult.times<-0.297,:),2)));
legfun = @()legend('stimulus A','stimulusB','buttonpress');
yfun1   = @()set(gca,'YLim',[-2.5 15],'XLim',[-50 500],'Box','off','XTick',[0 200 400],'YTick',[-2 0 2 4 6 8 10 12]);
yfun2   = @()set(gca,'YLim',[-2.5 15],'XLim',[-350 200],'Box','off','YTick','','XTick',[-200,0,200],'YTick',[-2 0 2 4 6 8 10 12]);
colors = cbrewer('seq','PuBu',10);
colors = colors(end:-1:1,:);
colors(end-2:end,:) = [];
cb     = @()set(gca, 'ColorOrder', colors, 'NextPlot', 'replacechildren');



figure
subplot(2,6,5)
% plot the simulated responses + the N170 effect
cb()
predictorvalues = linspace(0.2,1.2,5);
splinefunction = @(x)(log(x-1) - log(0.1));
plot(-499:1000/EEG.srate:500,EEG.sim.signals{1}(1).effectsize*EEG.sim.sig.shape{1}' + EEG.sim.signals{1}(2).effectsize*(EEG.sim.sig.shape{2}'*splinefunction(predictorvalues)),'LineWidth',1.5)
hold on
plot(-499:1000/EEG.srate:500,EEG.sim.signals{1}(1).effectsize*EEG.sim.sig.shape{1}' + EEG.sim.signals{1}(3).effectsize * EEG.sim.sig.shape{3}' + EEG.sim.signals{1}(2).effectsize*(EEG.sim.sig.shape{2}'* splinefunction(predictorvalues(3))  ),'-','LineWidth',1.5)
legend([arrayfun(@(x)sprintf('%.2f',x),predictorvalues,'uniformoutput',0) {'condition B'}])
yfun1()
vline(0)
subplot(2,6,6)
plot(EEG.sim.sig.time*1000,EEG.sim.sig.button)
yfun2()
vline(0)

% set(gca,'YLim',[-2 10],'XLim',[-250 500],'Box','off');



% no-unfold ERP
subplot(2,6,7)
plot(EEG_epoch.times,bslfun(ufresult.beta_nodc(:,:,1:end-1)))
legfun();
yfun1();
vline(0)
subplot(2,6,8)
plot(EEG_epoch.times,bslfun(ufresult.beta_nodc(:,:,end)))
hold on
plot(EEG_epoch.times,bslfun(ufresult.beta(:,:,end)))
legfun();
yfun2();
vline(0)
% unfold ERP
subplot(2,6,9)
plot(EEG_epoch.times,bslfun(ufresult.beta(:,:,1:end-1)))
legfun();
yfun1();
vline(0)
subplot(2,6,10)
plot(EEG_epoch.times,bslfun(ufresult.beta(:,:,end)))
legfun();
yfun2();
vline(0)
% unfold AND non-linear effect
subplot(2,6,11)
sacamps = [EEG.sim.X{1}(:,2);EEG.sim.X{3}(:,2)];
ufresult2_spline2 = uf_predictContinuous(ufresult2,'predictAt',{{'splineA',(mean(sacamps))}});
plot(EEG_epoch.times,bslfun(ufresult2_spline2.beta(:,:,[1 2])+sum(ufresult2_spline2.beta(:,:,[3 4]),3)))
legfun();
yfun1();
vline(0)
subplot(2,6,12);
plot(EEG_epoch.times,bslfun(ufresult2.beta(:,:,end)))

legfun();
yfun2();
vline(0)
%% plot saccade amplitudes
% cannot plot the gramm objects into the subplots unfortunately
figure
g = gramm('x',t.splineA(~strcmp(t.type ,'buttonpress')),'color',t.type(~strcmp(t.type ,'buttonpress')));
g.stat_bin('nbins',40,'geom','overlaid_bar')
% g.stat_density()
g.set_names('x','RT')
g.geom_vline('xintercept',mean([t.splineA{strcmp(t.type,'stimulusA')}]),'style','r')
g.geom_vline('xintercept',mean([t.splineA{strcmp(t.type,'stimulusB')}]),'style','b')
g.draw()


% plot reaction times
tmp = [diff(t.latency)/EEG.srate*1000;nan(1)];
t.reactiontime = tmp;

%%
figure
g = gramm('x',t.reactiontime(~strcmp(t.type ,'buttonpress')),'color',t.type(~strcmp(t.type ,'buttonpress')))
g.stat_bin('nbins',40,'geom','overlaid_bar')
g.set_names('x','reaction time [ms]')
g.geom_vline('xintercept',nanmean([t.reactiontime(strcmp(t.type,'stimulusA'))]),'style','r')
g.geom_vline('xintercept',nanmean([t.reactiontime(strcmp(t.type,'stimulusB'))]),'style','b')
g.axe_property('Xlim',[0 1000])

g.draw()


%%
et = struct();
et.cond =   [0,0,    2,  3,   2, 3,   1, 3    2,3    2,3,     1];
et.rt = [   .5, .4, 0.7,  0.3, .7,  0.6,.7,    .5,.7,   .4,1    .7,1];
tmp = [t.splineA{strcmp(t.type,'stimulusA')}];
et.amp = tmp(1:length(et.rt));
et.when = cumsum(et.rt);
et.srate = EEG.srate;
figure,
subplot(3,1,1)
sig = zeros(round((et.when(end)+0.5)*et.srate),1);
% sig(et.when*srate) = 1;
for k = 2:length(et.cond)
    if et.cond(k) == 3
        sigERP= EEG.sim.sig.button;
    else
          sigERP= EEG.sim.sig.shape{1} + double(et.cond(k)==2) * EEG.sim.signals{1}(3).effectsize * EEG.sim.sig.shape{3} + EEG.sim.signals{1}(2).effectsize*(EEG.sim.sig.shape{2}*log(et.amp(k)));
    end
    timing = round([((et.when(k)-0.5)*EEG.srate):((et.when(k)+0.5)*EEG.srate)-1]);
    
    if et.cond(k) == 1
        plot(timing/EEG.srate,sigERP,'-b')
    elseif et.cond(k) == 2
        plot(timing/EEG.srate,sigERP,'-r')
    elseif et.cond(k) == 3
        plot(timing/EEG.srate,sigERP,'-y')
    end
    hold on
    sig(timing) = sig(timing)+sigERP';
end
box off
% xlim([0,2])
xlim([0 10])
subplot(3,1,2)

plot((1:length(sig))/EEG.srate,sig)
vline(et.when);
xlim([0 10])

