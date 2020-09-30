Analysis of ERP event-durations 

Many event-related potential (ERP) EEG studies contain events with variable duration (reaction times, fixation durations, stimulus durations, movements). Due to a lack of analysis tools or plain unawareness, this duration is rarely modelled and typically a single ERP is calculated for all durations. This can lead to nonsensical, missleading or otherwise biased results.

I show here that this bias emerges also when overlap-correction is used, as the overlap-kernel is assumed to be equal for all events of one type.

I analyzed this problem on real and simulated datasets. In the simulations I systematically explore the effects of ERP-shape, duration-distributions, overlap and noise on five different ways to model duration. I conclude, that modelling event durations as a binned or linear predictor is not recommended. Non-linear effects can capture some of the effects and are a promising candidate for further study.

This work is especially important for complex experiments for instance in virtual-reality, using eye-movement, or even mobile EEG paradigms.