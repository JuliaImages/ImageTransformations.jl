using ImageTransformations, CoordinateTransformations, TestImages, ImageCore, Colors, FixedPointNumbers
using Base.Test

#img = testimage("camera")
#tfm = recenter(RotMatrix(-pi/8), center(img))
#imgr = warp(img, tfm)
#@test indices(imgr) == (-78:591, -78:591)
#imgr2 = warp(imgr, inv(tfm))   # this will need fixes in Interpolations
#@test imgr2[indices(img)...] ≈ img

@testset "Restriction" begin
    imgcol = colorview(RGB, rand(3,5,6))
    A = reshape([convert(UInt16, i) for i = 1:60], 4, 5, 3)
    B = restrict(A, (1,2))
    Btarget = cat(3, [ 0.96875  4.625   5.96875;
                        2.875   10.5    12.875;
                        1.90625  5.875   6.90625],
                    [ 8.46875  14.625 13.46875;
                    17.875    30.5   27.875;
                    9.40625  15.875 14.40625],
                    [15.96875  24.625 20.96875;
                    32.875    50.5   42.875;
                    16.90625  25.875 21.90625])
    @test B ≈ Btarget
    Argb = reinterpret(RGB, reinterpret(N0f16, permutedims(A, (3,1,2))))
    B = restrict(Argb)
    Bf = permutedims(reinterpret(eltype(eltype(B)), B), (2,3,1))
    @test isapprox(Bf, Btarget/reinterpret(one(N0f16)), atol=1e-12)
    Argba = reinterpret(RGBA{N0f16}, reinterpret(N0f16, A))
    B = restrict(Argba)
    @test isapprox(reinterpret(eltype(eltype(B)), B), restrict(A, (2,3))/reinterpret(one(N0f16)), atol=1e-12)
    A = reshape(1:60, 5, 4, 3)
    B = restrict(A, (1,2,3))
    @test cat(3, [ 2.6015625  8.71875 6.1171875;
                    4.09375   12.875   8.78125;
                    3.5390625 10.59375 7.0546875],
                    [10.1015625 23.71875 13.6171875;
                    14.09375   32.875   18.78125;
                    11.0390625 25.59375 14.5546875]) ≈ B
    #imgcolax = AxisArray(imgcol, :y, :x)
    #imgr = restrict(imgcolax, (1,2))
    #@test pixelspacing(imgr) == (2,2)
    #@test pixelspacing(imgcolax) == (1,1)  # issue #347
    #@inferred(restrict(imgcolax, Axis{:y}))
    #@inferred(restrict(imgcolax, Axis{:x}))
    # Issue #395
    img1 = colorview(RGB, fill(0.9, 3, 5, 5))
    img2 = colorview(RGB, fill(N0f8(0.9), 3, 5, 5))
    @test isapprox(channelview(restrict(img1)), channelview(restrict(img2)), rtol=0.01)
end

@testset "Image resize" begin
    img = zeros(10,10)
    img2 = imresize(img, (5,5))
    @test length(img2) == 25
    img = rand(RGB{Float32}, 10, 10)
    img2 = imresize(img, (6,7))
    @test size(img2) == (6,7)
    @test eltype(img2) == RGB{Float32}
end

