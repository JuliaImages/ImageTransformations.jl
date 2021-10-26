# restrict
function restrict(img::Union{WarpedView, InvWarpedView}, dims::Integer)
    # preserve axes information but eagerly evaluate the transformation
    # TODO: this eager evaluation destroy the laziness of `WarpedView`
    #       and `InvWarpedView`.
    restrict(OffsetArray(collect(img), axes(img)), dims)
end

# imresize
imresize(original::AbstractArray, dim1::T, dimN::T...; kwargs...) where T<:Union{Integer,AbstractUnitRange} = imresize(original, (dim1,dimN...); kwargs...)
function imresize(original::AbstractArray; ratio, kwargs...)
    all(ratio .> 0) || throw(ArgumentError("ratio $ratio should be positive"))
    new_size = ceil.(Int, size(original) .* ratio) # use ceil to avoid 0
    imresize(original, new_size; kwargs...)
end

function imresize(original::AbstractArray, short_size::Union{Indices{M},Dims{M}}; kwargs...) where M
    len_short = length(short_size)
    len_short > ndims(original) && throw(DimensionMismatch("$short_size has too many dimensions for a $(ndims(original))-dimensional array"))
    new_size = ntuple(i -> (i > len_short ? odims(original, i, short_size) : short_size[i]), ndims(original))
    imresize(original, new_size; kwargs...)
end

function imresize(original::AbstractArray, itp::Union{Interpolations.Degree,Interpolations.InterpolationType}, args...; kwargs...)
    throw(ArgumentError("Positional parameter for interpolation method is not supported; use keyword `method` instead."))
end

odims(original, i, short_size::Tuple{Integer,Vararg{Integer}}) = size(original, i)
odims(original, i, short_size::Tuple{}) = axes(original, i)
odims(original, i, short_size) = oftype(first(short_size), axes(original, i))

"""
    imresize(img, sz; [method]) -> imgr
    imresize(img, inds; [method]) -> imgr
    imresize(img; ratio, [method]) -> imgr

upsample/downsample the image `img` to a given size `sz` or axes `inds` using interpolations. If
`ratio` is provided, the output size is then `ceil(Int, size(img).*ratio)`.

!!! tip
    This interpolates the values at sub-pixel locations. If you are shrinking the image, you risk
    aliasing unless you low-pass filter `img` first.

# Arguments

- `img`: the input image array
- `sz`: the size of output array
- `inds`: the axes of output array
  If `inds` is passed, the output array `imgr` will be `OffsetArray`.

# Parameters

!!! info
    To construct `method`, you may need to load `Interpolations` package first.

- `ratio`: the upsample/downsample ratio used.
  The output size is `ceil(Int, size(img).*ratio)`. If `ratio` is larger than `1`, it is
  an upsample operation. Otherwise it is a downsample operation. `ratio` can also be a tuple,
  in which case `ratio[i]` specifies the resize ratio at dimension `i`.
- `method::InterpolationType`: 
  specify the interpolation method used for reconstruction. conveniently, `methold` can
  also be a `Degree` type, in which case a `BSpline` object will be created.
  For example, `method = Linear()` is equivalent to `method = BSpline(Linear())`.

# Examples

```julia
using ImageTransformations, TestImages, Interpolations

img = testimage("lighthouse") # 512*768

# pass integers as size
imresize(img, 256, 384) # 256*384
imresize(img, (256, 384)) # 256*384
imresize(img, 256) # 256*768

# pass indices as axes
imresize(img, 1:256, 1:384) # 256*384
imresize(img, (1:256, 1:384)) # 256*384
imresize(img, (1:256, )) # 256*768

# pass resize ratio
imresize(img, ratio = 0.5) #256*384
imresize(img, ratio = (2, 1)) # 1024*768

# use different interpolation method
imresize(img, (256, 384), method=Linear()) # 256*384 bilinear interpolation
imresize(img, (256, 384), method=Lanczos4OpenCV()) # 256*384 OpenCV-compatible Lanczos 4 interpolation
```

For downsample with `ratio=0.5`, [`restrict`](@ref) is a much faster two-fold implementation that
you can use.
"""
function imresize(original::AbstractArray{T,0}, new_inds::Tuple{}; kwargs...) where T
    Tnew = imresize_type(first(original))
    copyto!(similar(original, Tnew), original)
