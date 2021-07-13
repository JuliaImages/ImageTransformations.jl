# ---
# cover: assets/swirl.gif
# title: Swirl effect using warp operation
# author: Johnny Chen
# date: 2021-07-12
# ---

# In this example, we illustrate how to construct a custom warping map
# and pass it to `warp`. This swirl example comes from
# [the Princeton Computer Graphics course for Image Warping (Fall 2000)](https://www.cs.princeton.edu/courses/archive/fall00/cs426/lectures/warp/warp.pdf)
# and [scikit-image swirl example](https://scikit-image.org/docs/dev/auto_examples/transform/plot_swirl.html).

using ImageTransformations
using OffsetArrays, StaticArrays
using ImageShow, TestImages
using LinearAlgebra

img = imresize(testimage("cameraman"), (256, 256));

# As we've illustrated in [image warping](@ref index_image_warping), a warp operation
# consists of two operations: backward coordinate map `ϕ` and intensity estimator.
# To implement swirl operation, we need to customize the coordinate map `ϕ`.
# A valid coordinate map `q = ϕ(p)` follows the following interface:
#
# ```julia
# # SVector comes from StaticArrays
# ϕ(::SVector{N})::SVector{N} where N
# ```
#
# A cartesian position `(x, y)` can be transfered to/from polar coordinate `(ρ, θ)`
# using formula:
#
# ```julia
# # Cartesian to Polar
# ρ = norm(y-y0, x-x0)
# θ = atan(y/x)
#
# # Polar to Cartesian
# y = y0 + ρ*sin(θ)
# x = x0 + ρ*cos(θ)
# ```
#
# For given input index `p`, a swirl operation enforces more rotations in its polar coordinate using
# `θ̃ = θ + ϕ + s*exp(-ρ/r)`, and returns the cartesian index (x̃, ỹ) from the warped polor coordinate
# (ρ, θ̃). (Here we use the formula from [scikit-image swirl example](https://scikit-image.org/docs/dev/auto_examples/transform/plot_swirl.html)
# to build our version.)

function swirl(rotation, strength, radius)
    x0 = OffsetArrays.center(img)
    r = log(2)*radius/5

    function swirl_map(x::SVector{N}) where N
        xd = x .- x0
        ρ = norm(xd)
        θ = atan(reverse(xd)...)

        ## Note that `x == x0 .+ ρ .* reverse(sincos(θ))`
        ## swirl adds more rotations to θ based on the distance to center point
        θ̃ = θ + rotation + strength * exp(-ρ/r)
        
        SVector{N}(x0 .+ ρ .* reverse(sincos(θ̃)))
    end

    warp(img, swirl_map, axes(img))
end

# Now let's see how radius argument affects the result

preview = ImageShow.gif([swirl(0, 10, radius) for radius in 10:10:150]; fps=5)

using FileIO #src
save("assets/swirl.gif", preview; fps=5) #src
