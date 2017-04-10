img_square = Gray{N0f8}.(reshape(linspace(0,1,9), (3,3)))
img_camera = testimage("camera")

tfm = recenter(RotMatrix(-pi/8), center(img_camera))
imgr = @inferred(warp(img_camera, tfm))
@test indices(imgr) == (-78:591, -78:591)

for T in (Float16,Float32,Float64,
          N0f8,Gray,Gray{Float16},RGB)
    imgr = @inferred(warp(T, img_camera, tfm))
    @test indices(imgr) == (-78:591, -78:591)
    @test eltype(imgr) <: T
end
#imgr2 = warp(imgr, inv(tfm   # this will need fixes in Interpolations
#@test imgr2[indices(img_camera)...] ≈ img

img_pyramid = Gray{Float64}[
    0.0 0.0 0.0 0.0 0.0;
    0.0 0.5 0.5 0.5 0.0;
    0.0 0.5 1.0 0.5 0.0;
    0.0 0.5 0.5 0.5 0.0;
    0.0 0.0 0.0 0.0 0.0;
]

ref = Float64[
    NaN   NaN   NaN   NaN   NaN   NaN   NaN;
    NaN   NaN   NaN  0.172  NaN   NaN   NaN;
    NaN   NaN  0.293 0.543 0.293  NaN   NaN;
    NaN  0.172 0.543 1.000 0.543 0.172  NaN;
    NaN   NaN  0.293 0.543 0.293  NaN   NaN;
    NaN   NaN   NaN  0.172  NaN   NaN   NaN;
    NaN   NaN   NaN   NaN   NaN   NaN   NaN;
]

tfm = recenter(RotMatrix(-pi/4), center(img_pyramid))
imgr = warp(img_pyramid, tfm)
@test indices(imgr) == (0:6, 0:6)

# I do this very complicated because turns out NaNs are hard to compare...
@test all(map(===, round.(Float64.(parent(imgr)),3), round.(ref,3)))
