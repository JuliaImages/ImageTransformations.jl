using CoordinateTransformations, TestImages, ImageCore, Colors, FixedPointNumbers, StaticArrays, OffsetArrays, Interpolations, LinearAlgebra
using Test, ReferenceTests

refambs = detect_ambiguities(CoordinateTransformations, Base, Core)
using ImageTransformations
ambs = detect_ambiguities(ImageTransformations, CoordinateTransformations, Base, Core)
@test isempty(setdiff(ambs, refambs))

tests = [
    "autorange.jl",
    "resizing.jl",
    "interpolations.jl",
    "warp.jl",
]

@testset "ImageTransformations" begin
for t in tests
    @testset "$t" begin
        include(t)
    end
end
end

nothing
