immutable InvWarpedView{T,N,A,F,I,FI<:Transformation,E} <: AbstractArray{T,N}
    inner::WarpedView{T,N,A,F,I,E}
    inverse::FI
end

function InvWarpedView{T,N,TA,F,I,E}(inner::WarpedView{T,N,TA,F,I,E})
    tinv = inv(inner.transform)
    InvWarpedView{T,N,TA,F,I,typeof(inv),E}(inner, tinv)
end

function InvWarpedView(A::AbstractArray, tinv::Transformation, inds::Tuple = autorange(A, tinv))
    InvWarpedView(WarpedView(A, inv(tinv), inds), tinv)
end

function InvWarpedView(inner::InvWarpedView, outer_tinv::Transformation)
    tinv = compose(outer_tinv, inner.inverse)
    InvWarpedView(parent(inner), tinv)
end

Base.parent(A::InvWarpedView) = parent(A.inner)
@inline Base.indices(A::InvWarpedView) = indices(A.inner)

@compat Compat.IndexStyle{T<:InvWarpedView}(::Type{T}) = IndexCartesian()
@inline Base.getindex{T,N}(A::InvWarpedView{T,N}, I::Vararg{Int,N}) = A.inner[I...]

Base.size(A::InvWarpedView)    = OffsetArrays.errmsg(A)
Base.size(A::InvWarpedView, d) = OffsetArrays.errmsg(A)

function ShowItLikeYouBuildIt.showarg(io::IO, A::InvWarpedView)
    print(io, "InvWarpedView(")
    showarg(io, parent(A))
    print(io, ", ")
    print(io, A.inverse)
    print(io, ')')
end

Base.summary(A::InvWarpedView) = summary_build(A)

"""
TODO
"""
@inline invwarpedview(A::AbstractArray, tinv::Transformation, args...) =
    InvWarpedView(A, tinv, args...)

function invwarpedview{T}(
        A::AbstractArray{T},
        tinv::Transformation,
        degree::Union{Linear,Constant},
        fill::FillType = _default_fill(T),
        args...)
    invwarpedview(box_extrapolation(A, degree, fill), tinv, args...)
end

function invwarpedview(
        A::AbstractArray,
        tinv::Transformation,
        fill::FillType,
        args...)
    invwarpedview(A, tinv, Linear(), fill, args...)
end
