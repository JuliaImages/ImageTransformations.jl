"""
    CenterPoint(dims) -> cp

Create a fixed point which can be used in `imresize` and `imrotate`
functions in order to keep the value in this point the same, i.e.,

```julia
img[cp] == imgr[cp]
```
"""
struct CenterPoint{N}
    p::CartesianIndex{N}
end

CenterPoint(dims::Dims{N}) where N = CenterPoint{N}(CartesianIndex(dims))
CenterPoint(dims::Int64...) = CenterPoint(Tuple(dims))
