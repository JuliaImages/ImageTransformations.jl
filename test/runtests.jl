using ImageTransformations, CoordinateTransformations, TestImages, ImageCore, Colors, FixedPointNumbers
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
