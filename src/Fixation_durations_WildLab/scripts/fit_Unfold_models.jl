# Activate the project environment 
using DrWatson
@quickactivate "Fixation_durations_WildLab"

# Import required packages
using PyMNE
using Unfold
using CSV
using DataFrames
using StatsModels
using Chain
using Krylov, CUDA # To use GPU solver for Unfold
using BSplineKit # To use splines in the Unfold model(s)

include(srcdir("jl_utils.jl"))

#----
# Load the eeg and events data for the respective subject

subject_id = parse(Int64, ARGS[1]) # use first command line argument

# Reads the EEGLAB .set file of the respective subject
_, raw = load_eeg_data(subject_id)

# Extract the data for all channels
eeg_data = raw.get_data(units = "uV")
eeg_data = pyconvert(Array{Float64}, eeg_data)

# Extract the sampling frequency
sfreq = pyconvert(Float64, raw.info["sfreq"])

# Load events data frame
events = CSV.read(
    joinpath(get_subject_dir(subject_id), "sub-$(lpad(subject_id, 2, "0"))_events_mod.csv"),
    DataFrame,
)

#----
# Define basis functions for stimulus and fixation
bf_stimulus = firbasis(τ = (-0.5, 1.5), sfreq = sfreq, name = "stimulus")
bf_fixation = firbasis(τ = (-0.5, 1.0), sfreq = sfreq, name = "fixation")

bf_events = [bf_stimulus, bf_fixation]

#----
# Filter out all fixations with missing predictor values (e.g. fixations outside of the monitor)

# List of predictor variables
predictor_variables = [:is_face, :duration, :sac_amplitude, :fix_avgpos_x, :fix_avgpos_y]

# Make a list of events that have to be removed because of missing predictor values or because they are outside of the trial or the trial has too few fixations
events_to_remove = @chain events begin
    filter(
        [:type, :outside_trial, :few_fixations, predictor_variables...] => (
            (t, o, f, p...) ->
                t == "fixation" && (any(map(ismissing, p)) || o == true || f == true)
        ),
        _,
    )
    transform([:latency] => ByRow(Int ∘ round) => :latency_rounded)
    select([:event_nr, :latency, :latency_rounded])
end

# Only keep events without missing predictor values
cleaned_events = filter(:event_nr => event -> event ∉ events_to_remove.event_nr, events)

# Find the corresponding start and end for all events that have to be removed
data_to_delete = [events_to_remove.latency_rounded .+ bf_fixation.shiftOnset (
    events_to_remove.latency_rounded .+ bf_fixation.shiftOnset .+ length(bf_fixation.times)
)]

# Set the corresponding EEG data to missing
cleaned_data = Unfold.clean_data(eeg_data, data_to_delete)

#----
# Set pre- and suffix for saving the Unfold models
prefix = string("sub-$(lpad(subject_id, 2, "0"))", "-", "Unfoldmodel")
suffix = "jld2"

# Fit Unfold models for all combinations of overlap_correction and modeling_duration
for overlap_correction ∈ [true, false]
    for modeling_duration ∈ [true, false]

        # Fit Unfold model
        m = fit_Unfold_model(
            cleaned_data,
            cleaned_events,
            bf_events,
            sfreq;
            overlap_correction = overlap_correction,
            modeling_duration = modeling_duration,
        )
        #print(typeof(m))
        #print(m.design)

        # Use DrWatson.savename to create a systematic name for the Unfoldmodel
        name_container = Dict(
            "overlap_correction" => overlap_correction,
            "modeling_duration" => modeling_duration,
        )
        model_name = savename(prefix, name_container, suffix)

        # Save the Unfold model in a .jdl2 file
        save(joinpath(get_subject_dir(subject_id), model_name), m; compress = true)
        @info("The Unfold model has been saved to a jld2-file.")
    end
end