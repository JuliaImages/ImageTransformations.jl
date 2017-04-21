immutable WarpedView{T,N,A<:AbstractArray,F1<:Transformation,F2<:Transformation,I} <: AbstractArray{T,N}
    parent::A
    transform::F1
    transform_inv::F2
    indices::I

    function (::Type{WarpedView{T,N,A,F1,F2,I}}){T,N,A<:AbstractArray,F1<:Transformation,F2<:Transformation,I}(
            parent::A, tform::F1, tinv::F2, indices::I)
        @assert eltype(parent) == T
        new{T,N,A,F1,F2,I}(parent, tform, tinv, indices)
    end
end

function WarpedView{T,N,F<:Transformation}(inner::WarpedView{T,N}, outer_tform::F)
    tform = compose(outer_tform, inner.transform)
    tinv = inv(tform)
    etp = parent(inner)
    inds = autorange(etp, tform)
    WarpedView{T,N,typeof(etp),typeof(tform),typeof(tinv),typeof(inds)}(etp, tform, tinv, inds)
end

function WarpedView{T,N}(parent::AbstractArray{T,N}, args...)
    itp = Interpolations.BSplineInterpolation{T,N,typeof(parent),Interpolations.BSpline{Interpolations.Linear},OnGrid,0}(parent)
    WarpedView(itp, args...)
end

function WarpedView{T,F<:Transformation}(itp::AbstractInterpolation{T}, tform::F, fill=_default_fill(T))
    WarpedView(extrapolate(itp, fill), tform)
end

function WarpedView{T,N,F<:Transformation}(etp::AbstractExtrapolation{T,N}, tform::F)
    inds = autorange(etp, tform)
    tinv = inv(tform)
    WarpedView{T,N,typeof(etp),F,typeof(tinv),typeof(inds)}(etp, tform, tinv, inds)
end

Base.parent(A::WarpedView) = A.parent
@inline Base.indices(A::WarpedView) = A.indices

@compat Compat.IndexStyle{T<:WarpedView}(::Type{T}) = IndexCartesian()
@inline Base.getindex{T,N}(A::WarpedView{T,N}, I::Vararg{Int,N}) =
    _getindex(A.parent, A.transform_inv(SVector(I)))

Base.size(A::WarpedView)    = OffsetArrays.errmsg(A)
Base.size(A::WarpedView, d) = OffsetArrays.errmsg(A)

# This will return the next non-standard parent
# This way only those extrapolations/interpolations are displayed
# that are different to the default settings
_next_custom(A) = A
_next_custom(A::Interpolations.FilledExtrapolation) = _next_custom(A.itp)
_next_custom{T,N,TI,IT<:BSpline{Linear},GT<:OnGrid}(A::Interpolations.BSplineInterpolation{T,N,TI,IT,GT}) = _next_custom(A.coefs)

function ShowItLikeYouBuildIt.showarg(io::IO, A::WarpedView)
    print(io, "WarpedView(")
    showarg(io, _next_custom(parent(A)))
    print(io, ", ")
    print(io, A.transform)
    print(io, ')')
end

Base.summary(A::WarpedView) = summary_build(A)
