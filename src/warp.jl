"""
    warp(img, tform, [indices]; kwargs...) -> imgw

Transform the coordinates of `img`, returning a new `imgw` satisfying `imgw[I] = img[tform(I)]`.

# Output

The output array `imgw` is an `OffsetArray`. Unless manually specified, `axes(imgw) == axes(img)`
does not hold in general. If you just want a plain array, you can "strip" the custom indices with
`parent(imgw)` or `OffsetArrays.no_offset_view(imgw)`.

# Arguments

- `img`: the original image that you need coordinate transformation.
- `tform`: the coordinate transformation function or function-like object, it must accept a
  [`SVector`](https://github.com/JuliaArrays/StaticArrays.jl) as input. A useful package to
  create a wide variety of such transfomrations is
  [CoordinateTransformations.jl](https://github.com/FugroRoames/CoordinateTransformations.jl).
- `indices` (Optional): specifies the output image axes.
  By default, the indices are computed in such a way that `imgw` contains all the original pixels
  in `img` using [`autorange`](@ref ImageTransformations.autorange). To do this `inv(tform)` has
  to be computed. If the given transfomration `tform` does not support `inv` then the parameter
  `indices` has to be specified manually.

# Parameters

!!! info
    To construct `method` and `fillvalue` values, you may need to load `Interpolations` package first.

- `method::Union{Degree, InterpolationType}`: the interpolation method you want to use. By default it is
  `BSpline(Linear())`. To construct the method instance, one may need to load `Interpolations`.
- `fillvalue`: the value that used to fill the new region. The default value is `NaN` if possible,
  otherwise is `0`. One can also pass the extrapolation boundary condition: `Flat()`, `Reflect()` and `Periodic()`.

# See also

There're some high-level interfaces of `warp`:

- image rotation: [`imrotate`](@ref)
- image resize: [`imresize`](@ref)

There are also lazy version of `warp`:

- [`WarpedView`](@ref) is almost equivalent to `warp` except that it does not allocate memory.
- [`invwarpedview(img, tform, [indices]; kwargs...)`](@ref ImageTransformations.invwarpedview)
  is almost equivalent to `warp(img, inv(tform), [indices]; kwargs...)` except that it does not
  allocate memory.

# Extended help

## Parameters in detail

This approach is known as backward mode warping. It is called "backward" because
the internal coordinate transformation is actually an inverse map from `axes(imgr)` to `axes(img)`.

You can manually specify interpolation behavior by constructing `AbstractExtrapolation` object
and passing it to `warp` as `img`. However, this is usually cumbersome. For this reason, there 
are two keywords `method` and `fillvalue` to conveniently construct an `AbstractExtrapolation`
object during `warp`.

!!! warning
    If `img` is an `AbstractExtrapolation`, then additional `method` and `fillvalue` keywords
    will be discarded.

### `method::Union{Degree, InterpolationType}`

The interpolation method you want to use to reconstruct values in the wrapped image.

Among those possible `InterpolationType` choice, there are some commonly used methods that you may
have used in other languages:

- nearest neighbor: `BSpline(Constant())`
- triangle/bilinear: `BSpline(Linear())`
- bicubic: `BSpline(Cubic(Line(OnGrid())))`
- lanczos2: `Lanczos(2)`
- lanczos3: `Lanczos(3)`
- lanczos4: `Lanczos(4)` or `Lanczos4OpenCV()`

When passing a `Degree`, it is expected to be a `BSpline`. For example, `Linear()` is equivalent to
`BSpline(Linear())`.

### `fillvalue`

In case `tform(I)` maps to indices outside the original `img`, those locations are set to a value
`fillvalue`. The default fillvalue is `NaN` if the element type of `img` supports it, and `0`
otherwise.

The parameter `fillvalue` can be either a `Number` or `Colorant`. In this case, it will be
converted to `eltype(imgr)` first. For example, `fillvalue = 1` will be converted to `Gray(1)` which
will fill the outside indices with white pixels.

Also, `fillvalue` can be extrapolation schemes: `Flat()`, `Periodic()` and `Reflect()`. The best
way to understand these schemes is perhaps try it with small example:

```jldoctest
using ImageTransformations, TestImages, Interpolations
using OffsetArrays: IdOffsetRange

img = testimage("lighthouse")

imgr = imrotate(img, π/4; fillvalue=Flat()) # zero extrapolation slope
imgr = imrotate(img, π/4; fillvalue=Periodic()) # periodic boundary
imgr = imrotate(img, π/4; fillvalue=Reflect()) # mirror boundary

axes(imgr)

# output

(IdOffsetRange(values=-196:709, indices=-196:709), IdOffsetRange(values=-68:837, indices=-68:837))
```

## The meaning of the coordinates

`imgw` keeps track of the indices that would result from applying `inv(tform)` to the indices of
`img`. This can be very handy for keeping track of how pixels in `imgw` line up with
pixels in `img`.

```jldoctest
using ImageTransformations, TestImages, Interpolations

img = testimage("lighthouse")
imgr = imrotate(img, π/4)
imgr_cropped = imrotate(img, π/4, axes(img))

# No need to manually calculate the offsets
imgr[axes(img)...] == imgr_cropped

# output
true
```

!!! tip
    For performance consideration, it's recommended to pass the `inds` positional argument to
    `warp` instead of cropping the output with `imgw[inds...]`.

# Examples: a 2d rotation

!!! note
    This example only shows how to construct `tform` and calls `warp`. For common usage, it is
    recommended to use [`imrotate`](@ref) function directly.

Rotate around the center of `img`:

```jldoctest
using ImageTransformations, CoordinateTransformations, Rotations, TestImages, OffsetArrays
img = testimage("lighthouse") # axes (1:512, 1:768)

tfm = recenter(RotMatrix(-pi/4), center(img))
imgw = warp(img, tfm)

axes(imgw)

# output

(IdOffsetRange(values=-196:709, indices=-196:709), IdOffsetRange(values=-68:837, indices=-68:837))
```

"""
function warp(img::AbstractExtrapolation{T}, tform, inds::Tuple = autorange(img, inv(tform))) where T
    out = similar(Array{T}, inds)
    warp!(out, img, try_static(tform, img))
