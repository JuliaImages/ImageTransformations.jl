# None of these types are provided by this package, so the following line seems unclean
#     @inline Base.getindex(A::AbstractExtrapolation, v::StaticVector) = A[convert(Tuple, v)...]
# furthermore it would be ambiguous with getindex(::Extrapolation, xs...) after https://github.com/tlycken/Interpolations.jl/pull/141
@inline _getindex(A, v::StaticVector) = A[convert(Tuple, v)...]

warp(img::AbstractArray, args...) = warp(interpolate(img, BSpline(Linear()), OnGrid()), args...)

@inline _dst_type{T<:Colorant,S}(::Type{T}, ::Type{S}) = ccolor(T, S)
@inline _dst_type{T<:Number,S}(::Type{T}, ::Type{S}) = T

function warp{T,S}(::Type{T}, img::AbstractArray{S}, args...)
    TCol = _dst_type(T,S)
    TNorm = eltype(TCol)
    apad, pad = Interpolations.prefilter(TNorm, TCol, img, typeof(BSpline(Linear())), typeof(OnGrid()))
    itp = Interpolations.BSplineInterpolation(TNorm, apad, BSpline(Linear()), OnGrid(), pad)
    warp(itp, args...)
end

@compat const FloatLike{T<:AbstractFloat} = Union{T,Gray{T}} # Why not AbstractGray ?
@compat const FloatColorant{T<:AbstractFloat} = Colorant{T}

# The default values used by extrapolation for off-domain points
@inline _default_fill{T<:FloatLike}(::Type{T}) = convert(T, NaN)
@inline _default_fill{T<:FloatColorant}(::Type{T}) = nan(T)
@inline _default_fill{T}(::Type{T}) = zero(T)

warp{T}(img::AbstractInterpolation{T}, tform, fill=_default_fill(T)) = warp(extrapolate(img, fill), tform)

function warp(img::AbstractExtrapolation, tform)
    inds = autorange(img, tform)
    out = OffsetArray(Array{eltype(img)}(map(length, inds)), inds)
    warp!(out, img, tform)
end

function warp!(out, img::AbstractExtrapolation, tform)
    tinv = inv(tform)
    for I in CartesianRange(indices(out))
        out[I] = _getindex(img, tinv(SVector(I)))
    end
    out
end
