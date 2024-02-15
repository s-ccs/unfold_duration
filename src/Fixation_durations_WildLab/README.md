# Investigating the effects of fixation durations on fixation-related potentials (FRPs)

## Getting started
1. Activate the environment (`Fixation_durations_WildLab`) and run `instantiate` to install all the required packages from the `Manifest.toml`.
2. Run the `setup.jl` script with `include("scripts/setup.jl")` to specify the required paths and create the required folders.
3. Run the `pipeline.jl` with `include("scripts/pipeline.jl")` to run the analysis pipeline for all subjects. The resulting models will be saved in the subject folders e.g. for subject 18 in `data/sub-18`.