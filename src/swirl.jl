function swirl(rotation, strength, radius)
    x0 = OffsetArrays.center(img)
    r = log(2)*radius/5

    function swirl_map(x::SVector{N}) where N
        xd = x.- x0
        ρ = norm(xd)
        θ = atan(reverse(xd)...)

        θ̃ = θ + rotation + strength * exp(-ρ/r)

        SVector{N}(x0 .+ ρ .* reverse(sincos(θ)))
    end

    warp(img, swirl_map, axes(img))
end
