### A Pluto.jl notebook ###
# v0.20.9

using Markdown
using InteractiveUtils

# ╔═╡ 769aa72b-3a9d-41cb-bb0b-e6a2414aea01
begin
using Pkg
	Pkg.activate("/tmp/fmristroop2/")
	#Pkg.add(["NIfTI","Random","DataFrames","FileIO","CSV","WGLMakie","Unfold","UnfoldMakie","PythonCall","CondaPkg","StatsBase","UnfoldStats","HypothesisTests"])
end

# ╔═╡ a6fb95f6-1ed0-480f-afb5-1cbf6ff6bb3c
Pkg.add("DSP")

# ╔═╡ 387e6752-5de1-4d46-931f-b5a2af62c0f9
Pkg.add("CUDA")

# ╔═╡ 6e6a5571-28f3-4e58-9118-24d015e8c87a
using UnfoldBIDS

# ╔═╡ 8ac12029-c04f-457a-b85d-8e92a7771fdb
using DSP

# ╔═╡ 6f45836c-2030-11f0-2c2e-a3821d64a916
begin
	using NIfTI
	using Random
	using DataFrames
	using FileIO
	using CSV
	using WGLMakie
	using Unfold
	using UnfoldMakie
	using PythonCall
	#	using PyMNE

	using CondaPkg
	using StatsBase
	
#CondaPkg.add(["nilearn","scipy"])
	

	
	a = "firstcell"
end

# ╔═╡ dc7a3d31-a157-4ce6-bf89-04d1e29cf44e
using UnfoldStats

# ╔═╡ 83cb0942-f457-4924-af7c-dab196cad696
using HypothesisTests

# ╔═╡ 0ade7e1f-c3ab-46af-af23-fb4fbe939737
using NaNStatistics

# ╔═╡ c1c2ee66-bec6-4a6f-ae0f-df168c9ac22a
using CUDA

# ╔═╡ 76f5c899-26a2-4bf3-b390-1f76ccf594d4
md"""
# FIR Version!
"""

# ╔═╡ 8021cedb-64e8-4fe8-a609-8ee08eb0b503
begin
	a
	#using UnfoldBIDS
	
end

# ╔═╡ 127def47-3c07-4d1c-b8e7-9a3ebc86f31d
#CondaPkg.add("nilearn[plotting]")


# ╔═╡ 5a6bb19c-9e40-4ee1-996e-7e6595740c86
#CondaPkg.add("nilearn")

# ╔═╡ a2324a77-410b-4a94-9e32-374a303e973d


# ╔═╡ 5a2bcf77-cd88-484c-8024-889b85168263
pyimport("scipy.ndimage")

# ╔═╡ cf0019b9-60a2-4c48-b9d3-d0fbe686701d
nilearn = pyimport("nilearn")

# ╔═╡ d0b32cf3-9f5f-46e8-86df-3eee181bcd37
nl = pyimport("nilearn.image")

# ╔═╡ 6fa5d0cd-f88e-419f-9bd0-5e4ce0bb633a
rootpath = "/store/data/2025_mumford_stroop_fMRI/stroop_data_share"

# ╔═╡ 7560df0e-78f1-4b97-b21e-f335dfb53bc7
function to_df(all_paths)
files_df = DataFrame(subject=[], ses=[], task=[], run=[], file=[])  # Initialize an empty DataFrame to hold results

# Add subject information
for path in all_paths
    UnfoldBIDS.extract_subject_id!(files_df, basename(path))
	files_df[end,:file] = path
end
	return files_df
end

# ╔═╡ f955041d-7e38-4983-9057-69e4565700db
begin
# Find paths
all_tsv = collect(UnfoldBIDS.list_all_paths(rootpath, [".tsv"], ""))|>to_df
all_nifti = collect(UnfoldBIDS.list_all_paths(joinpath(rootpath,"derivatives"), ["nii.gz"], ""))|>to_df
end

# ╔═╡ 4fcccac2-b645-4bc6-8c26-3c0dc0b9e4ec
subject = "s130"

# ╔═╡ f426690e-854f-473f-9dc7-5aae9542c180
all_nifti

