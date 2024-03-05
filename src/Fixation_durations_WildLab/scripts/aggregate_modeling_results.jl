# Activate the project environment 
using DrWatson
@quickactivate "Fixation_durations_WildLab"

# Import required packages
using Unfold
using BSplineKit
using Krylov
using Glob
using DataFrames
using DataFramesMeta
using Chain
using Statistics
using CSV

include(srcdir("jl_utils.jl"))

# List all foldernames in the sourcedata folder
foldernames = readdir(datadir("sourcedata"))

# Extract the subject ids from the foldernames (e.g. sub-08 -> 8)
subject_ids = map(name -> parse(Int64, split(name, "-")[2]), foldernames)
subject_ids_sub = [8, 9]

# Load the Unfold models (for all combinations of overlap_correction and modeling_duration) for all subjects and create a data frame
models = vcat(map(load_Unfold_models, subject_ids)...)
#----
# Set pre- and suffix for saving the aggregated effects
prefix = "aggregated-effects"
suffix = "csv"

# Check whether there exists a folder for the aggregated effects results otherwise create it
if !isdir(datadir("aggregated_effects"))
    mkdir(datadir("aggregated_effects"))
    @info("A folder for the aggregated effects has been created.")
end

for overlap_correction ∈ [true, false]
    for modeling_duration ∈ [true, false]

        # Take only those models with the respective overlap_correction and modeling_duration condition
        models_sub = filter(
            [:overlap_correction, :modeling_duration] =>
                (oc, md) -> oc == overlap_correction && md == modeling_duration,
            models,
        )

        if modeling_duration == true
            predictor_dict = Dict(:duration => 0.1:0.1:1)
        else
            # In this case we want effects to take the typical values for all the predictors
            # Currently this is only possible with a "dummy" Dict
            predictor_dict = Dict(:duration => "d")
        end

        print(predictor_dict)
        # Compute the aggregated effects for the respective condition
        # As default `aggregation_function` is the mean
        aggregated_effs = aggregated_effects(models_sub, predictor_dict)
        print(first(aggregated_effs, 5))

        # Use DrWatson.savename to create a systematic name for the aggregated effects
        name_container = Dict(
            "overlap_correction" => overlap_correction,
            "modeling_duration" => modeling_duration,
        )
        model_name = savename(prefix, name_container, suffix)

        CSV.write(joinpath(datadir(), "aggregated_effects", model_name), aggregated_effs)
        @info("The following file has been created: $model_name")
    end
end
