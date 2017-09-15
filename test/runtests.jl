using CoordinateTransformations, TestImages, ImageCore, Colors, FixedPointNumbers, StaticArrays, OffsetArrays, Interpolations
using Base.Test, ReferenceTests

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

for t in tests
    @testset "$t" begin
        include(t)
    end
end

nothing