# ╔═╡ f0f7360a-b52b-4261-a1b3-4cb790eb40b3
path_ix_nifti = findfirst(all_nifti.subject .== subject)

# ╔═╡ 0dcefc1f-58c1-4e37-89ce-4400e8ff8aab
path_ix_tsv = findfirst(all_tsv.subject .== subject)

# ╔═╡ 0251d6b8-2740-4040-aa15-39151bf31a9c


# ╔═╡ bcc5a43d-cfbe-45d6-b841-294461739da4
TR = 0.68

# ╔═╡ 78325e72-8edd-4643-9664-ea2c2c19215e

	function do_read_tsv(ix)
		evts = CSV.read(all_tsv.file[ix],DataFrame,missingstring="n/a")

		#if !isa(evts.response_time[1],Float64)
		#	allowmissing!(evts,:response_time)
		#	evts.response_time[evts.response_time .== "n/a"] .= missing
		#evts.response_time = parse.(Float64,evts.response_time)
		#end
		#if !isa(evts.onset[1],Float64)
		#evts.onset = parse.(Float64,evts.onset)
		#end
		evts.latency = evts.onset ./ TR
	return evts
	end


# ╔═╡ 323de92a-8230-4b1c-b3ee-cc1ddd4060c5
evts = do_read_tsv(path_ix_tsv)

# ╔═╡ 98d1e30d-1718-4b8b-bb28-33a79ef84886
size(all_nifti)

# ╔═╡ 128b2bc2-3813-49ce-a305-0f1ec6b7bd16
function do_read_nifti(path_ix)
	return niread(all_nifti.file[path_ix])
end

# ╔═╡ 9b465222-edf9-4b05-980c-60466ad0c912
ni = do_read_nifti(path_ix_nifti)

# ╔═╡ 56df2f62-6600-433b-ab3f-5d4d2949a0a3
_evts2 = do_read_tsv(1)


# ╔═╡ 59e19266-7cba-47d9-a7f1-3e9776519f9e


# ╔═╡ b77e5a08-eec9-4984-a971-68234137b32b
ext = Base.get_extension(Unfold,:UnfoldBSplineKitExt)

# ╔═╡ 42a76743-97cd-4b01-8203-890218819e9a
begin
	#β = coef(m)[20,2:end]
	function eval_spl(x_rt,m,β)
		a = Unfold.formulas(m)[1].rhs.term.terms[2]
		X = ext.splFunction(x_rt,a)
		X = X[:, Not(Int(ceil(end / 2)))]
		return X*β
	end
end

# ╔═╡ f9d45bce-626b-4666-8c19-da033ddcc504
# ╠═╡ disabled = true
#=╠═╡
begin
	colormap = to_colormap(:plasma)
colormap[1] = RGBAf(0,0,0,0)
f3,ax3,h3 = volume(1 .- log10.(roi4_with_nlin_p),algorithm=:absorption,colormap=colormap,absorption=50)
	Colorbar(f3[1,2],h3)
	f3
end
  ╠═╡ =#

# ╔═╡ 7945f3af-c491-4eee-a461-54d7314ad0b6
const AoG = UnfoldMakie.AlgebraOfGraphics

# ╔═╡ 9f896b11-f7ef-44ed-b9e1-191783ef86a0


# ╔═╡ ccd29bf5-bd65-4ae9-a3a2-b82e76c87096
WGLMakie.Page()

# ╔═╡ 2db9cac5-efc8-4955-a42c-ff5e193ad9fc
#=╠═╡
contour(1 .- log10.(roi4_with_nlin_p),colormap=colormap)

  ╠═╡ =#

# ╔═╡ 8446d2e5-a58f-4b55-8144-801ad4a480bf
heatmap(ni[:,:,45,50])

# ╔═╡ ac232bd8-2647-4247-afc3-79c3ab56fbfa
# ╠═╡ show_logs = false
#CondaPkg.add("templateflow")

# ╔═╡ 78f3de36-a881-45bf-a352-90af422e7c95
py_templateflow = pyimport("templateflow")

