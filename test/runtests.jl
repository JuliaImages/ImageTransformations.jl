using CoordinateTransformations, TestImages, ImageCore, Colors, FixedPointNumbers, OffsetArrays, Interpolations
using Base.Test

refambs = detect_ambiguities(CoordinateTransformations, Base, Core)
using ImageTransformations
ambs = detect_ambiguities(ImageTransformations, CoordinateTransformations, Base, Core)
@test isempty(setdiff(ambs, refambs))

tests = [
    "autorange.jl",
    "resizing.jl",
    "warp.jl",
]

for t in tests
    @testset "$t" begin
        include(t)
    end
end

nothing
