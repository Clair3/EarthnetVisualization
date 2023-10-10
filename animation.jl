using JLD2, CairoMakieMakie, Dates
ds = load("map_error_unet.jld2")
lon = ds["longitude"]
lat = ds["latitude"]
tempo = ds["time"]
mse = ds["mse"]
a = load("correlation_landscape_unet.jld2")
lc_maj = a["lc_maj"]
u = unique(tempo)
p = sortperm(u)
u = u[p]

idx = Observable(10)
indxs = @lift(tempo .== u[$idx])
fig = Figure()
ax = Axis(fig[1,1], aspect = 1)
scatter!(ax, @lift(lon[$indxs]), @lift(lat[$indxs]), color = @lift(mse[$indxs]),
    markersize = @lift(300*mse[$indxs]),
    colorrange = (0, 0.04),
    )
fig

idx = Observable(1)

for i in 1:10:90
    indxs = tempo .== u[i]
    #println(sum(indxs[]))
    fig = Figure()
    ax = Axis(fig[1,1], aspect = 1, title = "$(Date(unix2datetime(u[i])))")
    scatter!(ax, lon[indxs], lat[indxs], color = lc_maj[indxs[:,1]],
        markersize = 300*mse[indxs],
        #colorrange = (0, 0.04),
        )
    println(lc_maj[indxs[:,1]])
    display(fig)
    sleep(0.5)
end


using CairoMakie
using Dates
using CompoundPeriods
using TimeSeries
using Printf
using Colors
include("load_files.jl")
ENV["DISPLAY"] = ":0"
using GLFW


file = "30SXD0426.nc"

path_pred = "EarthNet2023/data/pred_v0/" 
path_test = "EarthNet2023/data/test_v0/" 

pred_file = path_pred * file
test_file = path_test * file

fontsize_theme = Theme(fontsize = 25)
set_theme!(fontsize_theme)

# initial code
# target, prediction, t, x, y, lc = loadcube(pred_file) 
# red, green, blue, ndvi = loadtestcube(test_file)
# red, green, blue, ndvi = replace(red, missing => NaN), replace(green, missing => NaN), replace(blue, missing => NaN), replace(ndvi, missing => NaN)
# target, prediction = mask_data(target, lc), mask_data(prediction, lc)
# target, prediction = replace(target, missing => NaN), replace(prediction, missing => NaN)

prediction, t, latitude, longitude = load_predcube(pred_file)
red, green, blue, ndvi, s2_mask, landcover = load_testcube(test_file)
len_time, len_lon, len_lat = size(t, 1), size(longitude, 1), size(latitude, 1)  #size(t) = 30

target = mask_data(ndvi, s2_mask, landcover)
prediction = mask_data(prediction, s2_mask, landcover)
red, green, blue = replace(red, missing => NaN), replace(green, missing => NaN), replace(blue, missing => NaN)
target, prediction = replace(target, missing => NaN), replace(prediction, missing => NaN)


rgb = Any[]
for i in 1:10
    v = vec([RGBA(red[35 + i, j, k], green[35 + i, j, k], blue[35 + i, j, k],1) for j = 1:size(red, 2), k = 1:size(red, 3)])
    push!(rgb, v)
end
positions = vec([Point2f(j, k) for j = 1:128, k = 1:128])



idx = Observable(1)
color = @lift(3 * rgb[$idx])
fig = Figure(resolution=(1000, 1000), backgroundcolor=:grey95)
axrgb = Axis(fig[1, 1], aspect = 1, title = @lift("Observation RGB - $($idx) / 10 - $(Date(t[$idx]))"), showaxis=false)
meshscatter!(axrgb, positions; markersize = 1, color = color, shading=  false)

colormap = cgrad(:Spectral_11, rev=true)
colorrange=(0,1)
colort = @lift(target[$idx,:,:])
ax = Axis(fig[2, 1], aspect = 1, title = "Observation NDVI", showaxis=false)
hmap = heatmap!(ax, 1:128, 1:128, colort; colormap, colorrange) 
Colorbar(fig[2, 3], hmap; height = Relative(0.75), tickwidth = 2)

axp = Axis(fig[2, 2], aspect = 1, title = "Forecast NDVI", showaxis=false)
hmap = heatmap!(axp, 1:128, 1:128, @lift(prediction[$idx,:,:]); colormap, colorrange) 

axd = Axis(fig[1, 2], aspect = 1, title = "Absolute Prediction Error", showaxis=false)
hmap = heatmap!(axd, 1:128, 1:128, @lift(abs.(target[$idx,:,:] .- prediction[$idx,:,:])); colormap = :Blues, colorrange=(0, 0.2)) 
Colorbar(fig[1, 3], hmap; height = Relative(0.75), tickwidth = 2)

hidedecorations!.([axrgb, ax, axp, axd], label=false)


record(fig, "anim_$(ffile).gif", framerate = 1) do io
    for i in 1:10
        idx[] = i
        recordframe!(io)
        sleep(0.7)
    end
end




