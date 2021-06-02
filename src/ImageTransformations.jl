module ImageTransformations

using ImageCore
using CoordinateTransformations
using Rotations
using StaticArrays
using Interpolations, AxisAlgorithms
using OffsetArrays
using ColorVectorSpace

import Base: eltype, size, length
using Base: tail, Indices
using Base.Cartesian
using .ColorTypes: AbstractGray, TransparentGray, TransparentRGB

# these two symbols previously live in ImageTransformations
import ImageBase: restrict, restrict!

export

    restrict,
    imresize,
    center,
    warp,
    WarpedView,
    warpedview,
    InvWarpedView,
    invwarpedview,
    imrotate

include("autorange.jl")
include("interpolations.jl")
include("warp.jl")
include("warpedview.jl")
include("invwarpedview.jl")
include("resizing.jl")
include("compat.jl")
include("deprecated.jl")

# TODO: move to warp.jl
@inline _getindex(A, v::StaticVector) = A[Tuple(v)...]
@inline _getindex(A::AbstractInterpolation, v::StaticVector) = A(Tuple(v)...)
@inline _getindex(A, v) = A[v...]
@inline _getindex(A::AbstractInterpolation, v) = A(v...)

center(img::AbstractArray{T,N}) where {T,N} = SVector{N}(map(_center, axes(img)))
_center(ind::AbstractUnitRange) = (first(ind)+last(ind))/2

end # module
