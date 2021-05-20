"""
    warp(img, tform, [indices]; kwargs...) -> imgw

Transform the coordinates of `img`, returning a new `imgw`
satisfying `imgw[I] = img[tform(I)]`. This approach is known as
backward mode warping. The transformation `tform` must accept a
`SVector` as input. A useful package to create a wide variety of
such transformations is
[CoordinateTransformations.jl](https://github.com/FugroRoames/CoordinateTransformations.jl).

# Parameters

- `method::Union{Degree, InterpolationType}`: the interpolation method you want to use. By default it is
  `BSpline(Linear())`. To construct the method instance, one may need to load `Interpolations`.
- `fillvalue`: the value that used to fill the new region. The default value is `NaN` if possible,
   otherwise is `0`. One can also pass the extrapolation boundary condition: `Flat()`, `Reflect()` and `Periodic()`.

# Reconstruction scheme

During warping, values for `img` must be reconstructed at
arbitrary locations `tform(I)` which do not lie on to the lattice
of pixels. How this reconstruction is done depends on the type of
`img` and the optional parameter `degree`.

When `img` is a plain array, then on-grid b-spline interpolation
will be used. It is possible to configure what degree of b-spline
to use with the parameter `degree`. For example one can use
`degree = Linear()` for linear interpolation, `degree =
Constant()` for nearest neighbor interpolation, or `degree =
Quadratic(Flat())` for quadratic interpolation.

In the case `tform(I)` maps to indices outside the original
`img`, those locations are set to a value `fill` (which defaults
to `NaN` if the element type supports it, and `0` otherwise). The
parameter `fill` also accepts extrapolation schemes, such as
`Flat()`, `Periodic()` or `Reflect()`.

For more control over the reconstruction scheme --- and how
beyond-the-edge points are handled --- pass `img` as an
`AbstractInterpolation` or `AbstractExtrapolation` from
[Interpolations.jl](https://github.com/JuliaMath/Interpolations.jl).

The keyword `method` now also takes any InterpolationType from Interpolations.jl
or a Degree, which is used to define a BSpline interpolation of that degree, in
order to set the interpolation method used.

# The meaning of the coordinates

The output array `imgw` has indices that would result from
applying `inv(tform)` to the indices of `img`. This can be very
handy for keeping track of how pixels in `imgw` line up with
pixels in `img`.

If you just want a plain array, you can "strip" the custom
indices with `parent(imgw)`.

# Examples: a 2d rotation (see JuliaImages documentation for pictures)

```
julia> using Images, CoordinateTransformations, Rotations, TestImages, OffsetArrays

julia> img = testimage("lighthouse");

julia> axes(img)
(Base.OneTo(512),Base.OneTo(768))

# Rotate around the center of `img`
julia> tfm = recenter(RotMatrix(-pi/4), center(img))
AffineMap([0.707107 0.707107; -0.707107 0.707107], [-196.755,293.99])

julia> imgw = warp(img, tfm);

julia> axes(imgw)
(-196:709,-68:837)

# Alternatively, specify the origin in the image itself
julia> img0 = OffsetArray(img, -30:481, -384:383);  # origin near top of image

julia> rot = LinearMap(RotMatrix(-pi/4))
LinearMap([0.707107 -0.707107; 0.707107 0.707107])

julia> imgw = warp(img0, rot);

julia> axes(imgw)
(-293:612,-293:611)

julia> imgr = parent(imgw);

julia> axes(imgr)
(Base.OneTo(906),Base.OneTo(905))
```
"""
function warp(img::AbstractExtrapolation{T}, tform, inds::Tuple = autorange(img, inv(tform))) where T
    out = similar(Array{T}, inds)
    warp!(out, img, try_static(tform, img))
end

function warp!(out, img::AbstractExtrapolation, tform)
    tform = _round(tform)
    @inbounds for I in CartesianIndices(axes(out))
        out[I] = _getindex(img, tform(SVector(I.I)))
    end
    out
end

function warp(img::AbstractArray, tform, args...; kwargs...)
    etp = box_extrapolation(img; kwargs...)
    warp(etp, try_static(tform, img), args...)
end

"""
    imrotate(img, θ, [indices]; kwargs...) -> imgr

Rotate image `img` by `θ`∈[0,2π) in a clockwise direction around its center point.

# Arguments

- `img::AbstractArray`: the original image that you need to rotate.
- `θ::Real`: the rotation angle in clockwise direction. To rotate the image in conter-clockwise 
  direction, use a negative value instead. To rotate the image by `d` degree, use the formular `θ=d*π/180`.
- `indices` (Optional): specifies the output image axes. By default, rotated image `imgr` will not be
  cropped, and thus `axes(imgr) == axes(img)` does not hold in general.

# Parameters

- `method::Union{Degree, InterpolationType}`: the interpolation method you want to use. By default it is
  `BSpline(Linear())`. To construct the method instance, one may need to load `Interpolations`.
- `fillvalue`: the value that used to fill the new region. The default value is `NaN` if possible,
   otherwise is `0`. One can also pass the extrapolation boundary condition: `Flat()`, `Reflect()` and `Periodic()`.

# Examples

```julia
using TestImages, ImageTransformations
img = testimage("cameraman")

# Rotate the image by π/4 in the clockwise direction
imgr = imrotate(img, π/4) # output axes (-105:618, -105:618)
# Rotate the image by π/4 in the counter-clockwise direction
imgr = imrotate(img, -π/4) # output axes (-105:618, -105:618)

# Preserve the original axes
# Note that this is more efficient than `@view imrotate(img, π/4)[axes(img)...]`
imgr = imrotate(img, π/4, axes(img)) # output axes (1:512, 1:512)
```

By default, `imrotate` uses bilinear interpolation with constant fill value. You can,
for example, use the nearest interpolation and fill the new region with white pixels:

```julia
using Interpolations, ImageCore
imrotate(img, π/4, method=Constant(), fillvalue=oneunit(eltype(img)))
```

And with some inspiration, maybe fill with periodic values and tile the output together to
get a mosaic:

```julia
using Interpolations, ImageCore
imgr = imrotate(img, π/4, fillvalue = Periodic())
mosaicview([imgr for _ in 1:9]; nrow=3)
```

See also [`warp`](@ref).
"""
function imrotate(img::AbstractArray{T}, θ::Real, inds::Union{Tuple, Nothing} = nothing; kwargs...) where T
    # TODO: expose rotation center as a keyword
    θ = floor(mod(θ,2pi)*typemax(Int16))/typemax(Int16) # periodic discretezation
    tform = recenter(RotMatrix{2}(θ), center(img))
    # Use the `nothing` trick here because moving the `autorange` as default value is not type-stable
    inds = isnothing(inds) ? autorange(img, inv(tform)) : inds
    warp(img, tform, inds; kwargs...)
end
