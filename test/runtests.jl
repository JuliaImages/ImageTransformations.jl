using ImageTransformations, CoordinateTransformations, TestImages, ImageCore, Colors, FixedPointNumbers
using Base.Test

img_pyramid = Gray{Float64}[
    0.0 0.0 0.0 0.0 0.0;
    0.0 0.5 0.5 0.5 0.0;
    0.0 0.5 1.0 0.5 0.0;
    0.0 0.5 0.5 0.5 0.0;
    0.0 0.0 0.0 0.0 0.0;
]

img_square = Gray{N0f8}.(reshape(linspace(0,1,9), (3,3)))
img_camera = testimage("camera")

tfm = recenter(RotMatrix(-pi/8), center(img_camera))
imgr = warp(Gray, img_camera, tfm)
@test eltype(imgr) == eltype(img_camera)
@test indices(imgr) == (-78:591, -78:591)
#imgr2 = warp(imgr, inv(tfm))   # this will need fixes in Interpolations
#@test imgr2[indices(img)...] ≈ img

tests = [
    "autorange.jl",
    "resizing.jl",
]

for t in tests
    @testset "$t" begin
        include(t)
    end
end

nothing