end

function imresize(original::AbstractArray{T,N}, new_size::Dims{N}; kwargs...) where {T,N}
    Tnew = imresize_type(first(original))
    inds = axes(original)
    if map(length, inds) == new_size
        dest = similar(original, Tnew, new_size)
        if axes(dest) == inds
            copyto!(dest, original)
        else
            copyto!(dest, CartesianIndices(axes(dest)), original, CartesianIndices(inds))
        end
    else
        imresize!(similar(original, Tnew, new_size), original; kwargs...)
    end
end

function imresize(original::AbstractArray{T,N}, new_inds::Indices{N}; kwargs...) where {T,N}
    Tnew = imresize_type(first(original))
    if axes(original) == new_inds
        copyto!(similar(original, Tnew), original)
    else
        imresize!(similar(original, Tnew, new_inds), original; kwargs...)
    end
end

# To choose the output type, rather than forcing everything to
# Float64 by multiplying by 1.0, we exploit the fact that the scale
# changes correspond to integer ratios.  We mimic ratio arithmetic
# without actually using Rational (which risks promoting to a
# Rational type, too slow for image processing).
function imresize_type(c::Colorant)
    CT = base_colorant_type(c)
    isconcretetype(CT) && return CT # special 0-parameter colorant types: ARGB32, etc
    CT{eltype(imresize_type(Gray(c)))}
end
imresize_type(c::Gray) = Gray{imresize_type(gray(c))}
imresize_type(c::FixedPoint) = typeof(c)
imresize_type(c) = typeof((c*1)/1)

function imresize!(resized::AbstractArray{T,N}, original::AbstractArray{S,N}; method::Union{Interpolations.Degree,Interpolations.InterpolationType}=BSpline(Linear()), kwargs...) where {T,S,N}
    _imresize!(resized, original, method; kwargs...)
end
function _imresize!(resized::AbstractArray{T,N}, original::AbstractArray{S,N}, method::Union{Interpolations.Degree, Interpolations.BSpline{D}}; kwargs...) where {T,S,N,D}
    imresize!(resized, interpolate!(original, wrap_BSpline(method)))
end
function _imresize!(resized::AbstractArray{T,N}, original::AbstractArray{S,N}, method::Interpolations.InterpolationType; kwargs...) where {T,S,N}
    imresize!(resized, interpolate(original, method))
end

function imresize!(resized::AbstractArray{T,N}, original::AbstractInterpolation{S,N}) where {T,S,N}
    # Define the equivalent of an affine transformation for mapping
    # locations in `resized` to the corresponding position in
    # `original`. We take the viewpoint that a pixel at `i, j` is a
    # sensor that *integrates* the intensity over an area spanning
    # `i±0.5, j±0.5` (this is a good model of how a camera pixel
    # actually works). We then map the *outer corners* of the two
    # images to each other, i.e., in typical cases
    #     (0.5, 0.5) -> (0.5, 0.5)  (outer corner, top left)
    #     size(resized)+0.5 -> size(original)+0.5  (outer corner, lower right)
    # This ensures that both images cover exactly the same area.
    Ro, Rr = CartesianIndices(axes(original)), CartesianIndices(axes(resized))
    sf = map(/, (last(Ro)-first(Ro)).I .+ 1, (last(Rr)-first(Rr)).I .+ 1) # +1 for outer corners
    offset = map((io,ir,s)->io - 0.5 - s*(ir-0.5), first(Ro).I, first(Rr).I, sf)
    if all(x->x >= 1, sf)
        @inbounds for I in Rr
            I_o = map3((i,s,off)->s*i+off, I.I, sf, offset)
            resized[I] = original(I_o...)
        end
    else
        @inbounds for I in Rr
            I_o = clampR(map3((i,s,off)->s*i+off, I.I, sf, offset), Ro)
            resized[I] = original(I_o...)
        end
    end
    resized
end

# map isn't optimized for 3 tuple-arguments, so do it here
@inline map3(f, a, b, c) = (f(a[1], b[1], c[1]), map3(f, tail(a), tail(b), tail(c))...)
@inline map3(f, ::Tuple{}, ::Tuple{}, ::Tuple{}) = ()

function clampR(I::NTuple{N}, R::CartesianIndices{N}) where N
    map3(clamp, I, first(R).I, last(R).I)
end
