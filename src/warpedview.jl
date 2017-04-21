_build_extrapolation(etp::AbstractExtrapolation) = etp

function _build_extrapolation{T}(itp::AbstractInterpolation{T}, fill::FillType = _default_fill(T))
    etp = extrapolate(itp, fill)
    _build_extrapolation(etp)
end

function _build_extrapolation{T,N,D<:Union{Linear,Constant}}(parent::AbstractArray{T,N}, degree::D = Linear(), args...)
    itp = Interpolations.BSplineInterpolation{T,N,typeof(parent),BSpline{D},OnGrid,0}(parent)
    _build_extrapolation(itp, args...)
end

immutable WarpedView{T,N,A<:AbstractArray,F1<:Transformation,I,F2<:Transformation,E<:AbstractExtrapolation} <: AbstractArray{T,N}
    parent::A
    transform::F1
    indices::I
    inverse::F2
    extrapolation::E

    function (::Type{WarpedView{T,N,TA,F,I}}){T,N,TA<:AbstractArray,F<:Transformation,I<:Tuple}(
            parent::TA,
            tform::F,
            indices::I)
        @assert eltype(parent) == T
        etp = _build_extrapolation(parent)
        tinv = inv(tform)
        new{T,N,TA,F,I,typeof(tinv),typeof(etp)}(parent, tform, indices, tinv, etp)
    end
end

function WarpedView(inner::WarpedView, outer_tform::Transformation)
    tform = compose(outer_tform, inner.transform)
    A = parent(inner)
    inds = autorange(A, tform)
    WarpedView(A, tform, inds)
end

function WarpedView{T,N,F<:Transformation,I<:Tuple}(
        A::AbstractArray{T,N},
        tform::F,
        inds::I = autorange(A, tform))
    WarpedView{T,N,typeof(A),F,I}(A, tform, inds)
end

Base.parent(A::WarpedView) = A.parent
@inline Base.indices(A::WarpedView) = A.indices

@compat Compat.IndexStyle{T<:WarpedView}(::Type{T}) = IndexCartesian()
@inline Base.getindex{T,N}(A::WarpedView{T,N}, I::Vararg{Int,N}) =
    _getindex(A.extrapolation, A.inverse(SVector(I)))

Base.size(A::WarpedView)    = OffsetArrays.errmsg(A)
Base.size(A::WarpedView, d) = OffsetArrays.errmsg(A)

function ShowItLikeYouBuildIt.showarg(io::IO, A::WarpedView)
    print(io, "WarpedView(")
    showarg(io, parent(A))
    print(io, ", ")
    print(io, A.transform)
    print(io, ')')
end

Base.summary(A::WarpedView) = summary_build(A)

"""
TODO
"""
@inline warpedview(A::AbstractArray, tform::Transformation, args...) =
    WarpedView(A, tform, args...)

function warpedview{T}(
        A::AbstractArray{T},
        tform::Transformation,
        degree::Union{Linear,Constant},
        fill::FillType = _default_fill(T),
        args...)
    warpedview(_build_extrapolation(A, degree, fill), tform, args...)
end

function warpedview(
        A::AbstractArray,
        tform::Transformation,
        fill::FillType,
        args...)
    warpedview(_build_extrapolation(A, Linear(), fill), tform, args...)
end
