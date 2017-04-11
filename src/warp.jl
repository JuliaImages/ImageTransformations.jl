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

@compat const FloatLike{T<:AbstractFloat} = Union{T,AbstractGray{T}}
@compat const FloatColorant{T<:AbstractFloat} = Colorant{T}

# The default values used by extrapolation for off-domain points
@inline _default_fill{T<:FloatLike}(::Type{T}) = convert(T, NaN)
@inline _default_fill{T<:FloatColorant}(::Type{T}) = nan(T)
@inline _default_fill{T}(::Type{T}) = zero(T)

warp{T}(img::AbstractInterpolation{T}, tform, fill=_default_fill(T)) = warp(extrapolate(img, fill), tform)

"""
    warp(img, tform) -> imgw

Transform the coordinates of `img`, returning a new `imgw` satisfying
`imgw[x] = img[tform(x)]`. `tform` should be defined using
CoordinateTransformations.jl.

# Interpolation scheme

At off-grid points, `imgw` is calculated by interpolation. The default
is linear interpolation, used when `img` is a plain array, and `NaN`
values are used to indicate locations for which `tform(x)` was outside
the bounds of the input `img`. For more control over the interpolation
scheme---and how beyond-the-edge points are handled---pass it in as an
`AbstractExtrapolation` from Interpolations.jl.

# The meaning of the coordinates

The output array `imgw` has indices that would result from applying
`tform` to the indices of `img`. This can be very handy for keeping
track of how pixels in `imgw` line up with pixels in `img`.

If you just want a plain array, you can "strip" the custom indices
with `parent(imgw)`.

# Examples: a 2d rotation (see JuliaImages documentation for pictures)

```jldoctest
julia> using Images, CoordinateTransformations, TestImages, OffsetArrays

julia> img = testimage("lighthouse");

julia> indices(img)
(Base.OneTo(512),Base.OneTo(768))

# Rotate around the center of `img`
julia> tfm = recenter(RotMatrix(pi/4), center(img))
AffineMap([0.707107 -0.707107; 0.707107 0.707107], [347.01,-68.7554])

julia> imgw = warp(img, tfm);

julia> indices(imgw)
(-196:709,-68:837)

# Alternatively, specify the origin in the image itself
julia> img0 = OffsetArray(img, -30:481, -384:383);  # origin near top of image

julia> rot = LinearMap(RotMatrix(pi/4))
LinearMap([0.707107 -0.707107; 0.707107 0.707107])

julia> imgw = warp(img0, rot);

julia> indices(imgw)
(-293:612,-293:611)

julia> imgr = parent(imgw);

julia> indices(imgr)
(Base.OneTo(906),Base.OneTo(905))
```
"""
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

# This is type-piracy, but necessary if we want Interpolations to be
# independent of OffsetArrays.
function AxisAlgorithms.A_ldiv_B_md!(dest::OffsetArray, F, src::OffsetArray, dim::Integer, b::AbstractVector)
    indsdim = indices(parent(src), dim)
    indsF = indices(F)[2]
    if indsF == indsdim
        AxisAlgorithms.A_ldiv_B_md!(parent(dest), F, parent(src), dim, b)
        return dest
    end
    throw(DimensionMismatch("indices $(indices(parent(src))) do not match $(indices(F))"))
end
