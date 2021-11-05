"""

This package provides support for image resizing, image rotation, and other spatial transformations of arrays.

- `WarpedView`: Create a view of `img` that lazily transforms any given index `I` passed to `wv[I]` so that `wv[I] == img[tform(I)]`.
- `warp`: An eager evaluation variant of `WarpedView`. Transform the coordinates of `img`, returning a new `imgw` satisfying `imgw[I] = img[tform(I)]`. 
- `InvWarpedView`: Create a view of `img` that lazily transforms any given index `I` passed to `wv[I]` so that `wv[I] == img[inv(tinv)(I)]`.
- `imresize`: Upsample/downsample the image `img` to a given size `sz` or axes `inds` using interpolations.
- `restrict`: A much more efficient version of `imresize` that two-folds/down-samples image to approximate 1/2 size. (This is now provided by `ImageBase.restrict`)
- `imrotate`: Rotate image `img` by `θ`∈[0,2π) in a clockwise direction around its center point.
- `autorange`: For given transformation `tform`, return the "smallest" range indices that preserves all information from `A` after applying `tform`.

There are in-place version of many of the functions, e.g., `imresize!` etc.

Resize example:

```jldoctest
using ImageTransformations, TestImages

img = testimage("mandrill")

img_small = imresize(img, ratio=1/8)
img_medium = imresize(img_small, size(img_small).*2)
```

Warping example:

```jldoctest
using ImageTransformations, TestImages, CoordinateTransformations, Rotations

img = testimage("camera");

# define transformation
trfm = recenter(RotMatrix(pi/8), center(img));
imgw = warp(img, trfm);
```
"""
module ImageTransformations

using ImageCore
using CoordinateTransformations
using Rotations
using StaticArrays
using Interpolations, AxisAlgorithms
using OffsetArrays
using ColorVectorSpace

using Base: tail, Indices

# these two symbols previously live in ImageTransformations
import ImageBase: restrict, restrict!

export

    restrict,
    imresize,
    imresize!,
    center,
    warp,
    WarpedView,
    warpedview,
    InvWarpedView,
    invwarpedview,
    imrotate

include("autorange.jl")
include("interpolations.jl")
include("warp.jl")
include("warpedview.jl")
include("invwarpedview.jl")
include("resizing.jl")
include("compat.jl")
include("deprecated.jl")

# TODO: move to warp.jl
@inline _getindex(A, v::StaticVector) = A[Tuple(v)...]
@inline _getindex(A::AbstractInterpolation, v::StaticVector) = A(Tuple(v)...)
@inline _getindex(A, v) = A[v...]
@inline _getindex(A::AbstractInterpolation, v) = A(v...)

center(img::AbstractArray{T,N}) where {T,N} = SVector{N}(map(_center, axes(img)))
_center(ind::AbstractUnitRange) = (first(ind)+last(ind))/2

end # module
