%% Generate Signal

rng(1) % same seed
ufresult_all = {};
N_event = 500; % max number of events
emptyEEG = eeg_emptyset();

emptyEEG.srate = 100; %Hz
emptyEEG.pnts  = emptyEEG.srate*500; % total length in samples
T_event   = emptyEEG.srate*1.5; % total length of event-signal in samples

for shape = {'box','posNeg','posNegPos','hanning'}
    for overlap = [0 1]
        for overlapdistribution =['uniform','halfnormal']
            for noise = 0
                EEG = generate_eeg(emptyEEG,shape,overlap,overlapdistribution,noise)
                
            
                
                %% -------------------
                % Intermediate Plotting
                %     [dursort,ixsort] = sort([EEG.event.dur]);
                %     sigdursort = [EEG.event(ixsort).sigdur];
                %     figure,a1 = subplot(2,1,1);
                %     imagesc((1:size(sigAll,2))./EEG.srate,dursort,sigAll(ixsort,:))
                %     hold on
                %     plot(dursort,sigdursort,'o-')
                %
                %
                %     subplot(2,1,2),ksdensity((diff(event_lat))./EEG.srate)
                %     xlim(a1.XLim)
                %% -------------------
                % Fit Signal
                % and save results
                
                for k = 1:4
                    cfgDesign = struct();
                    switch k
                        case 1
                            cfgDesign.formula = 'y~1';
                        case 2
                            cfgDesign.formula = 'y~1+dur';
                        case 3
                            cfgDesign.formula = 'y~1+spl(dur,5)';
                        case 4
                            cfgDesign.formula = 'y~1+spl(dur,10)';
                    end
                    % cfgDesign.formula = 'y~1';
                    
                    if is_overlap == 1 || size(ufresult_all,2)<k
                        ufresult_all{k} = ufresult_marginal;
                    elseif is_overlap == 0 && k==1
                        
                        ufresult_all{k}.a_no_simulated_overlap= ufresult_marginal.beta;
                    else
                        continue
                    end
                    if k>1
                        durations = [ufresult_all{k}.param(2:end).value];
                        tmin = sum(ufresult_all{k}.times<=0);
                        sig = nan(size(ufresult_all{k}.beta));
                        for d = 1:length(durations)
                            tmp= generate_signal_kernel(durations(d)*EEG.srate*options.overlapModifier,options.shape,EEG.srate);
                            sig(1,tmin+1:min(tmin+length(tmp),end),d+1) = tmp(1:min(end,size(sig,2)-tmin));
                        end
                        
                        
                        ufresult_all{k}.abeta_original = sig;
                        
                        %%
                        sigAll = [];
                        tmin = 20;%sum(ufresult_all{4}.times<=0);
                        durlist = [6 11 2];
                        for d = durlist
                            %[0.4,0.8,0.2,0.4]
                            dur = ufresult_all{k}.param(d).value*EEG.srate;
                            
                            generated_sig = generate_signal_kernel(dur*options.overlapModifier,options.shape,EEG.srate);
                            
                            
                            sig = zeros(size(ufresult_all{k}.beta(:,:,1)));
                            sig(tmin+1:min(tmin+length(generated_sig),end)) = generated_sig(1:min(end,size(sig,2)-tmin));
                            sigAll(1,:,end+1) = sig;
                            tmin = tmin+dur;
                            
                        end
                        ufresult_all{k}.aexplain = nan(size(ufresult_all{k}.abeta_original));
                        ufresult_all{k}.aexplain(1,:,durlist) = sigAll(:,:,2:end);%first one is empty
                        
                        
                    end
                end
            end
            %% -----------
            % Plotting
            for k = [1 4]
                ufresult_all{k} = renameStructField(ufresult_all{k},'beta','d_overlap_correction');
                ufresult_all{k} = renameStructField(ufresult_all{k},'beta_nodc','c_no_overlap_correction');
                ufresult_all{k} = renameStructField(ufresult_all{k},'abeta_original','a_simulation_kernel');
                ufresult_all{k} = renameStructField(ufresult_all{k},'aexplain','b_example_plot');
                if k == 1
                    uf_plotParam(ufresult_all{k},'dataField','d_overlap_correction')
                else
                    g = uf_plotParam(ufresult_all{k},'plotParam','dur','dataField','d_overlap_correction');
                end
            end
            
            %%