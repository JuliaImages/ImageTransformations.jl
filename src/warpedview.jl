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
    warpedview(box_extrapolation(A, degree, fill), tform, args...)
end

function warpedview(
        A::AbstractArray,
        tform::Transformation,
        fill::FillType,
        args...)
    warpedview(A, tform, Linear(), fill, args...)
end
