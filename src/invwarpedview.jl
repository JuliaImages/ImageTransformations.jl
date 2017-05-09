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
immutable InvWarpedView{T,N,A,F,I,FI<:Transformation,E} <: AbstractArray{T,N}
    inner::WarpedView{T,N,A,F,I,E}
    inverse::FI
end

function InvWarpedView{T,N,TA,F,I,E}(inner::WarpedView{T,N,TA,F,I,E})
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
@inline Base.indices(A::InvWarpedView) = indices(A.inner)

@compat Compat.IndexStyle{T<:InvWarpedView}(::Type{T}) = IndexCartesian()
@inline Base.getindex{T,N}(A::InvWarpedView{T,N}, I::Vararg{Int,N}) = A.inner[I...]

Base.size(A::InvWarpedView)    = size(A.inner)
Base.size(A::InvWarpedView, d) = size(A.inner, d)

function ShowItLikeYouBuildIt.showarg(io::IO, A::InvWarpedView)
    print(io, "InvWarpedView(")
    showarg(io, parent(A))
    print(io, ", ")
    print(io, A.inverse)
    print(io, ')')
end

# showargs for SubArray{<:Colorant} is already implemented by ImageCore
function ShowItLikeYouBuildIt.showarg{T<:Number,N,W<:InvWarpedView}(io::IO, A::SubArray{T,N,W})
    print(io, "view(")
    showarg(io, parent(A))
    print(io, ", ")
    for (i, el) in enumerate(A.indexes)
        print(io, el)
        i < length(A.indexes) && print(io, ", ")
    end
    print(io, ')')
end

Base.summary(A::InvWarpedView) = summary_build(A)
Base.summary{T<:Number,N,W<:InvWarpedView}(A::SubArray{T,N,W}) = summary_build(A)

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
@inline invwarpedview(A::AbstractArray, tinv::Transformation, args...) =
    InvWarpedView(A, tinv, args...)

function invwarpedview{T}(
        A::AbstractArray{T},
        tinv::Transformation,
        degree::Union{Linear,Constant},
        fill::FillType = _default_fill(T))
    invwarpedview(box_extrapolation(A, degree, fill), tinv)
end

function invwarpedview{T}(
        A::AbstractArray{T},
        tinv::Transformation,
        indices::Tuple,
        degree::Union{Linear,Constant},
        fill::FillType = _default_fill(T))
    invwarpedview(box_extrapolation(A, degree, fill), tinv, indices)
end

function invwarpedview(
        A::AbstractArray,
        tinv::Transformation,
        fill::FillType)
    invwarpedview(A, tinv, Linear(), fill)
end

function invwarpedview(
        A::AbstractArray,
        tinv::Transformation,
        indices::Tuple,
        fill::FillType)
    invwarpedview(A, tinv, indices, Linear(), fill)
end

function invwarpedview{T,N,W<:InvWarpedView,I<:Tuple{Vararg{AbstractUnitRange}}}(
        inner_view::SubArray{T,N,W,I},
        tinv::Transformation)
    inner = parent(inner_view)
    new_inner = InvWarpedView(inner, tinv, autorange(inner, tinv))
    inds = autorange(CartesianRange(inner_view.indexes), tinv)
    view(new_inner, map(IdentityRange, inds)...)
end

function invwarpedview{T,N,W<:InvWarpedView,I<:Tuple{Vararg{AbstractUnitRange}}}(
        inner_view::SubArray{T,N,W,I},
        tinv::Transformation,
        indices::Tuple)
    inner = parent(inner_view)
    new_inner = InvWarpedView(inner, tinv, autorange(inner, tinv))
    view(new_inner, indices...)
end
