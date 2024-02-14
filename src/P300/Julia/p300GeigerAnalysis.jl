# Package loading
using DataFrames, DataFramesMeta, CSV
using PyMNE
#using PyCall
using Printf
using Unfold
using CairoMakie, AlgebraOfGraphics
using StatsBase


# Function to load Data
function loadSub(sub, task, MNE, useRAW)
    # Load events
    events = CSV.read(@sprintf("/store/data/non-bids/MSc_EventDuration/relevantEvents/%s_finalEvents.csv", sub), DataFrame, delim=",")

    # Change events latency to 250sfreq because of new 
    if ~MNE
        events.latency = (events.latency ./ 256) .* 250
    end

    # Load raw data
    #raw = PyMNE.io.read_raw_eeglab("/store/data/MSc_EventDuration/sub-"*sub*"/ses-001/eeg/sub-"*sub*"_ses-001_task-"*task*"_run-001_eeg.set")

    # Load preprocessed data
    if MNE
        raw = PyMNE.io.read_raw_fif("/store/data/MSc_EventDuration/derivatives/preprocessed_Oddball_MNE_filtered/sub-" * sub * "/eeg/sub-" * sub * "_ses-001_task-" * task * "_run-001_eeg_MNE_HPfilter.fif", verbose="ERROR")
    elseif useRAW
        raw = PyMNE.io.read_raw_eeglab("/store/data/MSc_EventDuration/sub-" * sub * "/ses-001/eeg/sub-" * sub * "_ses-001_task-" * task * "_run-001_eeg.set", verbose="ERROR")
    else
        raw = PyMNE.io.read_raw_eeglab("/store/data/MSc_EventDuration/derivatives/RS_replication/preprocessed/sub-" * sub * "/eeg/sub-" * sub * "_ses-001_task-" * task * "_run-001_eeg.set", verbose="ERROR")
    end

    # Get sampling frequency
    sfreq = raw.info["sfreq"]
    sfreq = pyconvert(Any, sfreq)

    #if sfreq != 256
    #raw = raw.resample(256)
    #sfreq = 256
    #end

    # Set correct channel types for EOG channels
    raw.set_channel_types(Dict("HEOGR" => "eog", "HEOGL" => "eog", "VEOGU" => "eog", "VEOGL" => "eog"))


    # Re-reference
    #ref_chan = ("P7","P8")
    #raw = raw.set_eeg_reference(ref_chan)

    # Add subject to DataFrame to easily subset when not looking at all subjects
    events[!, :subject] .= parse.(Int64, sub)

    return events, sfreq, raw
end

# Function for Unfold modeling
function runUF(subList, EEG_raw, eventsList, design_lm)
    lm = []
    resultsAll = DataFrame()

    for (ix, subject) in enumerate(subList)
        data = pyconvert(AbstractArray, EEG_raw[ix].get_data())
        data = data .* 1e6

        lmSub = fit(UnfoldModel, design_lm, eventsList[ix], data, eventcolumn="event_type")

        resOne = coeftable(lmSub)
        resOne.subject .= subject
        append!(resultsAll, resOne)
        append!(lm, [lmSub])
    end
    return resultsAll, lm
end

# Just for the function above
MNE = false;
useRAW = false;

# Loading parameters
subList = ["006" "007"]
#subList = ["005" "006" "007" "008" "009" "010" "011" "012" "013" "014" "015" "016" "017"]
#subList = ["005" "006" "007" "008" "009" "010" "011" "012" "013" "014" "015" "016" "017" "019" "020" "021" "022" "024" "025" "026" "028" "029" "030" "031" "032" "033" "034" "035" "036" "037" "038" "039" "040" "041"]
task = "Oddball"
chIx = ["Pz"]


# Load data	eventsList = Array{DataFrame}(undef,length(subList))
sfreq = []
EEG_raw = []
eventsList = Array{DataFrame}(undef, length(subList))


for (ix, sub) in enumerate(subList)
    events, sfreq, raw = loadSub(sub, task, MNE, useRAW)

    eventsList[ix] = events
    EEG_raw = [EEG_raw; raw]
end

# Plot EEG data
#lines(dat_mne[0,30000:60000])
#lines!(pyconvert(Any,raw_eeglab.get_data(picks="Cz")[0,30000:60000]),color="red")
#current_figure()

# Sanity check of data
evt1, sfreq1, raw_mne = loadSub("006", task, true, false)
evt1, sfreq1, raw_eeglab = loadSub("006", task, false, false)
raw_mne.plot_psd(picks="Pz")
raw_eeglab.plot_psd(picks="Pz")

# Change events list
for j in 1:size(eventsList, 1)
    for i in 1:size(eventsList[j].trial_type, 1)
        if eventsList[j].trial_type[i] == "bp_target"
            eventsList[j].trial_type[i] = "target"
        elseif eventsList[j].trial_type[i] == "bp_distractor"
            eventsList[j].trial_type[i] = "distractor"
        end
    end
end

# Design

design_lm_RT = Dict(
    "stimulus" => (
        @formula(0 ~ 0 + trial_type + spl(response_time, 5)),
        firbasis(τ=(-1, 1), sfreq=sfreq, name="stimulus")),
    "response" => (
        @formula(0 ~ 0 + trial_type),
        firbasis(τ=(-1, 1), sfreq=sfreq, name="response")),
);


design_lm = Dict(
    "stimulus" => (
        @formula(0 ~ 0 + trial_type),
        Unfold.firbasis(τ=(-1, 1), sfreq=sfreq, name="stimulus")),
    "response" => (
        @formula(0 ~ 0 + trial_type),
        Unfold.firbasis(τ=(-1, 1), sfreq=sfreq, name="response")),
);

# Calculate model
@elapsed resultsAll, lm = runUF(subList, EEG_raw, eventsList, design_lm)

@elapsed resultsAll_RT, lm_RT = runUF(subList, EEG_raw, eventsList, design_lm_RT)


# Calculate grand averages
GA = @chain resultsAll begin
    @subset((:channel .== 26))
    @by([:basisname, :coefname, :time], :estimate = mean(:estimate))
end;

# Baseline
for b = unique(GA.basisname)
    #@show b
    bsl = @subset(GA, :basisname .== b, :time .< 0)

    tmp = GA[GA.basisname.==b, :].estimate .- mean(bsl.estimate)
    GA[GA.basisname.==b, :].estimate = tmp
end

# Plotting
basis_select = "stimulus"
AlgebraOfGraphics.data(@subset(GA, :basisname .== basis_select)) * mapping(:time, :estimate, color=:coefname) * visual(Lines) |> plt -> draw(plt, axis=(; title="GrandAverage", limits=((-0.2, 0.8), nothing)), legend=(position=:right,))

# Single subjects
subPl = "006"
AlgebraOfGraphics.data(@subset(resultsAll, :channel .== 26, :basisname .== basis_select, :subject .== subPl)) * mapping(:time, :estimate, color=:coefname) * visual(Lines) |> plt -> draw(plt, axis=(; title="Single Subject " * subPl, limits=((-0.2, 0.8), nothing)), legend=(position=:right,))

# Look at effects

