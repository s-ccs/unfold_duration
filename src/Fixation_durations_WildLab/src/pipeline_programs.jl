# Import required packages
using DrWatson
using Pipelines

# DEFINITION OF COMMAND PROGRAMS FOR THE ANALYSIS PIPELINE in scripts/pipeline.jl

prepare_events_data = CmdProgram(
    name = "Prepare events data",
    id_file = joinpath(".id_files", ".prepare_events_data"),
    inputs = [
        "SUBJECT_ID",
        "SUBJECT_PREFIX" => String,
        "SOURCEDATA_PATH" => datadir("sourcedata"),
        "EEG_DATA" => joinpath(
            "<SOURCEDATA_PATH>",
            "<SUBJECT_PREFIX>",
            "eeg",
            "<SUBJECT_PREFIX>_task-WLFO_eeg.set",
        ),
        "EVENTS_DATA" => joinpath(
            "<SOURCEDATA_PATH>",
            "<SUBJECT_PREFIX>",
            "eeg",
            "<SUBJECT_PREFIX>_task-WLFO_events.tsv",
        ),
    ],
    prerequisites = quote
        # If the .id_files folder does not exist yet, create it
        mkpath(".id_files")
    end,
    validate_inputs = quote
        # Check whether sourcedata folder exists
        check_dependency_dir(SOURCEDATA_PATH)
        # Check whether subject data files exist
        check_dependency_file(EEG_DATA)
        check_dependency_file(EVENTS_DATA)
    end,
    cmd = `julia --project=Project.toml scripts/prepare_events_data.jl SUBJECT_ID`,
)

fit_Unfold_models = CmdProgram(
    name = "Fit Unfold model",
    id_file = joinpath(".id_files", ".fit_Unfold_models"),
    inputs = [
        "SUBJECT_ID",
        "SUBJECT_PREFIX" => String,
        "SOURCEDATA_PATH" => datadir("sourcedata"),
        "DATA_PATH" => datadir(),
        "EEG_DATA" => joinpath(
            "<SOURCEDATA_PATH>",
            "<SUBJECT_PREFIX>",
            "eeg",
            "<SUBJECT_PREFIX>_task-WLFO_eeg.set",
        ),
        "EVENTS_DATA" => joinpath(
            "<DATA_PATH>",
            "<SUBJECT_PREFIX>",
            "<SUBJECT_PREFIX>_events_mod.csv",
        ),
    ],
    prerequisites = quote
        # If the .id_files folder does not exist yet, create it
        mkpath(".id_files")
    end,
    validate_inputs = quote
        # Check whether sourcedata folder exists
        check_dependency_dir(SOURCEDATA_PATH)
        # Check whether subject data files exist
        check_dependency_file(EEG_DATA)
        check_dependency_file(EVENTS_DATA)
    end,
    cmd = `julia --project=Project.toml scripts/fit_Unfold_models.jl SUBJECT_ID`,
)
