"""
    InvWarpedView(img, tinv, [indices]; kwargs...) -> wv
    InvWarpedView(inner_view, tinv) -> wv

Create a view of `img` that lazily transforms any given index `I`
passed to `wv[I]` so that `wv[I] == img[inv(tinv)(I)]`.

Except for the lazy evaluation, the following two lines are expected to be equivalent:

```julia
warp(img, inv(tform), [indices]; kwargs...)
invwarpedview(img, tform, [indices]; kwargs...)
```

The conceptual difference to [`WarpedView`](@ref) is that
`InvWarpedView` is intended to be used when reasoning about the
image is more convenient that reasoning about the indices.
Furthermore, `InvWarpedView` allows simple nesting of
transformations, in which case the transformations will be
composed into a single one.

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

function InvWarpedView(A::AbstractArray, tinv::Transformation, inds::Tuple = autorange(A, tinv); kwargs...)
    inner = WarpedView(A, inv(tinv), inds; kwargs...)
    InvWarpedView(inner, tinv)
end

function InvWarpedView(inner::InvWarpedView, outer_tinv::Transformation)
    tinv = compose(outer_tinv, inner.inverse)
    InvWarpedView(parent(inner), tinv)
end

function InvWarpedView(inner::InvWarpedView, outer_tinv::Transformation, inds::Tuple)
    tinv = compose(outer_tinv, inner.inverse)
    InvWarpedView(parent(inner), tinv, inds)
end

@inline Base.parent(A::InvWarpedView) = parent(A.inner)
@inline Base.axes(A::InvWarpedView) = axes(A.inner)
@inline Base.size(A::InvWarpedView) = size(A.inner)

Base.@propagate_inbounds Base.getindex(A::InvWarpedView{T,N}, I::Vararg{Int,N}) where {T,N} = A.inner[I...]

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
