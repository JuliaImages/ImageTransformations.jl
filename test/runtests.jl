using CoordinateTransformations, Rotations, TestImages, ImageCore, OffsetArrays, Interpolations, LinearAlgebra
using StaticArraysCore
using Test, ReferenceTests

refambs = detect_ambiguities(CoordinateTransformations, Base, Core)
using ImageTransformations
ambs = detect_ambiguities(ImageTransformations, CoordinateTransformations, Base, Core)
@test isempty(setdiff(ambs, refambs))

# helper function to compare NaN
nearlysame(x, y) = x ≈ y || (isnan(x) & isnan(y))
nearlysame(A::AbstractArray, B::AbstractArray) = all(map(nearlysame, A, B))

tests = [
    "autorange.jl",
    "resizing.jl",
    "interpolations.jl",
    "warp.jl",
    "deprecated.jl" # test deprecations in the last
]

@testset "ImageTransformations" begin
for t in tests
    @testset "$t" begin
        include(t)
    end
end

# put StaticArrays-related test at the end of the test to ensure the functionality works
# without `using StaticArrays`
using StaticArrays
include("staticarrays.jl")
end

nothing
