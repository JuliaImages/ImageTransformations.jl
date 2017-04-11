__precompile__()
module ImageTransformations

using ImageCore
using CoordinateTransformations
using StaticArrays
using Interpolations, AxisAlgorithms
using OffsetArrays
using FixedPointNumbers
using Colors, ColorVectorSpace
using Compat

import Base: start, next, done, eltype, iteratorsize, size, length
using Base: tail, Cartesian

export

    restrict,
    imresize,
    warp,
    center

include("autorange.jl")
include("resizing.jl")
include("warp.jl")

center{T,N}(img::AbstractArray{T,N}) = SVector{N}(map(_center, indices(img)))
_center(ind::AbstractUnitRange) = (first(ind)+last(ind))/2

end # module
