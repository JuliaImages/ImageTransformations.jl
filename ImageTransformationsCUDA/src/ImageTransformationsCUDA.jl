"""

This package provides analogous ImageTransformation functions for CuArrays.

    - `warp`: Transforms coordinates of a CuArray, returning an OffsetArray with a CuArray within.
"""
module ImageTransformationsCUDA

using ImageTransformations

using OffsetArrays, Rotations, StaticArrays, CoordinateTransformations
using CUDA

export 
    
    warp

include("warpCUDA.jl")
include("interpolationsCUDA.jl")

end # module
