"""
    WarpedView(img, tform, [indices]; kwargs...) -> wv

Create a view of `img` that lazily transforms any given index `I`
passed to `wv[I]` so that `wv[I] == img[tform(I)]`.

This is the lazy view version of `warp`, please see [`warp`](@ref
for more information.
"""
struct WarpedView{T,N,A<:AbstractArray,F<:Transformation,I<:Tuple,E<:AbstractExtrapolation} <: AbstractArray{T,N}
    parent::A
    transform::F
    indices::I
    extrapolation::E
end

function WarpedView(
        A::AbstractArray{T, N},
        tform::Transformation,
        inds=autorange(A, inv(tform)); kwargs...) where {T,N,}
    etp = box_extrapolation(A; kwargs...)
    WarpedView{T,N,typeof(A),typeof(tform),typeof(inds),typeof(etp)}(A, tform, inds, etp)
end

@inline Base.parent(A::WarpedView) = A.parent
@inline Base.axes(A::WarpedView) = A.indices
@inline Base.size(A::WarpedView) = map(length,axes(A))

Base.@propagate_inbounds function Base.getindex(A::WarpedView{T,N}, I::Vararg{Int,N}) where {T,N}
    convert(T, _getindex(A.extrapolation, A.transform(SVector(I))))
end

function Base.showarg(io::IO, A::WarpedView, toplevel)
    print(io, "WarpedView(")
    Base.showarg(io, parent(A), false)
    print(io, ", ")
    print(io, A.transform)
    if toplevel
        print(io, ") with eltype ", eltype(parent(A)))
    else
        print(io, ')')
    end
end
