Analysis of ERP event-durations 

Many EEG studies are analyzed using event-related potentials (ERP). But often, the experiments contains events of variable duration (e.g. reaction times, fixation durations, stimulus durations, movements). Due to a lack of analysis tools or plain unawareness, such durations are rarely modelled and typically a single ERP is calculated for all durations. This can lead to nonsensical, missleading or otherwise biased results, especially if event durations differ between conditions.

I investigated this problem on real and simulated datasets. In the simulations, I systematically explore the effects of the ERP's waveform, different duration distributions, and noise on multiple ways to model duration. Because varying event-durations co-ocur often with temporal overlap between events, I also investigate the influence of overlap and deconvolution based overlap-correction.

I conclude, that modelling event durations as a binned or linear predictor is not recommended. Non-linear effects can capture some of the patterns and are a promising candidate for further study.

This work is especially important for complex experiments for instance in virtual-reality or mobile EEG settings which naturally allow for eye-movements.