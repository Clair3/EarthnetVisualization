include("load_files.jl")

fontsize_theme = Theme(fontsize = 18)
set_theme!(fontsize_theme)

file = "31SEA1934.nc"

path_pred = "EarthNet2023/data/pred_v0/" 
path_test = "EarthNet2023/data/test_v0/" 

pred_file = path_pred * file
test_file = path_test * file

prediction, t, latitude, longitude = load_predcube(pred_file)
red, green, blue, ndvi, s2_mask, landcover = load_testcube(test_file)
len_time, len_lon, len_lat = size(t, 1), size(longitude, 1), size(latitude, 1)  #size(t) = 30

target = mask_data(ndvi, s2_mask, landcover)
prediction = mask_data(prediction, s2_mask, landcover)
red, green, blue = replace(red, missing => NaN), replace(green, missing => NaN), replace(blue, missing => NaN)
target, prediction = replace(target, missing => NaN), replace(prediction, missing => NaN)

positions = vec([Point2f(j, k) for j = 1:len_lon, k = 1:len_lon])
positionscube = vec([Point3f(i, j, k) for i = 1:len_lat, j = 1:len_lon, k = 1:len_time])
rgbcube = vec([RGBA(red[i, j, k], green[i, j, k], blue[i, j, k],1) for i = 1:len_lon, j = 1:len_lon, k = 1:len_time])


rgb = Any[]
    for k in 1:len_time
        v = vec([RGBA(red[i, j, k], green[i, j, k], blue[i, j, k],1) for i = 1:len_lat, j = 1:len_lon])
        push!(rgb, v)
end
colormap = cgrad(:Spectral_11, rev=true)
colorrange=(0,1)


posi = [Point3f(i,j,k) for i in 1:128 for j in 1:128 for k in 1:len_time if !isnan(target[i,j,k])]
colorst = [target[i,j,k] for i in 1:128 for j in 1:128 for k in 1:len_time if !isnan(target[i,j,k])]
colorsp = [prediction[i,j,k] for i in 1:128 for j in 1:128 for k in 1:len_time if !isnan(target[i,j,k])]
error = abs.(colorst .- colorsp)


fig = Figure(resolution = (1500,600))
gv = fig[1,1] =  GridLayout()
gh = fig[1,2] =  GridLayout()
axs3 = [Axis3(gv[i,1]; perspectiveness = 0.5,
    #azimuth = 2.19,
    protrusions=0,
    elevation = 0.57,
    xlabel = " ",
    ylabel = " ",
    zlabel = " ", aspect = (1,1,1)) for i in 1:4]
axs2 = [Axis(gh[i,j], aspect = 1) for i in 1:4, j in 1:9]

meshscatter!(axs3[1], positionscube; marker = Rect3f(Vec3f(-0.5), Vec3f(1)),
        markersize = 1, color = 3*rgbcube, shading=false)
meshscatter!(axs3[2], posi; markersize = 1, colormap, colorrange, shading = false,
        marker = Rect3f(Vec3f(-0.5), Vec3f(1)), color = colorst)
meshscatter!(axs3[3], posi; markersize = 1, colormap, colorrange, shading = false,
        marker = Rect3f(Vec3f(-0.5), Vec3f(1)), color = colorsp)
meshscatter!(axs3[4], posi; markersize = 1, colormap = :Blues, colorrange=(0,0.2), 
        marker = Rect3f(Vec3f(-0.5), Vec3f(1)), shading = false, color = error)

hidedecorations!.(axs3, label = false)
axs3[4].title = "||targ - pred||"
[axs3[i].titlefont = "sans" for i in 1:4]
[axs3[i].titlesize = 18 for i in 1:4]
[axs3[i].titlegap = -15 for i in 1:4]
axs3[4].xlabel = "time"
axs3[4].ylabel = "lon"
axs3[4].zlabel = "lat"
axs3[4].xlabeloffset = 0
axs3[4].ylabeloffset = 0
axs3[4].zlabeloffset = 0

axs3[3].title = "prediction"
axs3[2].title = "target"
axs3[1].title = "Ground truth"

hidedecorations!.(axs2, label = false)
[axs2[1,j].title = "$(Date(t[j]))" for j in 1:9]
[axs2[1,j].titlefont = "sans" for j in 1:9]  


[meshscatter!(axs2[1,k], positions; markersize = 1, color = 3*rgb[k], shading=  false) for k in 1:9]
[global hmap = heatmap!(axs2[2,k], 1:128, 1:128, target[:,:,k]; colormap, colorrange) for k in 1:9]
[heatmap!(axs2[3,k], 1:128, 1:128, prediction[:,:,k]; colormap, colorrange) for k in 1:9]
Colorbar(gh[2:3,end + 1], colormap = colormap, colorrange = (0,1), 
    height = Relative(0.85), label = "NDVI")