# ╔═╡ b3b9257e-261c-45b5-96fe-73bb5f806ba0
# ╠═╡ show_logs = false
atlas_file = py_templateflow.api.get("MNI152NLin2009cAsym", resolution=2)

# ╔═╡ 50792c71-d02e-4bbf-b1a5-ec19e7add87e
atlas_labels = download("https://raw.githubusercontent.com/templateflow/tpl-MNI152NLin2009cAsym/e797e29df0fbfc87991c93a03369035897e2b513/tpl-MNI152NLin2009cAsym_atlas-Schaefer2018_desc-100Parcels7Networks_dseg.tsv") |> x->CSV.read(x,DataFrame)

# ╔═╡ 6988ca5e-d677-4a8f-9df3-fada317beadb
split(atlas_labels[25,:name],'_')

# ╔═╡ ad1a06ba-251f-4043-a18c-1de4ee387dfc
atlas_labels

# ╔═╡ e02a1cd5-fcfc-4018-a1a8-fc201a6adaab
function Unfold.time_expand(Xorg::AbstractArray, basisfunction::HRFBasis, onsets)    
        bases = Unfold.kernel.(Ref(basisfunction), eachrow(onsets))
        return Unfold.time_expand(Xorg, basisfunction, onsets[!, 1], bases)
end

# ╔═╡ 31a70dd6-03ec-4ca0-8e8e-74de6e05b068
evts

# ╔═╡ fb36cd7b-93eb-46fa-8990-5c81f9af4597


# ╔═╡ 136d1167-3e6b-4d60-96ab-4d40a032d40d
out = nl.resample_to_img(atlas_file[16],all_nifti.file[1],interpolation="nearest")

# ╔═╡ e05c7a33-9e83-4402-8acf-74cfa3f23f99
roi4 = pyconvert(Array,(out.get_fdata()))

# ╔═╡ 3ae1cea4-5e6c-4a40-9ff2-26915b180915
let
	f,ax,h = heatmap(roi4[:,:,50])
	heatmap!(ni[:,:,50,1],alpha=0.8)
	f
end

# ╔═╡ c2692000-49ab-44fb-ac7d-f68f5a043af6
	function do_fit(ni,evts,f)
		@info evts.worker_id[1]
		evts = deepcopy(evts) # no sideeffects

		# mean over ROIs
		meansignals = [mean(ni[roi4 .== i,:],dims=1)[1,:] for i in 1:100]
		
		#filter
		responsetype = Highpass(1/128)
		designmethod = Butterworth(4)
		myfilt = (x) -> filt(digitalfilter(responsetype, designmethod; fs=1/TR), x)
		meansignals_dccorrected = map(x->myfilt(x.-mean(x)),meansignals)
		meansignal = hcat(meansignals_dccorrected...)'

		# normalize response times
		evts.response_time = disallowmissing(coalesce.(evts.response_time,mean(skipmissing(evts.response_time)))) # mean impute
		
		evts.response_time = collect(winsor(evts.response_time;prop = 0.05)) # winsorize
		
		evts.response_time_centered = evts.response_time .- mean(evts.response_time) # mean center
		
		evts.response_time_centered = evts.response_time_centered ./ std(evts.response_time_centered) # normalize

		# modelfit
		#basis = Unfold.hrfbasis(TR;name="test")
		
		#gpu_solver =(x, y) -> Unfold.solver_predefined(x, y; solver=:qr)
		#m = Unfold.fit(UnfoldModel, designDict, evts, cu(dat), solver = gpu_solver)
		basis = Unfold.firbasis((-1,15),1/TR)
		#@info "meansignal" size(meansignal) typeof(meansignal)
		m = fit(UnfoldModel,[Any=>(f,basis)],evts,meansignal)
		return m
	end


