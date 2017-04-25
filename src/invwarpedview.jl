immutable InvWarpedView{T,N,A<:AbstractArray,F1<:Transformation,I,F2<:Transformation,E<:AbstractExtrapolation} <: AbstractArray{T,N}
    parent::A
    transform::F1
    indices::I
    inverse::F2
    extrapolation::E

    function (::Type{InvWarpedView{T,N,TA,F,I}}){T,N,TA<:AbstractArray,F<:Transformation,I<:Tuple}(
            parent::TA,
            tform::F,
            indices::I)
        @assert eltype(parent) == T
        etp = box_extrapolation(parent)
        tinv = inv(tform)
        new{T,N,TA,F,I,typeof(tinv),typeof(etp)}(parent, tform, indices, tinv, etp)
    end
end

function InvWarpedView(inner::InvWarpedView, outer_tform::Transformation)
    tform = compose(outer_tform, inner.transform)
    A = parent(inner)
    inds = autorange(A, tform)
    InvWarpedView(A, tform, inds)
end

function InvWarpedView{T,N,F<:Transformation,I<:Tuple}(
        A::AbstractArray{T,N},
        tform::F,
        inds::I = autorange(A, tform))
    InvWarpedView{T,N,typeof(A),F,I}(A, tform, inds)
end

Base.parent(A::InvWarpedView) = A.parent
@inline Base.indices(A::InvWarpedView) = A.indices

@compat Compat.IndexStyle{T<:InvWarpedView}(::Type{T}) = IndexCartesian()
@inline Base.getindex{T,N}(A::InvWarpedView{T,N}, I::Vararg{Int,N}) =
    _getindex(A.extrapolation, A.inverse(SVector(I)))

Base.size(A::InvWarpedView)    = OffsetArrays.errmsg(A)
Base.size(A::InvWarpedView, d) = OffsetArrays.errmsg(A)

function ShowItLikeYouBuildIt.showarg(io::IO, A::InvWarpedView)
    print(io, "InvWarpedView(")
    showarg(io, parent(A))
    print(io, ", ")
    print(io, A.transform)
    print(io, ')')
end

Base.summary(A::InvWarpedView) = summary_build(A)

"""
TODO
"""
@inline invwarpedview(A::AbstractArray, tform::Transformation, args...) =
    InvWarpedView(A, tform, args...)

function invwarpedview{T}(
        A::AbstractArray{T},
        tform::Transformation,
        degree::Union{Linear,Constant},
        fill::FillType = _default_fill(T),
        args...)
    invwarpedview(box_extrapolation(A, degree, fill), tform, args...)
end

function invwarpedview(
        A::AbstractArray,
        tform::Transformation,
        fill::FillType,
        args...)
    invwarpedview(A, tform, Linear(), fill, args...)
end