[heatmap!(axs2[4,k], 1:128, 1:128, abs.(target[:,:,k] .- prediction[:,:,k]); colormap = :Blues, colorrange = (0,0.2)) for k in 1:9]
Colorbar(gh[4,end], colormap = :Blues, colorrange = (0,0.2),
    height = Relative(0.75), label = "L1-norm")


colsize!(fig.layout, 1, Auto(0.125))
colgap!(gh, 4)
rowgap!(gh, 4)
colgap!(fig.layout, 4)
colgap!(gv, 0)
rowgap!(gv, 0)
figrgb = Any[]
for k in 1:len_time
    v = vec([RGBA(red[i, j, k], green[i, j, k], blue[i, j, k],1) for i = 1:len_lat, j = 1:len_lon])
    push!(rgb, v)
end
colormap = cgrad(:Spectral_11, rev=true)
colorrange=(0,1)


posi = [Point3f(i,j,k) for i in 1:128 for j in 1:128 for k in 1:len_time if !isnan(target[i,j,k])]
colorst = [target[i,j,k] for i in 1:128 for j in 1:128 for k in 1:len_time if !isnan(target[i,j,k])]
colorsp = [prediction[i,j,k] for i in 1:128 for j in 1:128 for k in 1:len_time if !isnan(target[i,j,k])]
error = abs.(colorst .- colorsp)


fig = Figure(resolution = (1500,600))
gv = fig[1,1] =  GridLayout()
gh = fig[1,2] =  GridLayout()
axs3 = [Axis3(gv[i,1]; perspectiveness = 0.5,
#azimuth = 2.19,
protrusions=0,
elevation = 0.57,
xlabel = " ",
ylabel = " ",
zlabel = " ", aspect = (1,1,1)) for i in 1:4]
axs2 = [Axis(gh[i,j], aspect = 1) for i in 1:4, j in 1:9]

meshscatter!(axs3[1], positionscube; marker = Rect3f(Vec3f(-0.5), Vec3f(1)),
    markersize = 1, color = 3*rgbcube, shading=false)
meshscatter!(axs3[2], posi; markersize = 1, colormap, colorrange, shading = false,
    marker = Rect3f(Vec3f(-0.5), Vec3f(1)), color = colorst)
meshscatter!(axs3[3], posi; markersize = 1, colormap, colorrange, shading = false,
    marker = Rect3f(Vec3f(-0.5), Vec3f(1)), color = colorsp)
meshscatter!(axs3[4], posi; markersize = 1, colormap = :Blues, colorrange=(0,0.2), 
    marker = Rect3f(Vec3f(-0.5), Vec3f(1)), shading = false, color = error)

hidedecorations!.(axs3, label = false)
axs3[4].title = "||targ - pred||"
[axs3[i].titlefont = "sans" for i in 1:4]
[axs3[i].titlesize = 18 for i in 1:4]
[axs3[i].titlegap = -15 for i in 1:4]
axs3[4].xlabel = "time"
axs3[4].ylabel = "lon"
axs3[4].zlabel = "lat"
axs3[4].xlabeloffset = 0
axs3[4].ylabeloffset = 0
axs3[4].zlabeloffset = 0

axs3[3].title = "prediction"
axs3[2].title = "target"
axs3[1].title = "Ground truth"

hidedecorations!.(axs2, label = false)
[axs2[1,j].title = "$(Date(t[j]))" for j in 1:9]
[axs2[1,j].titlefont = "sans" for j in 1:9]  


[meshscatter!(axs2[1,j], positions; markersize = 1, color = 3*rgb[j], shading=  false) for j in 1:9]
[global hmap = heatmap!(axs2[2,k], 1:128, 1:128, target[:,:,k]; colormap, colorrange) for k in 1:9]
[heatmap!(axs2[3,k], 1:128, 1:128, prediction[:,:,k]; colormap, colorrange) for k in 1:9]
Colorbar(gh[2:3,end + 1], colormap = colormap, colorrange = (0,1), 
height = Relative(0.85), label = "NDVI")

[heatmap!(axs2[4,k], 1:128, 1:128, abs.(target[:,:,k] .- prediction[:,:,k]); colormap = :Blues, colorrange = (0,0.2)) for k in 1:9]
Colorbar(gh[4,end], colormap = :Blues, colorrange = (0,0.2),
height = Relative(0.75), label = "L1-norm")


colsize!(fig.layout, 1, Auto(0.125))
colgap!(gh, 4)
rowgap!(gh, 4)
colgap!(fig.layout, 4)
colgap!(gv, 0)
rowgap!(gv, 0)
display(fig)
save("EarthNet2023/figures/time_serie_$(file).png", fig)
