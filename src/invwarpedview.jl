"""
    InvWarpedView(img, tinv, [indices]) -> wv

Create a view of `img` that lazily transforms any given index `I`
passed to `wv[I]` so that `wv[I] == img[inv(tinv)(I)]`.

The conceptual difference to [`WarpedView`](@ref) is that
`InvWarpedView` is intended to be used when reasoning about the
image is more convenient that reasoning about the indices.
Furthermore, `InvWarpedView` allows simple nesting of
transformations, in which case the transformations will be
composed into a single one.

See [`invwarpedview`](@ref) for a convenient constructor of `InvWarpedView`.

For detailed explaination of warp, associated arguments and parameters,
please refer to [`warp`](@ref).
"""
struct InvWarpedView{T,N,A,F,I,FI<:Transformation,E} <: AbstractArray{T,N}
    inner::WarpedView{T,N,A,F,I,E}
    inverse::FI
end

function InvWarpedView(inner::WarpedView{T,N,TA,F,I,E}) where {T,N,TA,F,I,E}
    tinv = inv(inner.transform)
    InvWarpedView{T,N,TA,F,I,typeof(tinv),E}(inner, tinv)
end

function InvWarpedView(A::AbstractArray, tinv::Transformation, inds::Tuple = autorange(A, tinv))
    InvWarpedView(WarpedView(A, inv(tinv), inds), tinv)
end

function InvWarpedView(inner::InvWarpedView, outer_tinv::Transformation)
    tinv = compose(outer_tinv, inner.inverse)
    InvWarpedView(parent(inner), tinv)
end

function InvWarpedView(inner::InvWarpedView, outer_tinv::Transformation, inds::Tuple)
    tinv = compose(outer_tinv, inner.inverse)
    InvWarpedView(parent(inner), tinv, inds)
end

Base.parent(A::InvWarpedView) = parent(A.inner)
@inline Base.axes(A::InvWarpedView) = axes(A.inner)

IndexStyle(::Type{T}) where {T<:InvWarpedView} = IndexCartesian()
@inline Base.getindex(A::InvWarpedView{T,N}, I::Vararg{Int,N}) where {T,N} = A.inner[I...]

Base.size(A::InvWarpedView)    = size(A.inner)
Base.size(A::InvWarpedView, d) = size(A.inner, d)

function Base.showarg(io::IO, A::InvWarpedView, toplevel)
    print(io, "InvWarpedView(")
    Base.showarg(io, parent(A), false)
    print(io, ", ")
    print(io, A.inverse)
    if toplevel
        print(io, ") with eltype ", eltype(parent(A)))
    else
        print(io, ')')
    end
end

"""
    invwarpedview(img, tinv, [indices]; kwargs...) -> wv

Create a view of `img` that lazily transforms any given index `I`
passed to `wv[I]` so that `wv[I] == img[inv(tinv)(I)]`.

Except for the lazy evaluation, the following two lines are equivalent:

```julia
warp(img, inv(tform), [indices]; kwargs...)
invwarpedview(img, tform, [indices]; kwargs...)
```

For detailed explaination of warp, associated arguments and parameters,
please refer to [`warp`](@ref).
"""
function invwarpedview(A::AbstractArray, tinv::Transformation, indices::Tuple=autorange(A, tinv); kwargs...)
    InvWarpedView(box_extrapolation(A; kwargs...), tinv, indices)
end

# For SubArray:
# 1. We can exceed the boundary of SubArray by using its parent and thus trick Interpolations in
#    order to get better extrapolation result around the border. Otherwise it will just fill it.
# 2. For default indices, we use `IdentityUnitRange`, which guarantees `r[i] == i`, to preserve the view indices.
function invwarpedview(A::SubArray, tinv::Transformation; kwargs...)
    default_indices = map(IdentityUnitRange, autorange(CartesianIndices(A.indices), tinv))
    invwarpedview(A, tinv, default_indices; kwargs...)
end
function invwarpedview(A::SubArray, tinv::Transformation, indices::Tuple; kwargs...)
    inner = parent(A)
    new_inner = InvWarpedView(inner, tinv, autorange(inner, tinv))
    view(new_inner, indices...)
end
