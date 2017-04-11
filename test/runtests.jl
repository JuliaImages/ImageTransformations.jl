using ImageTransformations, CoordinateTransformations, TestImages, ImageCore, Colors, FixedPointNumbers, OffsetArrays, Interpolations
using Base.Test

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
