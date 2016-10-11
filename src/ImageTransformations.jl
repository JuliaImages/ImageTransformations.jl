module ImageTransformations

using CoordinateTransformations, Interpolations, OffsetArrays, StaticArrays, Colors, ColorVectorSpace

import Base: start, next, done, eltype, iteratorsize
using Base: tail

export warp, center

typealias FloatLike{T<:AbstractFloat} Union{T,Gray{T}}
typealias FloatColorant{T<:AbstractFloat} Colorant{T}

@inline Base.getindex(A::AbstractExtrapolation, v::SVector) = A[convert(Tuple, v)...]

function warp(img::AbstractExtrapolation, tform)
    inds = autorange(img, tform)
    out = OffsetArray(Array{eltype(img)}(map(length, inds)), inds)
    warp!(out, img, tform)
end
warp(img::AbstractArray, tform) = warp(interpolate(img, BSpline(Linear()), OnGrid()), tform)
warp{T<:FloatLike}(img::AbstractInterpolation{T}, tform) = warp(extrapolate(img, convert(T, NaN)), tform)
warp{T<:FloatColorant}(img::AbstractInterpolation{T}, tform) = warp(extrapolate(img, nan(T)), tform)
warp{T}(img::AbstractInterpolation{T}, tform) = warp(extrapolate(img, zero(T)), tform)

function warp!(out, img::AbstractExtrapolation, tform)
    tinv = inv(tform)
    for I in CartesianRange(indices(out))
        out[I] = img[tinv(SVector(I))]
    end
    out
end

function autorange(img, tform)
    R = CartesianRange(indices(img))
    I = first(R)
    x = tform(SVector(I))
    mn = mx = x
    for I in CornerIterator(R)
        x = tform(SVector(I))
        mn, mx = min(x, mn), max(x, mx)
    end
    _autorange(convert(Tuple, mn), convert(Tuple, mx))
end

@noinline _autorange(mn,mx) = map((a,b)->floor(Int,a):ceil(Int,b), mn, mx)


## Iterate over the corner-indices of a rectangular region
immutable CornerIterator{I<:CartesianIndex}
    start::I
    stop::I
end
CornerIterator{I<:CartesianIndex}(R::CartesianRange{I}) = CornerIterator{I}(R.start, R.stop)

eltype{I}(::Type{CornerIterator{I}}) = I
iteratorsize{I}(::Type{CornerIterator{I}}) = Base.HasShape()

@inline function start{I<:CartesianIndex}(iter::CornerIterator{I})
    if any(map(>, iter.start.I, iter.stop.I))
        return iter.stop+1
    end
    iter.start
end
@inline function next{I<:CartesianIndex}(iter::CornerIterator{I}, state)
    state, I(inc(state.I, iter.start.I, iter.stop.I))
end
# increment & carry
@inline inc(::Tuple{}, ::Tuple{}, ::Tuple{}) = ()
@inline inc(state::Tuple{Int}, start::Tuple{Int}, stop::Tuple{Int}) = (state[1]+(stop[1]-start[1]),)
@inline function inc(state, start, stop)
    if state[1] < stop[1]
        return (stop[1],tail(state)...)
    end
    newtail = inc(tail(state), tail(start), tail(stop))
    (start[1], newtail...)
end
@inline done{I<:CartesianIndex}(iter::CornerIterator{I}, state) = state.I[end] > iter.stop.I[end]

# 0-d is special-cased to iterate once and only once
start{I<:CartesianIndex{0}}(iter::CornerIterator{I}) = false
next{I<:CartesianIndex{0}}(iter::CornerIterator{I}, state) = iter.start, true
done{I<:CartesianIndex{0}}(iter::CornerIterator{I}, state) = state

center{T,N}(img::AbstractArray{T,N}) = SVector{N}(map(_center, indices(img)))
_center(ind::AbstractUnitRange) = (first(ind)+last(ind))/2

end # module
