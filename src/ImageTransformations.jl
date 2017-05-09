__precompile__()
module ImageTransformations

using ShowItLikeYouBuildIt
using ImageCore
using CoordinateTransformations
using StaticArrays
using Interpolations, AxisAlgorithms
using OffsetArrays
using FixedPointNumbers
using Colors, ColorVectorSpace
using Compat
using IdentityRanges

import Base: start, next, done, eltype, iteratorsize, size, length
using Base: tail, Cartesian, Indices
using Colors.AbstractGray

export

    restrict,
    imresize,
    center,
    warp,
    WarpedView,
    warpedview,
    InvWarpedView,
    invwarpedview

include("autorange.jl")
include("resizing.jl")
include("interpolations.jl")
include("warp.jl")
include("warpedview.jl")
include("invwarpedview.jl")

@inline _getindex(A, v::StaticVector) = A[convert(Tuple, v)...]

center{T,N}(img::AbstractArray{T,N}) = SVector{N}(map(_center, indices(img)))
_center(ind::AbstractUnitRange) = (first(ind)+last(ind))/2

end # module