# ╔═╡ d8722b44-c724-4136-a3a6-5911643a34a8
begin
	run_on_n = 106 # 106 is all
	m_all_lin = Vector{Any}(undef,run_on_n)
	m_all_nlin = Vector{Any}(undef,run_on_n)
	offsetix = 0 #50
	for ix in 1:run_on_n
		try
		_ni = do_read_nifti(ix+offsetix)
		_evts = do_read_tsv(ix+offsetix)
		m_all_lin[ix] = do_fit(_ni,_evts,@formula(0~1+condition+response_time_centered))
		m_all_nlin[ix] = do_fit(_ni,_evts,@formula(0~1+condition+ spl(response_time_centered,10)))
		catch
			@info "error with subject-ix $(ix+offsetix)"
		end
	end
end
	

# ╔═╡ ad3480e1-7510-40c3-9096-0ef2b1108c4a
begin
	good_ix = isassigned.(Ref(m_all_lin),1:length(m_all_lin))
	coefs_lin = extract_coefs(vcat(m_all_lin[good_ix]...), :response_time_centered,Any)
p_values_lin =
    mapslices(c -> pvalue(OneSampleHotellingT2Test(c', [0])), coefs_lin, dims = (3, 4)) |>
    x -> dropdims(x, dims = (3, 4));

coefs_nlin = extract_coefs(vcat(m_all_nlin[good_ix]...), :response_time_centered,Any)
p_values_nlin =
    mapslices(c -> pvalue(OneSampleHotellingT2Test(c', [0,0,0,0,0,0,0,0,0])), coefs_nlin, dims = (3, 4)) |>
    x -> dropdims(x, dims = (3, 4));

end;

# ╔═╡ 08cad98b-bc35-4b4b-b190-8dab9f11ef95
sum(good_ix)

# ╔═╡ b5066378-2d8c-4101-a0ff-8429d6fb811d
findall(p_values_nlin[:,10].<0.0000006)

# ╔═╡ d593902f-ce7d-4dae-a77d-6028ddc986c9
findall(p_values_nlin[:,10].<0.05/(100*24))

# ╔═╡ 52418d10-6aa2-4ae5-a55c-21a596520e06
let
	f = Figure()

	heatmap(f[1,1],p_values_lin',colorscale=log10,colorrange=[1,0.000001])
	heatmap(f[1,2],p_values_lin'.<0.05/(100*24))
	heatmap(f[2,1],p_values_nlin',colorscale=log10,colorrange=[1,0.000001])
	heatmap(f[2,2],p_values_nlin'.<0.05/(100*24))
	f
end

# ╔═╡ fe91ed09-b02a-46ad-8201-bbdb3871584e
let
f = Figure()
	ax = Axis(f[1,1],yscale=log10)
		h = plot!(ax,(p_values_lin[:,9]),label="linear")
h2 = plot!(ax,(p_values_nlin[:,9]),label="non-linear",)
	hlines!([0.05,0.05/100],color=:black,linestyle=:dash)
	Legend(f[1,2],ax)
			  f
end

# ╔═╡ 934cae17-fbc7-436f-bca5-8a9add83192d
let
f = Figure()
	ax = Axis(f[1,1],yscale=log10)
		h = series!(ax,p_values_lin,solid_color=:black,label="linear")
	h2 = series!(ax,p_values_nlin,solid_color=:orange,label="non-linear")
	hlines!([0.05,0.05/100],color=:black,linestyle=:dash)
	Legend(f[1,2],ax)
			  f
end

# ╔═╡ 2ae16a33-bc68-48d8-ab78-c1e89c3d224b
# ╠═╡ show_logs = false

begin
	roi4_with_nlin_p = similar(roi4)
	roi4_with_nlin_p .= NaN
	roi4_with_lin_p = similar(roi4)
	roi4_with_lin_p .= NaN
	for r in 1:100
		_ix = roi4 .== r
		roi4_with_nlin_p[_ix] .= p_values_nlin[r,10]
		roi4_with_lin_p[_ix] .= p_values_lin[r,10]

	end
end	

# ╔═╡ 9099f03a-aa0d-41c6-a930-d42f94610b32
sortperm(p_values_nlin[:,10])

# ╔═╡ e8ea0f12-c283-4f32-b8ee-2df2279a74e3
minimum(p_values_nlin)

# ╔═╡ cb2949e8-5c35-4f22-bc72-d51e737a049a
size(p_values_nlin)

# ╔═╡ e2ecc519-a871-4c27-809f-763e64c0cbce
p_values_lin[20]

# ╔═╡ a66402c0-55cb-439d-bac3-2969a852d2cd
_effects_all = map(x->effects(Dict(:response_time_centered=>-1:0.2:2),x)|>x->subset(x,:channel => x->x.==18),m_all_nlin[good_ix]) #18

#20

#23

#74


# ╔═╡ 57fcbd56-e051-410c-ae5d-a9dfb05a9d19
begin
_effects_avg = _effects_all[1]
	_effects_avg.yhat .= mean.(winsor.(collect.(skipmissing.(eachrow(hcat([e.yhat for e in _effects_all]...)))),prop=0.1))
end

# ╔═╡ 109056bf-e3b4-4021-af03-3ff05643f99c
plot_erp(_effects_avg,mapping=(;color=:response_time_centered,group=:response_time_centered))

# ╔═╡ ed02ab26-73e4-44c2-99e6-2bebbad19e36
AoG.data(subset(_effects_avg,:time=>x->x.==5.44))*AoG.mapping(:response_time_centered,:yhat)*AoG.visual(Lines)|>AoG.draw

# ╔═╡ 6f9b2c6b-477b-4593-a2c1-1ccf4dab42f1
AoG.data(_effects_avg)*AoG.mapping(:response_time_centered,:yhat,color=:time,group=:time=>nonnumeric)*AoG.visual(Lines)|>AoG.draw

# ╔═╡ 8f40901a-d205-43c3-a8ea-eb5d143bf44d
_effects_avg.time|>unique|>sort

# ╔═╡ 3e897e59-cb21-48af-9002-ab7f35f3bb8b
let
	f = Figure()
	highlightroi = [70]#[18,20,23] #[25,33,82]# sortperm(p_values_nlin,dims=1)[1:3]
	clim = ((0.05/(100),0.05))
	p_dat = (roi4_with_nlin_p)
	options = (;axis=(;aspect=DataAspect()),colorrange=clim,colorscale=log10,colormap = Reverse(:reds),highclip=(:black,0.2),lowclip=:blue)
	h1 = heatmap(f[1,1],nanminimum(p_dat,dims=3)[:,:,1];options...)
	h2 = heatmap(f[1,2],nanminimum(p_dat,dims=2)[:,1,:];options...)
	h3 = heatmap(f[2,1],nanminimum(p_dat,dims=1)[1,:,:];options...)
	Colorbar(f[1,3],h1.plot,tellwidth=true,label="p-value")
	hidespines!.([h1.axis,h2.axis,h3.axis])
	hidedecorations!.([h1.axis,h2.axis,h3.axis])

	options = (;levels = 1,linewidth=3)
	#ax_roi = Axis(f[2,2])
	for (ix,roi) = enumerate(highlightroi)
		c = cgrad(:Accent_4 ,4)[ix]
		contour!(h1.axis,any(roi4.==roi,dims=3)[:,:,1];color=c,options...)
		contour!(h2.axis,any(roi4.==roi,dims=2)[:,1,:];color=c,options...)
		contour!(h3.axis,any(roi4.==roi,dims=1)[1,:,:];color=c,options...)

		
		#_,_eval_spline = my_eval_spl(roi)
		
		#_m = mean.(_eval_spline)./1000
		
		#_ci = 1.96 *std.(_eval_spline)./sqrt(50) ./1000
		#band!(ax_roi,x_rt,_m.-_ci,_m.+_ci,color=(c,0.3))
		#_h = lines!(ax_roi,x_rt,_m, color=c,linewidth=3, label=split(atlas_labels[roi,:name],'_')[end-1])
		#translate!(_h,0,0,20)

	end
	plot_erp!(f[2,2:3],_effects_avg,mapping=(;color=:response_time_centered,group=:response_time_centered),axis=(;ylabel="BOLD [a.u]",xlabel="Time [s]"))
	#ax_roi.xlabel = "Normalized, centered RT [σ]"
	#ax_roi.ylabel = "centered activation [a.u]"
	#Legend(f[2,3],ax_roi)
	#hidespines!(ax_roi,:r,:t)
f
end

# ╔═╡ 289154e2-2776-4fb6-9dea-cf0eb8a9f959
m_all_nlin[1]

# ╔═╡ 291647f2-ddce-4655-9257-62f48c7de316
let
f = Figure()
	ax = Axis(f[1,1])
		density!.(ax,map(x->x[1].response_time_centered,Unfold.events.(m_all_nlin[good_ix])),strokecolor=:black,strokewidth=2,color=(:black,0.))#,bins=-2:0.1:3)
	f
end

# ╔═╡ 35d789e3-431a-47dd-97a7-ee5edc6515d1
m = do_fit(roi4,evts,f)

# ╔═╡ 39a0e38b-afe7-45aa-a221-b248a636d214
let
f = plot(predict(m)[5,:])
	plot!(meansignal[5,:])
	f
end

# ╔═╡ 7b536980-58cc-4075-9284-b243d3c2514d
lines(coef(m)[:,2])

# ╔═╡ ff6f21a4-ce71-4bde-a242-88e50b799a37
plot_erp(effects(Dict(:response_time=>range(0.5,1,5)),m),mapping=(;color=:response_time,group=:response_time),axis=(;ylabel="BOLD"))


# ╔═╡ c924d34e-799b-4683-b1cc-82ef53c37307
let
	f =Figure()
heatmap(f[1,1],coef(m)[:,1:23])
	heatmap(f[1,2],coef(m)[:,24:end])
	f
end

# ╔═╡ Cell order:
# ╠═76f5c899-26a2-4bf3-b390-1f76ccf594d4
# ╠═769aa72b-3a9d-41cb-bb0b-e6a2414aea01
# ╠═6e6a5571-28f3-4e58-9118-24d015e8c87a
# ╠═a6fb95f6-1ed0-480f-afb5-1cbf6ff6bb3c
# ╠═8ac12029-c04f-457a-b85d-8e92a7771fdb
# ╠═6f45836c-2030-11f0-2c2e-a3821d64a916
# ╠═387e6752-5de1-4d46-931f-b5a2af62c0f9
# ╠═8021cedb-64e8-4fe8-a609-8ee08eb0b503
# ╠═127def47-3c07-4d1c-b8e7-9a3ebc86f31d
# ╠═5a6bb19c-9e40-4ee1-996e-7e6595740c86
# ╠═a2324a77-410b-4a94-9e32-374a303e973d
# ╠═5a2bcf77-cd88-484c-8024-889b85168263
# ╠═cf0019b9-60a2-4c48-b9d3-d0fbe686701d
# ╠═d0b32cf3-9f5f-46e8-86df-3eee181bcd37
# ╠═6fa5d0cd-f88e-419f-9bd0-5e4ce0bb633a
# ╠═f955041d-7e38-4983-9057-69e4565700db
# ╠═7560df0e-78f1-4b97-b21e-f335dfb53bc7
# ╠═4fcccac2-b645-4bc6-8c26-3c0dc0b9e4ec
# ╠═f426690e-854f-473f-9dc7-5aae9542c180
# ╠═f0f7360a-b52b-4261-a1b3-4cb790eb40b3
# ╠═0dcefc1f-58c1-4e37-89ce-4400e8ff8aab
# ╠═78325e72-8edd-4643-9664-ea2c2c19215e
# ╠═0251d6b8-2740-4040-aa15-39151bf31a9c
# ╠═323de92a-8230-4b1c-b3ee-cc1ddd4060c5
# ╠═bcc5a43d-cfbe-45d6-b841-294461739da4
# ╠═98d1e30d-1718-4b8b-bb28-33a79ef84886
# ╠═128b2bc2-3813-49ce-a305-0f1ec6b7bd16
# ╠═9b465222-edf9-4b05-980c-60466ad0c912
# ╠═08cad98b-bc35-4b4b-b190-8dab9f11ef95
# ╠═56df2f62-6600-433b-ab3f-5d4d2949a0a3
# ╠═d8722b44-c724-4136-a3a6-5911643a34a8
# ╠═ad3480e1-7510-40c3-9096-0ef2b1108c4a
# ╠═dc7a3d31-a157-4ce6-bf89-04d1e29cf44e
# ╠═83cb0942-f457-4924-af7c-dab196cad696
# ╠═b5066378-2d8c-4101-a0ff-8429d6fb811d
# ╠═d593902f-ce7d-4dae-a77d-6028ddc986c9
# ╠═52418d10-6aa2-4ae5-a55c-21a596520e06
# ╠═59e19266-7cba-47d9-a7f1-3e9776519f9e
# ╠═fe91ed09-b02a-46ad-8201-bbdb3871584e
# ╠═934cae17-fbc7-436f-bca5-8a9add83192d
# ╠═b77e5a08-eec9-4984-a971-68234137b32b
# ╠═42a76743-97cd-4b01-8203-890218819e9a
# ╠═2ae16a33-bc68-48d8-ab78-c1e89c3d224b
# ╠═f9d45bce-626b-4666-8c19-da033ddcc504
# ╠═a66402c0-55cb-439d-bac3-2969a852d2cd
# ╠═57fcbd56-e051-410c-ae5d-a9dfb05a9d19
# ╠═109056bf-e3b4-4021-af03-3ff05643f99c
# ╠═ed02ab26-73e4-44c2-99e6-2bebbad19e36
# ╠═6f9b2c6b-477b-4593-a2c1-1ccf4dab42f1
# ╠═8f40901a-d205-43c3-a8ea-eb5d143bf44d
# ╠═7945f3af-c491-4eee-a461-54d7314ad0b6
# ╟─289154e2-2776-4fb6-9dea-cf0eb8a9f959
# ╠═9099f03a-aa0d-41c6-a930-d42f94610b32
# ╠═e8ea0f12-c283-4f32-b8ee-2df2279a74e3
# ╠═6988ca5e-d677-4a8f-9df3-fada317beadb
# ╠═cb2949e8-5c35-4f22-bc72-d51e737a049a
# ╠═3e897e59-cb21-48af-9002-ab7f35f3bb8b
# ╠═e2ecc519-a871-4c27-809f-763e64c0cbce
# ╠═0ade7e1f-c3ab-46af-af23-fb4fbe939737
# ╠═9f896b11-f7ef-44ed-b9e1-191783ef86a0
# ╠═ccd29bf5-bd65-4ae9-a3a2-b82e76c87096
# ╠═2db9cac5-efc8-4955-a42c-ff5e193ad9fc
# ╠═291647f2-ddce-4655-9257-62f48c7de316
# ╠═8446d2e5-a58f-4b55-8144-801ad4a480bf
# ╠═ac232bd8-2647-4247-afc3-79c3ab56fbfa
# ╠═78f3de36-a881-45bf-a352-90af422e7c95
# ╠═b3b9257e-261c-45b5-96fe-73bb5f806ba0
# ╠═50792c71-d02e-4bbf-b1a5-ec19e7add87e
# ╠═3ae1cea4-5e6c-4a40-9ff2-26915b180915
# ╠═ad1a06ba-251f-4043-a18c-1de4ee387dfc
# ╠═e02a1cd5-fcfc-4018-a1a8-fc201a6adaab
# ╠═35d789e3-431a-47dd-97a7-ee5edc6515d1
# ╠═c2692000-49ab-44fb-ac7d-f68f5a043af6
# ╠═c1c2ee66-bec6-4a6f-ae0f-df168c9ac22a
# ╠═31a70dd6-03ec-4ca0-8e8e-74de6e05b068
# ╠═39a0e38b-afe7-45aa-a221-b248a636d214
# ╠═fb36cd7b-93eb-46fa-8990-5c81f9af4597
# ╠═7b536980-58cc-4075-9284-b243d3c2514d
# ╠═ff6f21a4-ce71-4bde-a242-88e50b799a37
# ╠═c924d34e-799b-4683-b1cc-82ef53c37307
# ╠═136d1167-3e6b-4d60-96ab-4d40a032d40d
# ╠═e05c7a33-9e83-4402-8acf-74cfa3f23f99
