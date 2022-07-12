using ImageTransformations
using OffsetArrays, StaticArrays
using ImageShow, TestImages
using LinearAlgebra

img = imresize(testimage("cameraman"), (256, 256));

function swirl(rotation, strength, radius)
    x0 = OffsetArrays.center(img)
    r = log(2)*radius/5

    function swirl_map(x::SVector{N}) where N
        xd = x .- x0
        ρ = norm(xd)
        θ = atan(reverse(xd)...)

        # Note that `x == x0 .+ ρ .* reverse(sincos(θ))`
        # swirl adds more rotations to θ based on the distance to center point
        θ̃ = θ + rotation + strength * exp(-ρ/r)

        SVector{N}(x0 .+ ρ .* reverse(sincos(θ̃)))
    end

    warp(img, swirl_map, axes(img))
end

preview = ImageShow.gif([swirl(0, 10, radius) for radius in 10:10:150]; fps=5)

# This file was generated using Literate.jl, https://github.com/fredrikekre/Literate.jl

