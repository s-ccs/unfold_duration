### A Pluto.jl notebook ###
# v0.19.45

using Markdown
using InteractiveUtils

# ╔═╡ 8edea32f-14ed-4b0d-97c4-ec79ea3d4c52
begin
    import Pkg
    # careful: this is _not_ a reproducible environment
    # activate a temporary environment
	Pkg.activate(mktempdir())

	Pkg.add(name = "UnfoldSim" ,rev = "sequFormulaOnset")
	Pkg.add(name = "Glob")
	Pkg.add(name = "MAT")
	Pkg.add(name = "FileIO")
	Pkg.add(name = "UnfoldMakie")
	Pkg.add(name = "CairoMakie")
	
	using Unfold, UnfoldSim, UnfoldMakie
	using CairoMakie
	using DataFrames, DataFramesMeta
	using StableRNGs, Random
	using CSV, Glob, FileIO, MAT
	using Statistics
	#using Parameters
	#using Distributions
end

# ╔═╡ df5d9f18-3d53-46ac-98e5-5cdfcd4c4fa1
function add(x::Vector{Vector{Float64}}, y::Vector{Float64})
	result = []
	for (i, ytmp) in enumerate(y)
		tmp = x[i] .+ ytmp
		push!(result, tmp)
	end
	return result
end

# ╔═╡ 3f70839d-2ece-43ae-91d3-61e3f80f8d84
function get_rts()
    # Find files
    tmp_fn_p3 = glob("sub-1_*.mat", "/store/projects/unfold_duration/local/p3/")
    fn_p3 = map(x -> split(basename(x), "_"), tmp_fn_p3)
    fn_p3 = DataFrame(sub = [f[1] for f in fn_p3], formula = [f[2] for f in fn_p3])
    
    # Add filename and folder columns
    fn_p3.filename = tmp_fn_p3
    fn_p3.folder = repeat(["p3"], nrow(fn_p3))
    
    # Group by formula
    groupIx = groupby(fn_p3, :formula)
	
    # RT distributions
    # Collect all RTs
    tablesplines = groupIx[2]
    grouplist = ["distractor", "target"]
    
    t = DataFrame(sub = String[], rt = Float64[], condition = String[])

    for k in 1:nrow(tablesplines)
        tmp = matread(tablesplines.filename[k])
        paramval = tmp["ufresult_a"]["unfold"]["splines"][1]["paramValues"]
        type = tmp["ufresult_a"]["unfold"]["X"][:, 2]
        valid_idx = .!isnan.(paramval[1:length(type)])
        
        type = type[valid_idx]
        paramval = paramval[valid_idx]

        tSingle = DataFrame(sub = repeat([fn_p3.sub[k]], length(paramval)),
                            rt = paramval,
                           condition = grouplist[Int.(type) .+ 1]
							)
        t = vcat(t, tSingle)
    end
    
    return t
end


# ╔═╡ d9253ea1-9cb6-4fba-8167-01cced41c03c
begin
	# Imbalanced design
	struct ImbalanceSubjectDesign <: UnfoldSim.AbstractDesign
	    nTrials::Int
	    balance::Float64
		targetDist
		distractorDist
	end
end;

# ╔═╡ e1ab6610-07d5-4e37-b2d0-ff4c73cb293f
# Function to generate imbalanced events
function UnfoldSim.generate_events(design::ImbalanceSubjectDesign)
    nA = Int(round.(design.nTrials .* design.balance))
    nB = Int(round.(design.nTrials .* (1 - design.balance)))
    @assert nA + nB ≈ design.nTrials

	rng = MersenneTwister(1)
	levels = vcat(repeat(["levelA"], nA), repeat(["levelB"], nB))
	durations = vcat(rand(rng, design.targetDist, nA), rand(rng, design.distractorDist, nB))
	
    return DataFrame(Dict(:condition => levels, :duration => durations))
end;

# ╔═╡ 52df5c57-7da9-46a6-8897-d2aa082fd7b1
size(design::ImbalanceSubjectDesign) = (design.nTrials,);

# ╔═╡ 5e456b6d-98de-4db8-971c-cff56f08b589
rt = get_rts();

# ╔═╡ 43561fbf-041b-4caa-8bd5-81d2cebd4396
begin
	design = ImbalanceSubjectDesign(200, 0.3,  @rsubset(rt, :condition == "target").rt,  @rsubset(rt, :condition == "distractor").rt)
	generate_events(design)
end;

# ╔═╡ 35347f78-c24d-48e2-b1d8-65524bbb9355
begin
	stim_char = 'A'
	design_seq = SequenceDesign(design, "$stim_char"*"R{1,1}_", 0, StableRNG(1))
	#UnfoldSim.generate_events(design_seq)
