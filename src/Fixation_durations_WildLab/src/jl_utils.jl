# Helper functions 

# Import required packages
using DrWatson
using CSV
using DataFrames
using PyMNE
using Unfold

## Functions to get required paths
"""
    get_subject_dir(subject_id::Integer)

Return the path to a subject's data directory.

The function additionally checks whether the directory exists and otherwise creates it.
"""
function get_subject_dir(subject_id::Integer)

    # Pad subject id to 2 digits using zeros
    # e.g. 3 gets 03
    subject_id = lpad(subject_id, 2, "0")
    subject_dir = datadir("sub-$(subject_id)/")

    # Check whether subject directory already exists, otherwise create it
    exists = isdir(subject_dir)

    if exists
        return subject_dir
    else
        print("Subject directory has been created.")
        return mkdir(subject_dir)
    end
end


function get_data_path(subject_id::Integer, which_path = "root")

    # Pad subject id to 2 digits using zeros
    # e.g. 3 gets 03
    subject_id = lpad(subject_id, 2, "0")

    # Define root path for the respective subject
    root_path = datadir("sourcedata", "sub-$(subject_id)/eeg/")

    # Return the requested path
    if which_path == "root"
        return root_path
    elseif which_path == "events"
        return joinpath(root_path, "sub-$(subject_id)_task-WLFO_events.tsv")
    elseif which_path == "eeg_set"
        return joinpath(root_path, "sub-$(subject_id)_task-WLFO_eeg.set")
    else
        throw(
            ArgumentError(
                "The specified path type does not exist. Use \"root\",\"events\" or \"eeg_set\".",
            ),
        )
    end
end

## Function(s) to load the data
function load_eeg_data(subject_id::Integer)

    # read the events tsv file and save it in a DataFrame
    events = CSV.read(get_data_path(subject_id, "events"), DataFrame, delim = "\t")

    # read the raw eeg data set
    raw = PyMNE.io.read_raw_eeglab(get_data_path(subject_id, "eeg_set"), preload = true)

    return events, raw
end

## Events preprocessing functions

# function to find the indices of all target events between the current start and stop event
function find_target_indices(
    current_source,
    target,
    type_col,
    source_latencies,
    stop_latencies,
)
    ix = intersect(
        findall(isequal(target), events[:, type_col]),
        findall(
            x ->
                source_latencies[current_source] <= x <= stop_latencies[current_source],
            events.latency,
        ),
    )
    return ix
end

# function to copy the info from one column of the start/source event to all events of a certain type inbetween the start and the stop event
function copy_trialinfo!(events, start_event, stop_event, target, type_col, field)

    # find the indices of the start events and the respective latencies
    source_idx = findall(isequal(start_event), events[:, type_col])
    source_latencies = events[source_idx, :latency]

    # find the indices of the stop events and the respective latencies
    stop_idx = findall(isequal(stop_event), events[:, type_col])
    stop_latencies = events[stop_idx, :latency]

    # go through all start/sorce events and copy the respective information to all events of the type specified in target
    for (i, source) in enumerate(source_idx)
        target_idx =
            find_target_indices(i, target, type_col, source_latencies, stop_latencies)
        events[target_idx, field] .= events[source, field]
    end
end

# function to create a new column which is true for events outside of trials and false otherwise
function flag_events_outside_trial!(events)
    # Extract start and end event numbers/indices of all trials
    trial_start = filter(:type => x -> x == "stimulus", events).event_nr
    trial_end = filter(:type => x -> x == "180", events).event_nr

    # Create empty array to store indices of events that are outside a trial
    outside_trial_indices = Array{Int64}(undef, 0)

    # Get indices of events before first trial and after the last trial
    append!(outside_trial_indices, findall(x -> x .< trial_start[1], events.event_nr))
    append!(outside_trial_indices, findall(x -> x .> trial_end[end], events.event_nr))

    # Add indices of events between trials
    for i = 1:length(trial_start)-1
        append!(
            outside_trial_indices,
            findall(x -> trial_end[i] .< x .< trial_start[i+1], events.event_nr),
        )
    end

    # Create new column in the events data frame
    events[!, :outside_trial] .= false

    # Set a flag for all events outside of trials
    events[outside_trial_indices, :outside_trial] .= true
end

