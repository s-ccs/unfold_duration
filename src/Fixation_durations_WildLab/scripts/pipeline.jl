# Activate the project environment 
using DrWatson
@quickactivate "Fixation_durations_WildLab"

# Import required packages
using Pipelines
using JobSchedulers
using ProgressBars

# Include CmdProgram definitions needed for the pipeline
include(srcdir("pipeline_programs.jl"))

# DATA ANALYSIS PIPELINE

# Start job scheduler
scheduler_start()
set_scheduler_max_cpu(2)

# List all foldernames in the sourcedata folder
foldernames = readdir(datadir("sourcedata"))

# Extract the subject ids from the foldernames (e.g. sub-08 -> 8)
subject_ids = map(name -> parse(Int64, split(name, "-")[2]), foldernames)

# Define empty dict for the inputs for the Julia scripts (will be filled in the loop below)
inputs_jl = Dict{String}{Any}()

# Subject loop
for id in ProgressBar(subject_ids)
    @info("Subject " * string(id))

    # Update subject id in the inputs dict
    inputs_jl["SUBJECT_ID"] = id
    inputs_jl["SUBJECT_PREFIX"] = "sub-$(lpad(id, 2, "0"))"

    # Preprocess the subject's event data frame
    job_events = Job(prepare_events_data, inputs_jl)

    # Fit an Unfold model to predict FRPs
    job_unfold = Job(fit_Unfold_models, inputs_jl; dependency = DONE => job_events)

    submit!(job_events)
    submit!(job_unfold)
end

# Stop job scheduler
#scheduler_stop()