"""
    InvWarpedView(img, tinv, [indices]) -> wv

Create a view of `img` that lazily transforms any given index `I`
passed to `wv[I]` to correspond to `img[inv(tinv)(I)]`. While
technically this approach is known as backward mode warping, note
that `InvWarpedView` is created by supplying the forward
transformation

The conceptual difference to [`WarpedView`](@ref) is that
`InvWarpedView` is intended to be used when reasoning about the
image is more convenient that reasoning about the indices.
Furthermore, `InvWarpedView` allows simple nesting of
transformations, in which case the transformations will be
composed into a single one.

The optional parameter `indices` can be used to specify the
domain of the resulting `wv`. By default the indices are computed
in such a way that `wv` contains all the original pixels in
`img`.

see [`invwarpedview`](@ref) for more information.
"""
struct InvWarpedView{T,N,A,F,I,FI<:Transformation,E} <: AbstractArray{T,N}
    inner::WarpedView{T,N,A,F,I,E}
    inverse::FI
end

function InvWarpedView(inner::WarpedView{T,N,TA,F,I,E}) where {T,N,TA,F,I,E}
    tinv = _round(inv(inner.transform))
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
    invwarpedview(img, tinv, [indices], [degree = Linear()], [fill = NaN]) -> wv

Create a view of `img` that lazily transforms any given index `I`
passed to `wv[I]` to correspond to `img[inv(tinv)(I)]`. While
technically this approach is known as backward mode warping, note
that `InvWarpedView` is created by supplying the forward
transformation. The given transformation `tinv` must accept a
`SVector` as input and support `inv(tinv)`. A useful package to
create a wide variety of such transformations is
[CoordinateTransformations.jl](https://github.com/FugroRoames/CoordinateTransformations.jl).

When invoking `wv[I]`, values for `img` must be reconstructed at
arbitrary locations `inv(tinv)(I)`. `InvWarpedView` serves as a
wrapper around [`WarpedView`](@ref) which takes care of
interpolation and extrapolation. The parameters `degree` and
`fill` can be used to specify the b-spline degree and the
extrapolation scheme respectively.

The optional parameter `indices` can be used to specify the
domain of the resulting `wv`. By default the indices are computed
in such a way that `wv` contains all the original pixels in
`img`.
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
