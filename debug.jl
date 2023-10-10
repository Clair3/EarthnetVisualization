
ds = Dataset(pred_file)
prediction = ds["ndvi_pred"][:, :, :]

t, latitude, longitude = ds["time"][:], ds["lat"][:], ds["lon"][:]

prediction, t, latitude, longitude = load_predcube(pred_file)

ds = Dataset(test_file)
context_length = 5  + 60 * 5
prediction_length = 29 * 5
context_length + prediction_length
ds = Dataset(test_file)
red = ds["s2_B04"][:, :,:]
ds["s2_B04"][:, :,5  + 60 * 5]
red = ds["s2_B04"][:, :,context_length:5:context_length+prediction_length] # h, w, t
green = ds["s2_B03"][:, :,context_length:5:context_length+prediction_length]
blue = ds["s2_B02"][:,:,context_length:5:context_length+prediction_length]
nir = ds["s2_B8A"][:,:,context_length:5:context_length+prediction_length]
ndvi = ((nir .- red) ./ (nir .+ red)) 
s2_mask = ds["s2_mask"][:,:,context_length:5:context_length+prediction_length]
landcover = ds["esawc_lc"][:,:]

red = ds["s2_B04"][:, :,context_length:5: context_length + prediction_length] # h, w, t
green = ds["s2_B03"][:, :, indices[1]:indices[end]]
blue = ds["s2_B02"][:,:,indices[1]:indices[end]]
nir = ds["s2_B8A"][:,:,indices[1]:indices[end]]
ndvi = ((nir .- red) ./ (nir .+ red)) 
s2_mask = ds["s2_mask"][:,:,context_length:5: context_length + prediction_length]
landcover = ds["esawc_lc"][:,:]
print(size(s2_mask))
prediction = mask_data(prediction, s2_mask, landcover)