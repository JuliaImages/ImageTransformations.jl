"""
    WarpedView(img, tform, [indices]) -> wv

Create a view of `img` that lazily transforms any given index `I`
passed to `wv[I]` to correspond to `img[tform(I)]`. This approach
is known as backward mode warping.

The optional parameter `indices` can be used to specify the
domain of the resulting `wv`. By default the indices are computed
in such a way that `wv` contains all the original pixels in
`img`. To do this `inv(tform)` has to be computed. If the given
transformation `tform` does not support `inv`, then the parameter
`indices` has to be specified manually.

see [`warpedview`](@ref) for more information.
"""
immutable WarpedView{T,N,A<:AbstractArray,F<:Transformation,I<:Tuple,E<:AbstractExtrapolation} <: AbstractArray{T,N}
    parent::A
    transform::F
    indices::I
    extrapolation::E

    function (::Type{WarpedView{T,N,TA,F,I}}){T,N,TA<:AbstractArray,F<:Transformation,I<:Tuple}(
            parent::TA,
            tform::F,
            indices::I)
        @assert eltype(parent) == T
        etp = box_extrapolation(parent)
        new{T,N,TA,F,I,typeof(etp)}(parent, tform, indices, etp)
    end
end

function WarpedView{T,N,F<:Transformation,I<:Tuple}(
        A::AbstractArray{T,N},
        tform::F,
        inds::I = autorange(A, inv(tform)))
    WarpedView{T,N,typeof(A),F,I}(A, tform, inds)
end

Base.parent(A::WarpedView) = A.parent
@inline Base.indices(A::WarpedView) = A.indices

@compat Compat.IndexStyle{T<:WarpedView}(::Type{T}) = IndexCartesian()
@inline Base.getindex{T,N}(A::WarpedView{T,N}, I::Vararg{Int,N}) =
    _getindex(A.extrapolation, A.transform(SVector(I)))

Base.size{T,N,TA,F}(A::WarpedView{T,N,TA,F})    = OffsetArrays.errmsg(A)
Base.size{T,N,TA,F}(A::WarpedView{T,N,TA,F}, d) = OffsetArrays.errmsg(A)

Base.size{T,N,TA,F}(A::WarpedView{T,N,TA,F,NTuple{N,Base.OneTo{Int}}})    = map(length, A.indices)
Base.size{T,N,TA,F}(A::WarpedView{T,N,TA,F,NTuple{N,Base.OneTo{Int}}}, d) = d <= N ? length(A.indices[d]) : 1

function ShowItLikeYouBuildIt.showarg(io::IO, A::WarpedView)
    print(io, "WarpedView(")
    showarg(io, parent(A))
    print(io, ", ")
    print(io, A.transform)
    print(io, ')')
end

Base.summary(A::WarpedView) = summary_build(A)

"""
    warpedview(img, tform, [indices], [degree = Linear()], [fill = NaN]) -> wv

Create a view of `img` that lazily transforms any given index `I`
passed to `wv[I]` to correspond to `img[tform(I)]`. This approach
is known as backward mode warping. The given transformation
`tform` must accept a `SVector` as input. A useful package to
create a wide variety of such transformations is
[CoordinateTransformations.jl](https://github.com/FugroRoames/CoordinateTransformations.jl).

When invoking `wv[I]`, values for `img` must be reconstructed at
arbitrary locations `tform(I)` which do not lie on to the lattice
of pixels. How this reconstruction is done depends on the type of
`img` and the optional parameter `degree`. When `img` is a plain
array, then on-grid b-spline interpolation will be used, where
the pixel of `img` will serve as the coeficients. It is possible
to configure what degree of b-spline to use with the parameter
`degree`. The two possible values are `degree = Linear()` for
linear interpolation, or `degree = Constant()` for nearest
neighbor interpolation.

In the case `tform(I)` maps to indices outside the domain of
`img`, those locations are set to a value `fill` (which defaults
to `NaN` if the element type supports it, and `0` otherwise).
Additionally, the parameter `fill` also accepts extrapolation
schemes, such as `Flat()`, `Periodic()` or `Reflect()`.

The optional parameter `indices` can be used to specify the
domain of the resulting `WarpedView`. By default the indices are
computed in such a way that the resulting `WarpedView` contains
all the original pixels in `img`. To do this `inv(tform)` has to
be computed. If the given transformation `tform` does not support
`inv`, then the parameter `indices` has to be specified manually.

`warpedview` is essentially a non-coping, lazy version of
[`warp`](@ref). As such, the two functions share the same
interface, with one important difference. `warpedview` will
insist that the resulting `WarpedView` will be a view of `img`
(i.e. `parent(warpedview(img, ...)) === img`). Consequently,
`warpedview` restricts the parameter `degree` to be either
`Linear()` or `Constant()`.
"""
@inline warpedview(A::AbstractArray, tform::Transformation, args...) =
    WarpedView(A, tform, args...)

function warpedview{T}(
        A::AbstractArray{T},
        tform::Transformation,
        degree::Union{Linear,Constant},
        fill::FillType = _default_fill(T))
    warpedview(box_extrapolation(A, degree, fill), tform)
end

function warpedview{T}(
        A::AbstractArray{T},
        tform::Transformation,
        indices::Tuple,
        degree::Union{Linear,Constant},
        fill::FillType = _default_fill(T))
    warpedview(box_extrapolation(A, degree, fill), tform, indices)
end

function warpedview(
        A::AbstractArray,
        tform::Transformation,
        fill::FillType)
    warpedview(A, tform, Linear(), fill)
end

function warpedview(
        A::AbstractArray,
        tform::Transformation,
        indices::Tuple,
        fill::FillType)
    warpedview(A, tform, indices, Linear(), fill)
end
