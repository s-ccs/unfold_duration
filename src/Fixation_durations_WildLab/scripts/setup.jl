# Activate the project environment 
using DrWatson
@quickactivate "Fixation_durations_WildLab"

# Load required packages
using YAML

# Navigate to the project directory
cd(projectdir())

# Check whether the data directory already exists, otherwise create it
if !isdir("data")
    mkdir("data")
    @info "Data directory has been created."
end

# Check whether there exists a yaml file with the relevant paths,
# otherwise ask the user for the path and save it in a yaml file
if !isfile("scripts/paths.yaml")
    valid_sourcedata_path = false

    # Query user input until the user enters a valid path
    while valid_sourcedata_path == false

        println(
            "Please enter the path to the sourcedata folder (containing eeg and events data):",
        )
        global sourcedata_path = readline()
        if isdir(sourcedata_path)
            global valid_sourcedata_path = true
            open("scripts/paths.yaml", "w") do f
                YAML.write_file(
                    "scripts/paths.yaml",
                    Dict("sourcedata_path" => sourcedata_path),
                )
            end

        else
            println("This is not a valid path.")
            continue
        end
    end
    @info "The path has been saved to scripts/paths.yaml."

    # If the yaml file already exists load the sourcedata path from the yaml file
else
    paths = YAML.load_file("scripts/paths.yaml")
    global sourcedata_path = paths["sourcedata_path"]
end

# If there is no sourcedata folder yet, create a symbolic link to the sourcedata path from the yaml file
if !isdir("data/sourcedata")
    run(`ln -s $sourcedata_path data/sourcedata`)
    @info "Created a symbolic link to the location of the sourcedata (i.e. eeg and events data)."
end

@info "The setup is finished."