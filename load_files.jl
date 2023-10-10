using CairoMakie
using Dates
using CompoundPeriods
using TimeSeries
using Printf
using Colors
using NCDatasets
using NPZ
using Pkg

min_lc = 40
max_lc = 90
context_length = 5  + 60 * 5
prediction_length = 29 * 5

function load_testcube(pathtofile::String)
    ds = Dataset(pathtofile)
    red = ds["s2_B04"][:, :,context_length:5:context_length+prediction_length] # h, w, t
    green = ds["s2_B03"][:, :,context_length:5:context_length+prediction_length]
    blue = ds["s2_B02"][:,:,context_length:5:context_length+prediction_length]
    nir = ds["s2_B8A"][:,:,context_length:5:context_length+prediction_length]
    ndvi = ((nir .- red) ./ (nir .+ red)) 
    s2_mask = ds["s2_mask"][:,:,context_length:5:context_length+prediction_length]
    landcover = ds["esawc_lc"][:,:]
    return (red, green, blue, ndvi, s2_mask, landcover)
end

function load_predcube(pathtofile::String)
    ds = Dataset(pathtofile)
    prediction = ds["ndvi_pred"][:, :, :]
    t, latitude, longitude = ds["time"][:], ds["lat"][:], ds["lon"][:]
    return prediction, t, latitude, longitude
end
    
function load_predcube_old(pathtofile::String)
    ds = npzread(pathtofile)
    prediction = ds["highresdynamic"][:, :, :,:]
    return prediction
end


function mask_data(data, s2_mask, landcover)
    # Dynamic mask
    #s2_mask = replace(mask, Missing => NaN)
    data = abs.(s2_mask .- 1) .* data

    # Landcover mask
    lc_mask = (landcover .>= min_lc) .& (landcover .<= max_lc) 
    lc_mask = replace(lc_mask, 0.0 => missing)

    for i in 1:size(data, 3)
        data[:, :, i] = lc_mask[i, :, :] .* data[:, :, i]
    end
    return data
end

function mask_data_prediction(data, s2_mask, landcover)
    # Dynamic mask
    #s2_mask = replace(mask, Missing => NaN)

    for i in 1:size(data, 3)
        data[:,:,i,:] = s2_mask .* data
    end
    # Landcover mask
    lc_mask = (landcover .>= min_lc) .& (landcover .<= max_lc) 
    lc_mask = replace(lc_mask, 0.0 => missing)

    for i in 1:size(data, 4)
        data[:, :, :, i] = lc_mask .* data[:, :, i]
    end
    return data
end


function list_files(pathtofile::String)
    pathtofiles = []
    ffiles = []
    for (root, dirs, files) in walkdir(pathtofile)
        for file in files
            push!(pathtofiles, joinpath(root, file))
            push!(ffiles, file)
        end
    end
    return pathtofiles, ffiles
end

function path_to_pred(file::String)
    return path_pred * file[1:5] * "/pred1_" * file # * ".npz"
end