end;

# ╔═╡ 99914fa8-6522-4511-9cda-4325a32666a4
begin
	design_full = RepeatDesign(design_seq, 1)
	generate_events(design_full)
end

# ╔═╡ d71d0e69-70d3-4b55-8d6e-189623c491f6
begin
	# Components
	p1 = LinearModelComponent(;
    basis = p100(),
    formula = @formula(0 ~ 1),
    β = [1],
	);

	n1 = LinearModelComponent(;
	    basis = n170(),
	    formula = @formula(0 ~ 1),
	    β = [1],
	);
	
	p3 = LinearModelComponent(;
	    basis = UnfoldSim.hanning(Int(0.5 * 100)), # sfreq = 100 for the other bases
	    formula = @formula(0 ~ 1 + condition + duration),
	    β = [1, 0, 0.005],
	);
	
	resp = LinearModelComponent(;
	    basis = UnfoldSim.hanning(Int(0.5 * 100)), # sfreq = 100 for the other bases
	    formula = @formula(0 ~ 1),
	    β = [1],
	    offset = -10,
	);
end

# ╔═╡ 851e433e-7c29-461b-89d9-a4d0776e8072
begin
	#maxi = maximum(generate_events(design_full).duration) / 100
	
	mybasisfun = design -> map(.*, UnfoldSim.hanning.(Int.(round.(generate_events(design).duration  * 0.1))), round.(generate_events(design).duration) * 0.0025)
	signal = LinearModelComponent(;
	    basis = (mybasisfun, 100),
	    formula = @formula(0 ~ 1 + condition),
	    β = [1, 0],
		offset = 7
	);
end

# ╔═╡ 1e23b402-9cc0-4e3d-8614-0384beec5c23
begin
	components_test = Dict(stim_char => [p1, n1, signal], 'R' => [resp])
end

# ╔═╡ 53538f0d-51af-4887-bdaa-c4983dc05621
begin
	newOns =  UnfoldSim.FormulaUniformOnset(width_formula=@formula(0~1);width_β=[10],offset_formula=@formula(0~1+duration),offset_β=[0,0.1])
	
	components = Dict(stim_char => [p1, n1, p3], 'R' => [resp])
	#components = [p1, n1, resp]
	data, evts = simulate(
	    StableRNG(1),
	    design_full,
	    components_test,
	    newOns,
	    NoNoise(),
	)
end;

# ╔═╡ 071486ff-6ae5-4c71-9015-c4edc5adde36
begin
# First do without overlap correction
data_r = reshape(data, (1,:))
# cut the data into epochs
data_epochs, times = Unfold.epoch(data = data, tbl = evts, τ = (-0.2, 0.8), sfreq = 100); # channel x timesteps x trials
end

# ╔═╡ 380b046c-5ba9-4479-8e6d-f2a75f42b826
begin
	f = @formula 0 ~ 1 + condition * event
	m_nOV = fit(UnfoldModel, [Any=>(f, times)], evts, data_epochs);
end

# ╔═╡ 228ccc04-b020-42eb-a899-9123fdee3c25
begin
	m = fit(
	    UnfoldModel,
	    Dict(
	        stim_char => (
	            @formula(0 ~ 1 + condition + spl(duration, 10)),
	            firbasis(τ = [-0.2, 0.8], sfreq = 100, name = ""),
	        ),
			'R' => (
	            @formula(0 ~ 1 + condition),
	            firbasis(τ = [-0.3, 0.5], sfreq = 100, name = ""),
	        ),
	    ),
	    evts,
	    data,
	);
	
	m_nEff = fit(
	    UnfoldModel,
	    Dict(
	        stim_char => (
	            @formula(0 ~ 1 + condition),
	            firbasis(τ = [-0.2, 0.8], sfreq = 100, name = ""),
	        ),
			'R' => (
	            @formula(0 ~ 1 + condition),
	            firbasis(τ = [-0.3, 0.5], sfreq = 100, name = ""),
	        ),
	    ),
	    evts,
	    data,
	);
end

# ╔═╡ ff421fbb-cfd8-4204-9543-85f87d92c769
begin
	# Get non-overlapping data
	
	pred_data_stim = predict(
    m,
    Unfold.formulas(m),
    Unfold.events(m);
    overlap = true,
	keep_basis = [Unfold.basisname(Unfold.formulas(m))[2]]
)

	pred_data_resp = predict(
    m,
    Unfold.formulas(m),
    Unfold.events(m);
    overlap = true,
	keep_basis = [Unfold.basisname(Unfold.formulas(m))[1]]
)

end

# ╔═╡ cd386f51-4034-4e5b-b6f3-5c20b0af2261
begin
	data
	fig = Figure(; size = (1122, 734));
	stim_colors = [:teal, :orange]
	resp_color = :purple
