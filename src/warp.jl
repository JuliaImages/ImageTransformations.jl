"""
    warp(img, tform, [fill]) -> imgw

Transform the coordinates of `img`, returning a new `imgw` satisfying
`imgw[x] = img[tform(x)]`. `tform` should be defined using
[CoordinateTransformations.jl](https://github.com/FugroRoames/CoordinateTransformations.jl).

# Interpolation scheme

At off-grid points, `imgw` is calculated by interpolation. The
default is linear interpolation, which is used when `img` is a
plain array and the `img[tform(x)]` is inbound. In the case
`tform(x)` maps to indices outside the original `img`, the value
/ extrapolation scheme denoted by the optional parameter `fill`
(which defaults to `NaN`) is used to indicate locations for which
`tform(x)` was outside the bounds of the input `img`.

For more control over the interpolation scheme --- and how
beyond-the-edge points are handled --- pass it in as an
`AbstractExtrapolation` from
[Interpolations.jl](https://github.com/JuliaMath/Interpolations.jl).

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
function warp{T,N}(img::AbstractArray{T,N}, args...)
    itp = Interpolations.BSplineInterpolation{T,N,typeof(img),Interpolations.BSpline{Interpolations.Linear},OnGrid,0}(img)
    warp(itp, args...)
end

# The default values used by extrapolation for off-domain points
@compat const FloatLike{T<:AbstractFloat} = Union{T,AbstractGray{T}}
@compat const FloatColorant{T<:AbstractFloat} = Colorant{T}
@inline _default_fill{T<:FloatLike}(::Type{T}) = convert(T, NaN)
@inline _default_fill{T<:FloatColorant}(::Type{T}) = nan(T)
@inline _default_fill{T}(::Type{T}) = zero(T)

function warp{T}(img::AbstractInterpolation{T}, tform, fill = _default_fill(T))
    warp(extrapolate(img, fill), tform)
end

function warp{T}(img::AbstractExtrapolation{T}, tform)
    inds = autorange(img, tform)
    out = OffsetArray(Array{T}(map(length, inds)), inds)
    warp!(out, img, tform)
end

function warp!(out, img::AbstractExtrapolation, tform)
    tinv = inv(tform)
    @inbounds for I in CartesianRange(indices(out))
        out[I] = _getindex(img, tinv(SVector(I.I)))
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
