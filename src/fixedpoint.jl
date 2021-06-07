"""
    FixedPoint(dims) -> fp

Create a fixed point which can be used in `imresize` and `imrotate`
functions in order to keep the value in this point the same, i.e.,

```jldoctest
img[fp] == imgr[fp]
```
"""
struct FixedPoint{N}
    p::CartesianIndex{N}
end

FixedPoint(dims::Dims{N}) where N = FixedPoint{N}(CartesianIndex(dims))
FixedPoint(dims::Int64...) = FixedPoint(Tuple(dims))