end;

# ╔═╡ a8de876d-de87-47be-9516-216f65433059
begin
	pos = [1, 4:6]
	ax1 = Axis(fig[pos...], width=Relative(1), height=Relative(0.5), halign=0.0, valign=1)
	ax2 = Axis(fig[pos...], width=Relative(1), height=Relative(0.5), halign=0.0, valign=0.0)
	l = (18100, 19250)
	#start = l[1]
	#ending = l[2]
	
	# Plot continuous data
	lines!(ax1, data, color = :black)

	# Plot non-overlapping data
	lines!(ax2, pred_data_stim[1,:], color = (resp_color, 0.5))
	lines!(ax2, pred_data_resp[1,:], color = (stim_colors[1], 0.5))

	
	# Set limits and hide stuff
	axes = [ax1, ax2]
	for a in axes; xlims!(a, l...); hidedecorations!(a); hidespines!(a); end

	# Stimulus marker
	
	for (i,c) in enumerate(unique(evts.condition))
		vlines!(Axis(fig[pos...]),@rsubset(evts, :condition .== c, :event .== stim_char).latency, color = (stim_colors[i], 0.5))
		xlims!(l...)
		hidedecorations!(current_axis())
		hidespines!(current_axis())
	end

	# Response marker
	vlines!(Axis(fig[pos...]),@rsubset(evts,:event .== 'R').latency, color = (resp_color, 0.5))
	xlims!(l...)
	hidedecorations!(current_axis())
	hidespines!(current_axis())
	
	current_figure()
	
end

# ╔═╡ 4eba3429-7711-4785-ba78-97f46ec776e0
begin
	# Middle row left
	ax = Axis(fig[2, 1:3],
	xgridvisible = false, 
		ygridvisible = false,
		#yticklabelsvisible = false,
		ylabel = "PDF",
		xlabel = "Reaction time [ms]"
	)
	
	plt = UnfoldMakie.AlgebraOfGraphics.data(evts) * UnfoldMakie.AlgebraOfGraphics.mapping(:duration, color=:condition) * UnfoldMakie.AlgebraOfGraphics.density()
	fg = UnfoldMakie.AlgebraOfGraphics.draw!(ax, plt)

	mean_dis = round(mean(@rsubset(evts, :condition == "levelB").duration))
	mean_tar = round(mean(@rsubset(evts, :condition == "levelA").duration))
	vlines!(ax, [mean_dis, mean_tar], ymin = 0.05, color = [stim_colors[2], stim_colors[1]])

	spines = (:r,:t)
	hidespines!(ax, spines...)
	
	fig
end

# ╔═╡ ecb59448-16ea-4314-8262-b02fd55c0b08
unique(evts.condition)

# ╔═╡ d6476ce7-5da5-4f4e-9d9a-67dd6070f81b
# ╠═╡ disabled = true
#=╠═╡
UnfoldMakie.AlgebraOfGraphics.data(eff) * UnfoldMakie.AlgebraOfGraphics.visual(Lines) * UnfoldMakie.AlgebraOfGraphics.mapping(:yhat, col = :eventname => UnfoldMakie.AlgebraOfGraphics.sorter(sorting), color = :duration, group = :duration => nonnumeric) |> UnfoldMakie.AlgebraOfGraphics.draw()
  ╠═╡ =#

# ╔═╡ 120d383a-1889-4974-bf82-7dd69972efa5
begin
	# Lower row left
	lims = (-0.25, 0.8, -0.75, 1.55)
	ticks = [-0.2, 0.0, 0.25, 0.5]
	
	nOV_eff = effects(Dict(:condition => ["levelA", "levelB"], :event => [stim_char, 'R']), m_nOV)
	plot_erp!(fig[3, 1:2],
		nOV_eff; mapping = (; color = :condition, col = :event),
		axis = (; xlabel = "", titlevisible = false, limits = lims, xticks = ticks),
		layout = (; show_legend = false),
		visual = (; colormap = stim_colors)
	)
end

# ╔═╡ 98a4d94e-113a-46c1-9941-57f3f99ae621
begin
	# Middle row right
	eff = effects(Dict(:duration => 290:50:600), m)
	plot_erp!(fig[2, 4:6],
	    eff;
	    mapping = (; col = :eventname, color = :duration, group = :duration => nonnumeric),
		axis = (; titlevisible = false, xticks = ticks),
		colorbar = (; tellwidth = true, label = "Reaction time [ms]"),
		layout = (; use_legend = false),
	    categorical_color = false,
	    categorical_group = false,
	)
end

