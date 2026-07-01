using OffsetArrays, Rotations, StaticArrays, CoordinateTransformations, LinearAlgebra
using ImageTransformations, ImageTransformationsCUDA, Interpolations
using CUDA
using Test

# helper function from ImageTransformations/test.jl to compare NaN
nearlysame(x, y) = x ≈ y || (isnan(x) & isnan(y))
nearlysame(A::AbstractArray, B::AbstractArray) = all(map(nearlysame, A, B))

tests = [
    "warpCUDA.jl",
]

@testset "ImageTransformations" begin
    for t in tests
        @testset "$t" begin
            include(t)
        end
    end
end

nothing