end

function warp!(out, img::AbstractExtrapolation, tform)
    tform = _round(tform)
    @inbounds for I in CartesianIndices(axes(out))
        # Backward mode:
        #   1. get the target index `I` of `out`
        #   2. maps _back_ to original index `Ĩ` of `img`
        #   3. interpolate/extrapolate the value of `Ĩ`
        #   4. this value is then assigned to `out[I]`
        # The advantage of backward mode is that all piexels
        # in the output image will be iterated once very efficiently.
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
- `θ::Real`: the rotation angle in clockwise direction.
  To rotate the image in conter-clockwise direction, use a negative value instead.
  To rotate the image by `d` degree, use the formular `θ=d*π/180`.
- `indices` (Optional): specifies the output image axes. By default, rotated image `imgr` will not be
  cropped, and thus `axes(imgr) == axes(img)` does not hold in general.

# Parameters

!!! info
    To construct `method` and `fillvalue` values, you may need to load `Interpolations` package first.

- `method::Union{Degree, InterpolationType}`: the interpolation method you want to use. By default it is
  `Linear()`.
- `fillvalue`: the value that used to fill the new region. The default value is `NaN` if possible,
  otherwise is `0`.

This function is a simple high-level interface to `warp`, for more explaination and details,
please refer to [`warp`](@ref).

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

By default, `imrotate` uses bilinear interpolation with constant fill value (`NaN` or `0`). You can,
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
"""
function imrotate(img::AbstractArray{T}, θ::Real, inds::Union{Tuple, Nothing} = nothing; kwargs...) where T
    # TODO: expose rotation center as a keyword
    θ = floor(mod(θ,2pi)*typemax(Int16))/typemax(Int16) # periodic discretezation
    tform = recenter(RotMatrix{2}(θ), center(img))
    # Use the `nothing` trick here because moving the `autorange` as default value is not type-stable
    inds = isnothing(inds) ? autorange(img, inv(tform)) : inds
    warp(img, tform, inds; kwargs...)
end