# ╔═╡ a10c6346-2473-4beb-aeb8-19cf60056a74
plot_erp(eff;
	    mapping = (; col = :eventname, color = (:duration, :eventname), group = :duration => nonnumeric), categorical_color = false,
	    categorical_group = false,
	axis = (; xticks = ticks),
	visual = (; colormap = :RdBu)
	)

# ╔═╡ 6a5a1d09-6769-4fa9-a852-1fbc6af6dc47
begin
	# Lower row middle
	cond_eff = effects(Dict(:condition => ["levelA", "levelB"]), m_nEff)
	plot_erp!(fig[3, 3:4],
		cond_eff; stderror = false,
		axis = (; titlevisible = false, ylabelvisible = false, yticklabelsvisible = false, limits = lims, xticks = ticks),
		mapping = (; color = :condition, col = :eventname),
		layout = (; show_ylabel = false, show_yticks = false, show_legend = false),
		visual = (; colormap = stim_colors)
	)
end

# ╔═╡ a9cf1920-bf63-4fc8-bafc-902eba3dba8d
begin
	# Lower row right
	eff_same = effects(Dict(:condition => ["levelA", "levelB"], :duration => 400), m)
	plot_erp!(fig[3, 5:6],
	    eff_same;
	    mapping = (; col = :eventname, color = :condition),
		axis = (; titlevisible = false, 
					xlabel = "", 
					ylabelvisible = false, 
					yticklabelsvisible = false,  limits = lims, xticks = ticks),
		layout = (; show_legend = false),
		visual = (; colormap = stim_colors)
	)
end

# ╔═╡ 9d93c5d2-7ac8-41b5-8b4e-734a8a17ff0c
begin
	
	with_theme(colormap=[:red,:green]) do
	plot_erp(cond_eff;
	    mapping = (; col = :eventname, color = :condition),
		axis = (; titlevisible = false, 
					xlabel = "", 
					ylabelvisible = false, 
					yticklabelsvisible = false,  limits = lims, xticks = ticks),
		layout = (; show_legend = false)
	)
	end
	
end

# ╔═╡ 314adba7-6a6d-460c-b6bc-68e14221fe74
begin
	fig
end

# ╔═╡ b89f9378-45c0-4774-b735-52d715badf0b
#CairoMakie.save("20241002Figure2.pdf", fig)

# ╔═╡ Cell order:
# ╠═8edea32f-14ed-4b0d-97c4-ec79ea3d4c52
# ╠═df5d9f18-3d53-46ac-98e5-5cdfcd4c4fa1
# ╠═3f70839d-2ece-43ae-91d3-61e3f80f8d84
# ╠═d9253ea1-9cb6-4fba-8167-01cced41c03c
# ╠═e1ab6610-07d5-4e37-b2d0-ff4c73cb293f
# ╠═52df5c57-7da9-46a6-8897-d2aa082fd7b1
# ╠═5e456b6d-98de-4db8-971c-cff56f08b589
# ╠═43561fbf-041b-4caa-8bd5-81d2cebd4396
# ╠═35347f78-c24d-48e2-b1d8-65524bbb9355
# ╠═99914fa8-6522-4511-9cda-4325a32666a4
# ╠═d71d0e69-70d3-4b55-8d6e-189623c491f6
# ╠═851e433e-7c29-461b-89d9-a4d0776e8072
# ╠═1e23b402-9cc0-4e3d-8614-0384beec5c23
# ╠═53538f0d-51af-4887-bdaa-c4983dc05621
# ╠═071486ff-6ae5-4c71-9015-c4edc5adde36
# ╠═380b046c-5ba9-4479-8e6d-f2a75f42b826
# ╠═228ccc04-b020-42eb-a899-9123fdee3c25
# ╠═ff421fbb-cfd8-4204-9543-85f87d92c769
# ╠═cd386f51-4034-4e5b-b6f3-5c20b0af2261
# ╠═a8de876d-de87-47be-9516-216f65433059
# ╠═4eba3429-7711-4785-ba78-97f46ec776e0
# ╠═ecb59448-16ea-4314-8262-b02fd55c0b08
# ╠═98a4d94e-113a-46c1-9941-57f3f99ae621
# ╠═a10c6346-2473-4beb-aeb8-19cf60056a74
# ╠═d6476ce7-5da5-4f4e-9d9a-67dd6070f81b
# ╠═120d383a-1889-4974-bf82-7dd69972efa5
# ╠═6a5a1d09-6769-4fa9-a852-1fbc6af6dc47
# ╠═a9cf1920-bf63-4fc8-bafc-902eba3dba8d
# ╠═9d93c5d2-7ac8-41b5-8b4e-734a8a17ff0c
# ╠═314adba7-6a6d-460c-b6bc-68e14221fe74
# ╠═b89f9378-45c0-4774-b735-52d715badf0b
