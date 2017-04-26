"""
    warp(img, tform, [indices], [degree = Linear()], [fill = NaN]) -> imgw

Transform the coordinates of `img`, returning a new `imgw` satisfying
`imgw[I] = img[tform(I)]`. This approach is known as backward
mode warping. The transformation `tform` should be defined using
[CoordinateTransformations.jl](https://github.com/FugroRoames/CoordinateTransformations.jl).

# Interpolation scheme

At off-grid points, `imgw` is calculated by interpolation. The
degree of the b-spline can be specified with the optional
parameter `degree`, which can take the values `Linear()` or
`Constant()`.

The b-spline interpolation is used when `img` is a plain array
and `img[tform(I)]` is inbound. In the case `tform(I)` maps
to indices outside the original `img`, the value or extrapolation
scheme denoted by the optional parameter `fill` (which defaults
to `NaN` if the element type supports it, and `0` otherwise) is
used to indicate locations for which `tform(I)` was outside the
bounds of the input `img`.

For more control over the interpolation scheme --- and how
beyond-the-edge points are handled --- pass it in as an
`AbstractInterpolation` or `AbstractExtrapolation` from
[Interpolations.jl](https://github.com/JuliaMath/Interpolations.jl).

# The meaning of the coordinates

The output array `imgw` has indices that would result from applying
`inv(tform)` to the indices of `img`. This can be very handy for keeping
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

julia> imgw = warp(img, inv(tfm));

julia> indices(imgw)
(-196:709,-68:837)

# Alternatively, specify the origin in the image itself
julia> img0 = OffsetArray(img, -30:481, -384:383);  # origin near top of image

julia> rot = LinearMap(RotMatrix(pi/4))
LinearMap([0.707107 -0.707107; 0.707107 0.707107])

julia> imgw = warp(img0, inv(rot));

julia> indices(imgw)
(-293:612,-293:611)

julia> imgr = parent(imgw);

julia> indices(imgr)
(Base.OneTo(906),Base.OneTo(905))
```
"""
function warp_new{T}(img::AbstractExtrapolation{T}, tform, inds::Tuple = autorange(img, inv(tform)))
    out = OffsetArray(Array{T}(map(length, inds)), inds)
    warp!(out, img, tform)
end

# this function was never exported, so no need to deprecate
function warp!(out, img::AbstractExtrapolation, tform)
    @inbounds for I in CartesianRange(indices(out))
        out[I] = _getindex(img, tform(SVector(I.I)))
    end
    out
end

function warp_new(img::AbstractArray, tform, inds::Tuple, args...)
    etp = box_extrapolation(img, args...)
    warp_new(etp, tform, inds)
end

function warp_new(img::AbstractArray, tform, args...)
    etp = box_extrapolation(img, args...)
    warp_new(etp, tform)
end

# # after deprecation period:
# @deprecate warp_new(img::AbstractArray, tform, args...) warp(img, tform, args...)
# @deprecate warp_old(img::AbstractArray, tform, args...) warp(img, tform, args...)

"""
    warp(img, tform, [indices], [degree = Linear()], [fill = NaN]) -> imgw

!!! warning "Deprecation Warning!"

    This method with the signature `warp(img, tform, args...)` is
    deprecated in favour of the cleaner interpretation `warp(img,
    inv(tform), args...)`. Set `const warp =
    ImageTransformations.warp_new` right after package import to
    change to the new behaviour right away.

Transform the coordinates of `img`, returning a new `imgw`
satisfying `imgw[I] = img[inv(tform(I))]`. This approach is known
as backward mode warping. The transformation `tform` should be
defined using
[CoordinateTransformations.jl](https://github.com/FugroRoames/CoordinateTransformations.jl).

# Interpolation scheme

At off-grid points, `imgw` is calculated by interpolation. The
degree of the b-spline can be specified with the optional
parameter `degree`, which can take the values `Linear()` or
`Constant()`.

The b-spline interpolation is used when `img` is a plain array
and `img[inv(tform(I))]` is inbound. In the case `inv(tform(I))`
maps to indices outside the original `img`, the value or
extrapolation scheme denoted by the optional parameter `fill`
(which defaults to `NaN` if the element type supports it, and `0`
otherwise) is used to indicate locations for which
`inv(tform(I))` was outside the bounds of the input `img`.

For more control over the interpolation scheme --- and how
beyond-the-edge points are handled --- pass it in as an
`AbstractInterpolation` or `AbstractExtrapolation` from
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
@generated function warp_old(img::AbstractArray, tform, args...)
    warn("'warp(img, tform)' is deprecated in favour of the cleaner interpretation 'warp(img, inv(tform))'. Set 'const warp = ImageTransformations.warp_new' right after package import to change to the new behaviour right away.")
    :(warp_new(img, inv(tform), args...))
end
const warp = warp_old
