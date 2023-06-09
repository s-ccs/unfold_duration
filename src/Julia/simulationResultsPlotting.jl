
using CSV, DataFrames
using CairoMakie, AlgebraOfGraphics, MixedModelsMakie
using GLM, StatsModels, MixedModels
using DataFramesMeta
using StatsBase


folder = "sim_realNoise_HanningShapes_filtered"
fpath = joinpath("/store/projects/unfold_duration/local/simulationResults/", folder, "simulationResults_" * folder * "_MSE.csv")

df = CSV.read(fpath, DataFrame)

safeFig = false

##############################

plt_wOV = data(@rsubset(df,
    :shape == "scaledHanning",
    :noise =="noise-1.00",
    :overlap == "overlap-1",
    :overlapmod == "overlapmod-1.5.mat",
    :overlapdist == "halfnormal",
    #:overlapdist == "uniform",
    :durEffect == "durEffect-0",
    :formula != "theoretical",
    :formula !="y~1",
    )) * visual(BoxPlot) * mapping(:formula, :normMSE_nodc, color=:formula)

plt_wOC = data(@rsubset(df,
    :shape == "scaledHanning",
    :noise =="noise-1.00",
    :overlap == "overlap-1",
    :overlapmod == "overlapmod-1.5.mat",
    :overlapdist == "halfnormal",
    #:overlapdist == "uniform",
    :durEffect == "durEffect-0",
    :formula != "theoretical",
    :formula !="y~1",
    )) * visual(BoxPlot) * mapping(:formula, :normMSE, color=:formula)

plt_durEF = data(@rsubset(df,
    :shape == "scaledHanning",
    :noise =="noise-1.00",
    :overlap == "overlap-1",
    :overlapmod == "overlapmod-1.5.mat",
    :overlapdist == "halfnormal",
    :durEffect == "durEffect-1",
    :formula != "theoretical",
    :formula != "y~1",
    )) * visual(BoxPlot) * mapping(:formula, :normMSE, color=:formula)

plt_Noise = data(@rsubset(df,
    :shape == "scaledHanning",
    :noise =="noise-1.00",
    :overlap == "overlap-1",
    :overlapmod == "overlapmod-1.5.mat",
    :overlapdist == "halfnormal",
    #:overlapdist == "uniform",
    :durEffect == "durEffect-1",
    :formula != "theoretical",
    :formula !="y~1",
    )) * visual(BoxPlot) * mapping(:formula, :normMSE, color=:formula)

############################################
resolution = (2480, 1748)
fig_3 = Figure(; resolution)
ax_31 = Axis(fig_3[1,1], title = "No overlap correction", xgridvisible = false,
ygridvisible = false)
ax_32 = Axis(fig_3[2,1], title = "With overlap correction", xgridvisible = false,
ygridvisible = false)
ax_33 = Axis(fig_3[:,2], title = "With OC and duration effect", xgridvisible = false,
ygridvisible = false)

draw!(ax_31, plt_wOV)
ylims!(ax_31, (-0.2, 2.3))
hlines!(ax_31, [0, 1], color = :red)
draw!(ax_32, plt_wOC)
ylims!(ax_32, (-0.2, 2.3))
hlines!(ax_32, [0, 1], color = :red)
draw!(ax_33, plt_durEF)
ylims!(-0.2, 2.3)
hlines!(ax_33, [0, 1], color = :red)

fig_3