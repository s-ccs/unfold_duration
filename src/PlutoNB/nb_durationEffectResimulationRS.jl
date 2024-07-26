### A Pluto.jl notebook ###
# v0.19.37

using Markdown
using InteractiveUtils

# This Pluto notebook uses @bind for interactivity. When running this notebook outside of Pluto, the following 'mock version' of @bind gives bound variables a default value (instead of an error).
macro bind(def, element)
    quote
        local iv = try Base.loaded_modules[Base.PkgId(Base.UUID("6e696c72-6542-2067-7265-42206c756150"), "AbstractPlutoDingetjes")].Bonds.initial_value catch; b -> missing; end
        local el = $(esc(element))
        global $(esc(def)) = Core.applicable(Base.get, el) ? Base.get(el) : iv(el)
        el
    end
end

# ╔═╡ 6b1d84e6-dfb9-11ee-2244-77b58e1fd9c1
begin
	using Pkg
	Pkg.activate(mktempdir())
	Pkg.add(["Random","DataFrames","PlutoUI","Unfold","UnfoldMakie","CairoMakie", "Distributions"])
	Pkg.add(url="https://github.com/unfoldtoolbox/unfoldSim.jl",rev="sequFormulaOnset")
end
		

# ╔═╡ 2c2a6f3b-3938-45ab-99a1-38c6c6890d3a
using UnfoldSim,Random,DataFrames,PlutoUI,Unfold,UnfoldMakie,CairoMakie,Distributions

# ╔═╡ bfa47a6f-b2f3-45c3-b90c-4bc7c4f0098c
using Statistics

# ╔═╡ c07e3eac-d60e-42ad-97c8-6ca8617aaa8a
offset = 0.15 #s

# ╔═╡ 58aa2f97-c2bb-491a-8a7f-3f31106e9810
	sfreq = 100


# ╔═╡ 80ca6fb1-633e-4f8a-83e6-f2d7e905786d
function half_hanning(k,duration)
	h = UnfoldSim.DSP.hanning
	fullhanning = h(Int(k*2))
	firsthanning = fullhanning[1:end÷2]
	secondhanning = h(Int(duration.*2))
	
	return vcat(firsthanning,secondhanning[end÷2+1:end])
end

# ╔═╡ 9b176a6f-ace4-4ff7-90d4-f85996865a11
0.15+ 1/0.2887*0.2

# ╔═╡ fc85b5ff-e3c9-45ad-b74f-48226a675e7d


# ╔═╡ 04861840-b0be-4f15-891e-ebc88c3a49dd
@bind λ PlutoUI.Slider(0:0.01:2,show_value=true)

# ╔═╡ b8a26cfb-1863-4edc-9326-73203779fcff
function solver_regularization(
    X,
    data::AbstractArray{T,2};
    multithreading = true,
) where {T<:Union{Missing,<:Number}}
    minfo = Array{Unfold.IterativeSolvers.ConvergenceHistory,1}(undef, size(data, 1))

    beta = zeros(size(data, 1), size(X, 2)) # had issues with undef

    for ch = 1:size(data, 1)
        dd = view(data, ch, :)
        ix = @. !ismissing(dd)
        # use the previous channel as a starting point
        ch == 1 || copyto!(view(beta, ch, :), view(beta, ch - 1, :))

        beta[ch, :], h =
            Unfold.IterativeSolvers.lsmr!(@view(beta[ch, :]), (X[ix, :]), @view(data[ch, ix]), log = true,λ=λ)

        minfo[ch] = h
    end


	modelfit = Unfold.LinearModelFit(beta, ["lsmr", minfo])
    
    return modelfit
end

# ╔═╡ a0f55698-e320-4bfd-99b4-0bc424e5682c
@bind signal_strength PlutoUI.Slider(0:1:5,show_value=true,default=1)

# ╔═╡ 196b7d9d-a2e7-4062-90cb-6fcd29bef255
function duration_kernel(design)
	evts = generate_events(design)
	
	return signal_strength .*half_hanning.(Int(offset*sfreq),evts.duration)