function flag_too_few_fixations!(events; threshold = 6)
    trial_start = filter(:type => x -> x == "stimulus", events).event_nr
    trial_end = filter(:type => x -> x == "180", events).event_nr

    # Create new column in the events data frame to flag trials with too few fixations 
    events[!, :few_fixations] .= false

    # Log the number of trials with too few fixations
    trial_count = 0
    for i = 1:length(trial_start)
        fixations_trial = filter(
            [:type, :event_nr] =>
                (type, nr) ->
                    type == "fixation" && nr > trial_start[i] && nr < trial_end[i],
            events,
        )
        nr_fixations = size(fixations_trial)[1]

        if nr_fixations < threshold
            trial_count += 1
            events[fixations_trial.event_nr, :few_fixations] .= true
        end
    end

    @info("There are $(trial_count) trials that contain less than $(threshold) fixations.")
end

## Model fitting function(s)

function fit_Unfold_model(
    data,
    events,
    bf_events,
    sfreq;
    overlap_correction,
    modeling_duration,
)

    # Define model formulas for stimulus and fixations
    f_stimulus = @formula 0 ~ 1

    # If modeling_duration == true, include duration as a predictor in the model
    if modeling_duration
        f_fixation = @formula 0 ~
            1 +
            is_face +
            spl(duration, 4) +
            spl(sac_amplitude, 4) +
            spl(fix_avgpos_x, 4) +
            spl(fix_avgpos_y, 4)
    else
        f_fixation = @formula 0 ~
            1 +
            is_face +
            spl(sac_amplitude, 4) +
            spl(fix_avgpos_x, 4) +
            spl(fix_avgpos_y, 4)
    end

    if overlap_correction
        # Unpack basisfunctions
        bf_stimulus, bf_fixation = bf_events

        # Match the formulas and basis functions to their corresponding event type
        bfDict = Dict(
            "stimulus" => (f_stimulus, bf_stimulus),
            "fixation" => (f_fixation, bf_fixation),
        )

        # Fit continuous Unfold model
        @info(
            "Start fitting Unfold model with overlap_correction == $overlap_correction and modeling_duration == $modeling_duration."
        )
        m = fit(
            UnfoldModel,
            bfDict,
            events,
            data,
            eventcolumn = "type",
            solver = (x, y) -> Unfold.solver_krylov(x, y; GPU = true),
        )
    else
        # Epoch the data (note: in this case both events have the same time window)
        data_epochs, times =
            Unfold.epoch(data = data, tbl = events, τ = (-0.5, 1.0), sfreq = sfreq)

        # Fit mass univariate Unfold model
        @info(
            "Start fitting Unfold model with overlap_correction == $overlap_correction and modeling_duration == $modeling_duration."
        )
        m = fit(
            UnfoldModel,
            Dict("fixation" => (f_fixation, times), "stimulus" => (f_stimulus, times)),
            events,
            data_epochs,
            eventcolumn = "type",
        )
    end

    return m
end

## Function(s) to aggregate the modelling results over subjects

# Function to convert the values of a dictionary to Boolean values
# Adapted from: https://discourse.julialang.org/t/convert-value-type-of-dictionary/67419
convert_to_bool((k, v)) = k => parse(Bool, v)

function load_Unfold_models(subject_id::Integer)

    # Set pre- and suffix for loading the Unfold models
    prefix = string("sub-$(lpad(subject_id, 2, "0"))", "-", "Unfoldmodel")

    # Create empty data frame to store the models
    model_df = DataFrame(
        subject_id = Int[],
        overlap_correction = Bool[],
        modeling_duration = Bool[],
        unfold_model = UnfoldModel[],
    )

    # List the paths of all Unfold models that match the prefix
    model_paths = glob(prefix * "*.jld2", get_subject_dir(subject_id))

    # Load all models and store them in a data frame
    for model_path in model_paths
        m = load(model_path, UnfoldModel, generate_Xs = false)
        _, parameters, _ = parse_savename(model_path)
        df_row = DataFrame(
            merge(
                Dict("unfold_model" => m, "subject_id" => subject_id),
                Dict(Iterators.map(convert_to_bool, pairs(parameters))),
            ),
        )
        append!(model_df, df_row)
    end

    return model_df
end

function aggregated_effects(models, predictor_dict; aggregation_function = mean)

    # Compute the effects for all subjects separately
    effects_all_subjects = combine(
        groupby(models, :subject_id),
        :unfold_model => (m -> effects(predictor_dict, m[1])) => AsTable,
    )
    # Aggregate the effects (per event type, time point and channel) over subjects using the specified function
    aggregated_effs = @chain effects_all_subjects begin
        groupby([:basisname, :channel, collect(keys(predictor_dict))..., :time])
        combine(
            :yhat .=>
                [x -> aggregation_function(skipmissing(x))] .=>
                    Symbol("yhat_", aggregation_function),
        )
    end
    return aggregated_effs
end
