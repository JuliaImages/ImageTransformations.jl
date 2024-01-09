"""
    swirl(img, rotation, strength, radius, x0 = OffsetArrays.center(img))

Create whirlpool effect on `img`

# Arguments
- `img`: to specify input image array
- `rotation`: to specify rotation angle(clockwise)
- `strength`:to specify amount of swirl 
- `radius`:to specify extent of swirl 
- `x0` (optional): to specify the center point of the swirl. The default value is `OffsetArrays.center(img)`.
# Examples

```julia
using ImageTransformations, TestImages


img = imresize(testimage("cameraman"), (256, 256));

preview = swirl(img, 0, 10, 50, 100) # swirl with rotation 0, strength 10, radius 50, x0 center 100
```
"""
function swirl(img, rotation, strength, radius, x0 = OffsetArrays.center(img))
    r = log(2)*radius/5

    function swirl_map(x::SVector{N}) where N
        xd = x .- x0
        ρ = norm(xd)
        θ = atan(reverse(xd)...)

        θ̃ = θ + rotation + strength * exp(-ρ/r)

        SVector{N}(x0 .+ ρ .* reverse(sincos(θ̃)))
    end

    warp(img, swirl_map, axes(img))
end