end

# ╔═╡ ed1b50f3-7084-42fb-84cc-374d3dca6b14
@bind additional_jitter CheckBox()

# ╔═╡ 525b27cb-9569-4e14-8569-27b66931d486
begin
	struct MyManualOnset <: AbstractOnset end
	function UnfoldSim.simulate_interonset_distances(rng, onset::MyManualOnset, design)
		evs = generate_events(design)
	   #iod =  Int.(round.(evs.duration.*0.66*0.8))
		#iod =   .+ 
		iod = Int.(round.(evs.duration))#.- Int(0.13*sfreq)
		@info iod
	   if additional_jitter
		   jit = 0.1
		   j = Int.(round.(rand(rng,length(evs.duration)).*jit*sfreq .- jit*sfreq./2))
		   @info j
	   iod = iod.+j
	   end
		@show std(iod)
		iod = vcat(0,iod[1:end-1])
		return iod
	end
end

# ╔═╡ a0efbfd5-bb9f-4502-a730-19eb58a731d9
@bind noise CheckBox()

# ╔═╡ 9d56590e-9d84-4fe5-9d11-574348194809
@bind shuffle_duration_before_fit CheckBox()

# ╔═╡ df8bea1f-09c0-4035-b89d-c8035fcf4b6f
@bind jitter_to_duration_before_fit PlutoUI.Slider(0:0.1:1,show_value=true)

# ╔═╡ 7a018ed9-4647-4d73-9080-fa71b71b4b5f
@bind spline_or_cat Select(["spline","none","linear","cat"])

# ╔═╡ 6140a7f5-c608-416f-bfd9-4fc6bfe063ca
@bind μ PlutoUI.Slider(0:0.5:5,show_value=true,default=3.5)

# ╔═╡ 5164a459-e98e-4fe8-9454-e9819244fda3
@bind σ PlutoUI.Slider(0:0.1:1,show_value=true,default=0.2)

# ╔═╡ 0f515695-4458-42fd-9af9-0ed218a84ed7
begin
	fun = LogNormal(μ, σ)
	x = round.(0 .+ rand(fun, 500)) ./ sfreq 
	@show size(x)
	hist(x; bins = 30)
end

# ╔═╡ 39a9bc56-ee9b-4019-96ca-347d21c71fee
std(x)

# ╔═╡ b27d3549-2bcb-4946-8f8a-cc62309173ab
@bind dist Select(["uniform", "lognormal"])

# ╔═╡ 3135569f-90d3-4fa9-83ca-564ef902cfb7
begin
	if dist == "uniform"
		durations = round.((rand(500)/0.2887*0.2 .+ 0.15).*sfreq)./sfreq
	elseif dist == "lognormal"
		func = LogNormal(μ, σ)
		durations = round.(0 .+ rand(MersenneTwister(1), func, 500)) ./ sfreq 
	end
end

# ╔═╡ 90c13ae2-afb2-40cb-aee7-90005072028b
dur_eval = Int.(round.(sort(unique(round.(durations .*15)./15;))[2:end-1].*sfreq))

# ╔═╡ 8a37e4a6-eedb-4462-aa12-1fe1618a9cc0
(unique(dur_eval.*sfreq).+offset*sfreq)

# ╔═╡ a356f590-988d-4fc8-b144-8d5933f38304
unique(dur_eval)

# ╔═╡ 6344a370-4571-4686-b45b-eb2a2d50b687
begin
design2 = SingleSubjectDesign(
	conditions = Dict(
		:duration=> Int.(round.(durations.*sfreq)
		)),
	event_order_function=x->shuffle(MersenneTwister(1),x)
)
#design2 = RepeatDesign(design2, 40) MersenneTwister(seed)
end

# ╔═╡ c2d5b808-4cc9-437a-95a0-f6a5728c96d4
generate_events(design2)

# ╔═╡ f9a16eda-3fcd-4aae-b4a9-59b2557cb835
unique(generate_events(design2).duration)

