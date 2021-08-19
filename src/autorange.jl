"""
    autorange(A::AbstractArray, tform::Transformation)

For given transformation `tform`, return the "smallest" range indices that
preserves all information from `A` after applying `tform`.

# Examples

For transformation that preserves the array size, `autorange` is equivalent to `axes(A)`.

```jldoctest; setup=:(using ImageTransformations: autorange; using CoordinateTransformations, Rotations, ImageTransformations)
A = rand(5, 5)
tform = IdentityTransformation()
autorange(A, tform) == axes(A)

# output
true
```

The diffrence shows up when `tform` enlarges the input array `A`. In the following example, we need
at least `(0:6, 0:6)` as the range indices to get all data of `A`:

```jldoctest; setup=:(using ImageTransformations: autorange; using CoordinateTransformations, Rotations, ImageTransformations)
A = rand(5, 5)
tform = recenter(RotMatrix(pi/8), center(A))
autorange(A, tform)

# output
(0:6, 0:6)
```

!!! note
    This function is not exported; it is mainly for internal usage to infer the default indices.
"""
autorange(A::AbstractArray, tform) = autorange(CartesianIndices(A), tform)
function autorange(R::CartesianIndices, tform)
    mn = mx = tform(SVector(first(R).I))
    for I in CornerIterator(R)
        x = tform(SVector(I.I))
        # we map min and max to prevent type-inference issues
        # (because min(::SVector,::SVector) -> Vector)
        mn = map(min, x, mn)
        mx = map(max, x, mx)
    end
    _autorange(Tuple(mn), Tuple(mx))
end

@noinline _autorange(mn,mx) = map((a,b)->floor(Int,_round(a)):ceil(Int,_round(b)), mn, mx)

## Iterate over the corner-indices of a rectangular region
struct CornerIterator{I<:CartesianIndex}
    start::I
    stop::I
end
CornerIterator(R::CartesianIndices) = CornerIterator(first(R), last(R))

Base.eltype(::Type{CornerIterator{I}}) where {I} = I
Base.Iterators.IteratorSize(::Type{CornerIterator{I}}) where {I<:CartesianIndex{N}} where {N} = Base.Iterators.HasShape{N}()

# in 0.6 we could write: 1 .+ (iter.stop.I .- iter.start.I .!= 0)
Base.size(iter::CornerIterator{CartesianIndex{N}}) where {N} = ntuple(d->iter.stop.I[d]-iter.start.I[d]==0 ? 1 : 2, Val(N))::NTuple{N,Int}
Base.length(iter::CornerIterator) = prod(size(iter))

@inline function Base.iterate(iter::CornerIterator{<:CartesianIndex})
    if any(map(>, iter.start.I, iter.stop.I))
        return nothing
    end
    iterate(iter, iter.start)
end

@inline function Base.iterate(iter::CornerIterator{I}, state) where I<:CartesianIndex
    if state.I[end] > iter.stop.I[end]
        return nothing
    end
    state, I(inc(state.I, iter.start.I, iter.stop.I))
end

# increment & carry
@inline inc(::Tuple{}, ::Tuple{}, ::Tuple{}) = ()
# the max(1, ...) makes sure that the code doesn't break
# for corner cases where if stop == start
# (e.g. CornerIterator(CartesianRange((1,1))))
@inline inc(state::Tuple{Int}, start::Tuple{Int}, stop::Tuple{Int}) = (state[1]+(max(1,stop[1]-start[1])),)
@inline function inc(state, start, stop)
    if state[1] < stop[1]
        return (stop[1],tail(state)...)
    end
    newtail = inc(tail(state), tail(start), tail(stop))
    (start[1], newtail...)
end

# 0-d is special-cased to iterate once and only once
Base.iterate(iter::CornerIterator{<:CartesianIndex{0}}) = (iter.start, nothing)
Base.iterate(iter::CornerIterator{<:CartesianIndex{0}}, state) = nothing

# Ensure that we use StaticArrays for linear transformations
try_static(tfm, img) = tfm   # fallback
try_static(tfm::AffineMap{<:SMatrix, <:SVector}, img::AbstractArray{T,N}) where {T,N} = tfm
try_static(tfm::AffineMap{<:AbstractMatrix, <:AbstractVector}, img::AbstractArray{T,N}) where {T,N} =
    AffineMap(SMatrix{N,N}(tfm.linear), SVector{N}(tfm.translation))
try_static(tfm::LinearMap{<:SMatrix}, img::AbstractArray{T,N}) where {T,N} = tfm
try_static(tfm::LinearMap{<:AbstractMatrix}, img::AbstractArray{T,N}) where {T,N} =
    LinearMap(SMatrix{N,N}(tfm.linear))
try_static(tfm::Translation{<:SVector}, img::AbstractArray{T,N}) where {T,N} = tfm
try_static(tfm::Translation{<:AbstractVector}, img::AbstractArray{T,N}) where {T,N} =
    Translation(SVector{N}(tfm.translation))

# Slightly round/discretize the output coordinates so that the warped image size isn't affected by
# numerical stability
# https://github.com/JuliaImages/ImageTransformations.jl/issues/104
_default_digits(::Type{T}) where T<:Number = _default_digits(floattype(T))
# these constants come from eps() digits
_default_digits(::Type{T}) where T<:AbstractFloat = ceil(Int, -log10(sqrt(eps(T))))
_default_digits(::Type{Float64}) = 8
_default_digits(::Type{Float32}) = 4

_round(x::T; digits=_default_digits(T), kwargs...) where T<:Number = round(x; digits=digits, kwargs...)
