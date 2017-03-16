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

function WarpedView(parent::AbstractArray, args...)
    WarpedView(interpolate(parent, BSpline(Linear()), OnGrid()), args...)
end

function WarpedView{T,F<:Transformation}(itp::AbstractInterpolation{T}, tform::F, fill=_default_fill(T))
    WarpedView(extrapolate(itp, fill), tform)
end

function WarpedView{T,N,F<:Transformation}(etp::AbstractExtrapolation{T,N}, tform::F)
    inds = autorange(etp, tform)
    tinv = inv(tform)
    WarpedView{T,N,typeof(etp),F,typeof(tinv),typeof(inds)}(etp, tform, tinv, inds)
end

Base.parent(A::WarpedView)  = A.parent
@inline Base.indices(A::WarpedView) = A.indices

@compat Compat.IndexStyle{T<:WarpedView}(::Type{T}) = IndexCartesian()
@inline Base.getindex{N}(A::WarpedView, I::Vararg{Int,N}) = _getindex(A.parent, A.transform_inv(SVector(I)))

Base.size(A::WarpedView)    = OffsetArrays.errmsg(A)
Base.size(A::WarpedView, d) = OffsetArrays.errmsg(A)
