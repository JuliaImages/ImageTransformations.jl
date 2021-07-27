"""
    zoom(img; ratio, [fixed_point], kwargs...)

Zoom in/out.
"""
function zoom(img; ratio, kwargs...)
    all(ratio .> 0) || throw(ArgumentError("ratio $ratio should be positive"))
    new_size = ceil.(Int, size(img) .* ratio) # use ceil to avoid 0
    _zoom(img, new_size; kwargs...)
end

# TODO:
#   before we make this a part of API, we need to figure out how should we interpret
#   the axes information.
function _zoom(img, size_or_axes; fixed_point=OffsetArrays.center(img), kwargs...)
    # zoom introduces out-of-domain points, so we need to build extrapolation

    # Because `first(CartesianIndices(R)) == oneunit(first(R))`, we need to
    # preserve the axes information if `size_or_axes` is actually an CartesianIndices `R`
    Rdst = if size_or_axes isa AbstractArray{<:CartesianIndex}
        size_or_axes
    else
        CartesianIndices(size_or_axes)
    end
    Rsrc = CartesianIndices(img)
    tform = zoom_coordinate_map(Rdst, Rsrc, fixed_point)
    @assert tform(SVector(fixed_point)) == SVector(fixed_point)

    warp(img, tform, Rsrc.indices)
end

function zoom_coordinate_map(Rdst, Rsrc, c)
    k = SVector((size(Rsrc) .- 1) ./(size(Rdst) .- 1))
    b = @. (1-k)*c
    return x->@. k*x + b
end