# ╔═╡ 7bbdaa20-56d3-4c59-b28e-c8db0069b7d6
hist(generate_events(design2).duration,bins=100)

# ╔═╡ 81e6aecb-fe8e-4317-91ae-dcf7e6a2aacf
signal = LinearModelComponent(;
    basis = (duration_kernel,Int(offset*sfreq)+Int(round(maximum(durations)*sfreq))),
    formula = @formula(0 ~ 1),
    β = [1],

);

# ╔═╡ cf85bf2a-aa74-470a-8731-c40d90abe3a6
begin
series(simulate_component(MersenneTwister(1),signal,design2)',solid_color=:black)
	vlines!([15])
	current_figure()
end

# ╔═╡ af3cc915-dd3e-42c7-b619-3b37924db3e1
mean(durations)

# ╔═╡ 5b25c935-fc74-4b4c-bbc7-d2c5ab300603
@bind noiselevel PlutoUI.Slider(0:0.1:2,show_value=true)

# ╔═╡ 4ff48730-fe21-408c-a76d-45ccc59afa59
@bind seed PlutoUI.Slider(1:100,show_value=true)

# ╔═╡ c7756338-f201-4f89-b312-0261bcfd4c7a
data,evts = simulate(MersenneTwister(seed),design2,signal,MyManualOnset(),noise ? RedNoise(noiselevel = noiselevel) : NoNoise());

# ╔═╡ 29414ef2-090a-46c3-b84f-14c9ff6fbae6
hist(diff(evts.latency))

# ╔═╡ 3d23275e-1e92-48ad-b103-368389be8782
hist(evts.duration) 

# ╔═╡ 4508bf22-ee40-477f-be2a-8c0dbd15fe38
maximum(evts.duration)

# ╔═╡ 5086cba9-776d-4065-8cc3-7fa0a61f6855
diff(evts.latency)[1:10] .- evts.duration[1:10]

# ╔═╡ b9256f6f-4ee5-43c1-9505-198f405eedfb
begin
	ix = 500
lines(data[1:ix])
	vlines!(evts.latency[evts.latency.<ix],color=:red)
	current_figure()

end

# ╔═╡ 352c8aea-b4de-4740-9adc-21d968061302
begin
	evts.duration_cat = string.(evts.duration)
	f = if spline_or_cat == "spline"
		@formula(0~1+spl(duration,5))
	elseif spline_or_cat == "cat"
		@formula(0~1+duration_cat)
	elseif spline_or_cat == "none"
		@formula(0~1)
	elseif spline_or_cat == "linear"
		@formula(0~1+duration)
	else
		error("unknown spline_or_cat")
	end

	evts_fit = deepcopy(evts)
	if shuffle_duration_before_fit
		
	evts_fit.duration .= evts.duration[randperm(length(evts.duration))]
	end
	
	evts_fit.duration .= evts.duration .+ sfreq.*jitter_to_duration_before_fit * rand(length(evts.duration))
	
m = fit(UnfoldModel,Dict(Any=>(f,firbasis(τ=(-0.5,2),sfreq=sfreq,name="test"))),evts_fit,data;solver=(x,y)->solver_regularization(x,y));
end

# ╔═╡ b73f0ecc-d248-4e44-9ca9-057327f11fb7
begin
d = if (spline_or_cat == "spline")|(spline_or_cat == "linear" )
	Dict(:duration=>dur_eval)
	elseif spline_or_cat == "cat"
		
Dict(:duration_cat => string.(dur_eval))
		
	end

eff = effects(
	d
	,m)
end

# ╔═╡ 715882f1-8a03-47e6-a07d-da148b4a161c
evts.latency

# ╔═╡ a160ab6f-5697-4feb-9c91-1c17dfa1e222
let
	eff = deepcopy(eff)
	if spline_or_cat == "cat"
	eff.duration = parse.(Int,eff.duration_cat)
	end
plot_erp(eff;mapping=(;color=:duration,group=:duration),visual=(;colormap=:viridis),categorical_color=false)
end

# ╔═╡ b008b400-341b-4be7-8082-41196127bf7c
coeftable(m)

# ╔═╡ Cell order:
# ╠═6b1d84e6-dfb9-11ee-2244-77b58e1fd9c1
# ╠═2c2a6f3b-3938-45ab-99a1-38c6c6890d3a
# ╠═bfa47a6f-b2f3-45c3-b90c-4bc7c4f0098c
# ╠═90c13ae2-afb2-40cb-aee7-90005072028b
# ╠═3135569f-90d3-4fa9-83ca-564ef902cfb7
# ╠═29414ef2-090a-46c3-b84f-14c9ff6fbae6
# ╠═3d23275e-1e92-48ad-b103-368389be8782
# ╠═4508bf22-ee40-477f-be2a-8c0dbd15fe38
# ╠═5086cba9-776d-4065-8cc3-7fa0a61f6855
# ╠═c07e3eac-d60e-42ad-97c8-6ca8617aaa8a
# ╠═58aa2f97-c2bb-491a-8a7f-3f31106e9810
# ╠═6344a370-4571-4686-b45b-eb2a2d50b687
# ╠═c2d5b808-4cc9-437a-95a0-f6a5728c96d4
# ╠═81e6aecb-fe8e-4317-91ae-dcf7e6a2aacf
# ╠═196b7d9d-a2e7-4062-90cb-6fcd29bef255
# ╠═80ca6fb1-633e-4f8a-83e6-f2d7e905786d
# ╠═c7756338-f201-4f89-b312-0261bcfd4c7a
# ╠═b9256f6f-4ee5-43c1-9505-198f405eedfb
# ╠═9b176a6f-ace4-4ff7-90d4-f85996865a11
# ╠═525b27cb-9569-4e14-8569-27b66931d486
# ╠═cf85bf2a-aa74-470a-8731-c40d90abe3a6
# ╠═fc85b5ff-e3c9-45ad-b74f-48226a675e7d
# ╠═352c8aea-b4de-4740-9adc-21d968061302
# ╠═b8a26cfb-1863-4edc-9326-73203779fcff
# ╠═b73f0ecc-d248-4e44-9ca9-057327f11fb7
# ╠═f9a16eda-3fcd-4aae-b4a9-59b2557cb835
# ╠═8a37e4a6-eedb-4462-aa12-1fe1618a9cc0
# ╠═a356f590-988d-4fc8-b144-8d5933f38304
# ╠═7bbdaa20-56d3-4c59-b28e-c8db0069b7d6
# ╠═04861840-b0be-4f15-891e-ebc88c3a49dd
# ╠═a0f55698-e320-4bfd-99b4-0bc424e5682c
# ╠═ed1b50f3-7084-42fb-84cc-374d3dca6b14
# ╠═a0efbfd5-bb9f-4502-a730-19eb58a731d9
# ╠═9d56590e-9d84-4fe5-9d11-574348194809
# ╠═df8bea1f-09c0-4035-b89d-c8035fcf4b6f
# ╠═7a018ed9-4647-4d73-9080-fa71b71b4b5f
# ╠═0f515695-4458-42fd-9af9-0ed218a84ed7
# ╠═39a9bc56-ee9b-4019-96ca-347d21c71fee
# ╠═6140a7f5-c608-416f-bfd9-4fc6bfe063ca
# ╠═5164a459-e98e-4fe8-9454-e9819244fda3
# ╠═b27d3549-2bcb-4946-8f8a-cc62309173ab
# ╠═af3cc915-dd3e-42c7-b619-3b37924db3e1
# ╠═5b25c935-fc74-4b4c-bbc7-d2c5ab300603
# ╠═4ff48730-fe21-408c-a76d-45ccc59afa59
# ╠═715882f1-8a03-47e6-a07d-da148b4a161c
# ╠═a160ab6f-5697-4feb-9c91-1c17dfa1e222
# ╠═b008b400-341b-4be7-8082-41196127bf7c
