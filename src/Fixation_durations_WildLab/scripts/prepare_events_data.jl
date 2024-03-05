# Activate the project environment 
using DrWatson
print(projectdir())
@quickactivate "Fixation_durations_WildLab"

# Import required packages
using CSV
using DataFrames
using Chain
using Missings
using YAML
using DataFramesMeta

include(srcdir("jl_utils.jl"))

#----
subject_id = parse(Int64, ARGS[1]) # use first command line argument

#----
# Load the events and raw eeg data set files
events, raw = load_eeg_data(subject_id)

#----
# Extract the sampling frequency
sfreq = pyconvert(Float64, raw.info["sfreq"])

# Add latency (event onsets in samples) to the events DataFrame
events[!, :latency] .= events.onset .* sfreq

# Number the events in the data frame
events[!, :event_nr] = range(1, size(events)[1])

#----
# Create a column outside_trial to flag events that are not within a trial
flag_events_outside_trial!(events)

#----
# Create a column few_fixations to flag fixations in trials that contain too few fixations (less than the specified threshold)
flag_too_few_fixations!(events; threshold = 6)

#----
# Copy the info about picID, stim_set, stim_file, trialnum and subject_id from a "stimulus" event
# to all fixations, saccades and blinks within the respective trial
# (i.e. inbetween stimulus onset and the end of the trial (trigger "180"))
type_field_combs = rename!(
    DataFrame(
        Iterators.product(
            ["fixation", "saccade", "blink", "blinkFix"],
            [:picID, :stim_set, :stim_file, :trialnum, :id],
        ),
    ),
    ["evt_type", "field"],
)
map(eachrow(type_field_combs)) do r
    copy_trialinfo!(events, "stimulus", "180", r.evt_type, :type, r.field)
end

#----
# Extract the information about the screen resolution for detecting whether a fixation is on the screen or outside
exp_setup = YAML.load_file("scripts/exp_setup.yaml")
screen_res_px = exp_setup["screen_res_px"]

#----
events_mod = @chain events begin

    # replace NaN (type Float64) or "NaN" values with missing
    allowmissing!(_)
    transform(
        All() .=> col -> replace(col, NaN => missing, "NaN" => missing),
        renamecols = false,
    )

    # change the column type from Float to Int for pic and subject id and trialnum (while allowing missing values)
    transform(
        [:picID, :trialnum, :id] .=> x -> convert(Array{Union{Int,Missing},1}, x),
        renamecols = false,
    )

    # update the stim_file name with the filename of the combined image
    transform(
        :stim_file => ByRow(
            passmissing(
                file -> replace(
                    file,
                    r"/.*" => "/" * match(r"\d+", file, 1).match * ".png",
                ),
            ),
        ),
        renamecols = false,
    )

    # add is_face column which is true if the fixation is on a face
    transform(
        :fix_type =>
            ByRow(row -> ismissing(row) ? missing : split(row, "to")[2] == "HF") =>
                :is_face,
    )

    # set fixations that are outside of the screen to missing
    @eachrow _ begin
        if :type == "fixation" && (
            :fix_avgpos_x <= 0 ||
            :fix_avgpos_y <= 0 ||
            :fix_avgpos_x >= screen_res_px[1] ||
            :fix_avgpos_y >= screen_res_px[2]
        )
            :fix_avgpos_x = missing
            :fix_avgpos_y = missing
        end
    end

    # rename :id column and reorder columns
    rename(:id => :subject_id)
    select(:event_nr, :)
end

#----
CSV.write(
    joinpath(get_subject_dir(subject_id), "sub-$(lpad(subject_id, 2, "0"))_events_mod.csv"),
    events_mod,
)