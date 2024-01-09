using CoordinateTransformations, Rotations, TestImages, ImageCore, StaticArrays, OffsetArrays, Interpolations, LinearAlgebra
using Test, ReferenceTests

refambs = detect_ambiguities(CoordinateTransformations, Base, Core)
using ImageTransformations
ambs = detect_ambiguities(ImageTransformations, CoordinateTransformations, Base, Core)
@test isempty(setdiff(ambs, refambs))

# helper function to compare NaN
nearlysame(x, y, atol = 0.0) = isapprox(x, y; atol = atol) || (isnan(x) & isnan(y))
nearlysame(A::AbstractArray, B::AbstractArray; atol = 0.0) = all(map((a, b, atol)-> nearlysame(a, b, atol), A, B, atol))

tests = [
    "autorange.jl",
    "resizing.jl",
    "interpolations.jl",
    "warp.jl",
    "swirl.jl",
    "deprecated.jl" # test deprecations in the last
]

@testset "ImageTransformations" begin
for t in tests
    @testset "$t" begin
        include(t)
    end
end
end

nothing
