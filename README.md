# Project description

Project investigating whether duration and overlap can be modelled simultaneously and the effect of duration on analysis of human time series data. Corresponding article (preprint: https://doi.org/10.1101/2024.12.05.626938)

# Folder structure
(what ended up in the manuscript)
- Figures: Figures used in the manuscript in vector format
- src: All code used in the project
  - Simulations: matlab code used for the main simulations. Dependencies can be found in /lib, src/helper, and src/functions
  - Fixation_durations_WildLab: Code used for he FRP data analysis
  - PlutoNB: (Julia) Pluto notebooks for data plotting and fMRI analysis
- typst-paper2: Typst project for manuscript
- lib: dependencies (toolboxes) for the matlab simulation code

Note that some folders that are present in the repository are not listed here because they have no relevance to the final submission but are kept for completeness.

# How to reproduce manuscript figures

To reproduce figures of the simulations you will first have to run the [run_simulations.m](https://github.com/s-ccs/unfold_duration/blob/master/src/Simulations/run_simulations.m) and the [analysis_sim.m](https://github.com/s-ccs/unfold_duration/blob/master/src/Simulations/analysis_sim.m) scripts to produce the data (note that this will run ~15,000 simulations and might take a while). For the real data please look into the manuscript of how to obtain the data needed for either fMRI or FRPs.

Below you can find a table indicating which script/ notebook to use to produce certain figures. All figures can also be found as vector data in /Figures

## Quick note on notebooks

Please be aware that the notebooks used in this project are [Pluto.jl notebooks](https://plutojl.org/) within the Julia language. You can follow the installation instructions on [https://plutojl.org/](https://plutojl.org/#install) in order to use these.

| Figure | Script/ Notebook to produce figure | Comment
|-|-|-|
|Figure 1 | [2024-nb_figure1.jl](https://github.com/s-ccs/unfold_duration/blob/master/src/PlutoNB/2024-nb_figure1.jl) | Pluto.jl notebook |
|Figure 2 | [2024-nb_figure2.jl](https://github.com/s-ccs/unfold_duration/blob/master/src/PlutoNB/2024-nb_figure2.jl) | Pluto.jl notebook |
|Figure 3 | [plot_paper.m](https://github.com/s-ccs/unfold_duration/blob/master/src/Simulations/plot_paper.m) | Figure was changed subsequently in adobe |
|Figure 4 | [analysis_sim.m](https://github.com/s-ccs/unfold_duration/blob/master/src/Simulations/analysis_sim.m) | Use the code after section %% Load data |
|Figure 5 | [SimResultsStatsPlots_Paper.jl](https://github.com/s-ccs/unfold_duration/blob/master/src/PlutoNB/SimResultsStatsPlots_Paper.jl) | Pluto.jl notebook |
|Figure 6 | [SimResultsStatsPlots_Paper.jl](https://github.com/s-ccs/unfold_duration/blob/master/src/PlutoNB/SimResultsStatsPlots_Paper.jl) | Pluto.jl notebook |
|Figure 7 | [20240613_SimResults_Plots_BlockVsNoblock.jl](https://github.com/s-ccs/unfold_duration/blob/master/src/PlutoNB/20240613_SimResults_Plots_BlockVsNoblock.jl) | Pluto.jl notebook |
|Figure 8 | [nb_2024-02-15_wildlab-frp-duration-overlap.jl](https://github.com/s-ccs/unfold_duration/blob/master/nb_2024-02-15_wildlab-frp-duration-overlap.jl) | Pluto.jl notebook |
|Figure 9 | [2025-05-30_fmriStroop-FIR.jl](https://github.com/s-ccs/unfold_duration/blob/master/src/PlutoNB/2025-05-30_fmriStroop-FIR.jl) | Pluto.jl notebook |
