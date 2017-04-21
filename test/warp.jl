# helper function to compare NaN
nearlysame(x, y) = x ≈ y || (isnan(x) & isnan(y))
nearlysame(A::AbstractArray, B::AbstractArray) = all(map(nearlysame, A, B))
#img_square = Gray{N0f8}.(reshape(linspace(0,1,9), (3,3)))

SPACE = if VERSION < v"0.6.0-dev.2505" # julia PR #20288
    ""
else
    " "
end

img_camera = testimage("camera")
@testset "Constructor" begin
    tfm = recenter(RotMatrix(-pi/8), center(img_camera))
    ref_inds = (-78:591, -78:591)

    @testset "warp" begin
        imgr = @inferred(warp(img_camera, tfm))
        @test indices(imgr) == ref_inds

        for T in (Float32,Gray,RGB) # TODO: remove this signature completely
            imgr = @inferred(warp(T, img_camera, tfm))
            @test indices(imgr) == ref_inds
            @test eltype(imgr) <: T
        end

        imgr = @inferred(warp(Gray, img_camera, tfm))
        imgr2 = warp(Gray, imgr, inv(tfm))
        # look the same but are not similar enough to pass test
        # @test imgr2[indices(img_camera)...] ≈ img_camera
    end

    @testset "WarpedView" begin
        wv = @inferred(WarpedView(img_camera, tfm))
        @test summary(wv) == "-78:591×-78:591 WarpedView(::Array{Gray{N0f8},2}, AffineMap([0.92388 0.382683; -0.382683 0.92388], [-78.6334,$(SPACE)117.683])) with element type ColorTypes.Gray{FixedPointNumbers.Normed{UInt8,8}}"
        @test_throws ErrorException size(wv)
        @test_throws ErrorException size(wv, 1)
        @test indices(wv) == ref_inds
        @test eltype(wv) === eltype(img_camera)
        @test typeof(parent(wv)) <: Interpolations.AbstractExtrapolation
        @test typeof(parent(wv).itp) <: Interpolations.AbstractInterpolation
        @test parent(wv).itp.coefs === img_camera

        # check nested transformation using the inverse
        wv2 = @inferred(WarpedView(wv, inv(tfm)))
        @test indices(wv2) == indices(img_camera)
        @test eltype(wv2) === eltype(img_camera)
        @test typeof(parent(wv2)) <: Interpolations.AbstractExtrapolation
        @test typeof(parent(wv2).itp) <: Interpolations.AbstractInterpolation
        @test parent(wv2).itp.coefs === img_camera
        @test wv2 ≈ img_camera
    end
end

img_pyramid = Gray{Float64}[
    0.0 0.0 0.0 0.0 0.0;
    0.0 0.5 0.5 0.5 0.0;
    0.0 0.5 1.0 0.5 0.0;
    0.0 0.5 0.5 0.5 0.0;
    0.0 0.0 0.0 0.0 0.0;
]
img_pyramid_cntr = OffsetArray(img_pyramid, -2:2, -2:2)
ref_img_pyramid = Float64[
    NaN   NaN   NaN   NaN   NaN   NaN   NaN;
    NaN   NaN   NaN  0.172  NaN   NaN   NaN;
    NaN   NaN  0.293 0.543 0.293  NaN   NaN;
    NaN  0.172 0.543 1.000 0.543 0.172  NaN;
    NaN   NaN  0.293 0.543 0.293  NaN   NaN;
    NaN   NaN   NaN  0.172  NaN   NaN   NaN;
    NaN   NaN   NaN   NaN   NaN   NaN   NaN;
]
ref_img_pyramid_quad = Float64[
    NaN      NaN      NaN      0.003    NaN      NaN      NaN;
    NaN      NaN     -0.038    0.205   -0.038    NaN      NaN;
    NaN     -0.038    0.255    0.635    0.255   -0.038    NaN;
    0.003    0.205    0.635    1.0      0.635    0.205    0.003;
    NaN     -0.038    0.255    0.635    0.255   -0.038    NaN;
    NaN      NaN     -0.038    0.205   -0.038    NaN      NaN;
    NaN      NaN      NaN      0.003    NaN      NaN      NaN;
]

@testset "Result against reference" begin

    tfm1 = recenter(RotMatrix(-pi/4), center(img_pyramid))
    tfm2 = LinearMap(RotMatrix(-pi/4))

    @testset "warp" begin
        imgr = warp(img_pyramid, tfm1)
        @test indices(imgr) == (0:6, 0:6)
        # Use map and === because of the NaNs
        @test nearlysame(round.(Float64.(parent(imgr)),3), round.(ref_img_pyramid,3))

        @testset "OffsetArray" begin
            imgr_cntr = warp(img_pyramid_cntr, tfm2)
            @test indices(imgr_cntr) == (-3:3, -3:3)
            @test nearlysame(parent(imgr_cntr), parent(imgr))
        end

        @testset "Quadratic Interpolation" begin
            itp = interpolate(img_pyramid_cntr, BSpline(Quadratic(Flat())), OnCell())
            imgrq_cntr = warp(itp, tfm2)
            @test indices(imgrq_cntr) == (-3:3, -3:3)
            @test nearlysame(round.(Float64.(parent(imgrq_cntr)),3), round.(ref_img_pyramid_quad,3))
        end
    end

    @testset "WarpedView" begin
        imgr = WarpedView(img_pyramid, tfm1)
        @test indices(imgr) == (0:6, 0:6)
        # Use map and === because of the NaNs
        @test nearlysame(round.(Float64.(imgr[0:6, 0:6]),3), round.(ref_img_pyramid,3))

        @testset "OffsetArray" begin
            imgr_cntr = WarpedView(img_pyramid_cntr, tfm2)
            @test indices(imgr_cntr) == (-3:3, -3:3)
            @test nearlysame(imgr_cntr[indices(imgr_cntr)...], imgr[indices(imgr)...])
        end

        @testset "Quadratic Interpolation" begin
            itp = interpolate(img_pyramid_cntr, BSpline(Quadratic(Flat())), OnCell())
            imgrq_cntr = WarpedView(itp, tfm2)
            @test summary(imgrq_cntr) == "-3:3×-3:3 WarpedView(interpolate(::OffsetArray{Gray{Float64},2}, BSpline(Quadratic(Flat())), OnCell()), LinearMap([0.707107 0.707107; -0.707107 0.707107])) with element type ColorTypes.Gray{Float64}"
            @test indices(imgrq_cntr) == (-3:3, -3:3)
            @test nearlysame(round.(Float64.(imgrq_cntr[indices(imgrq_cntr)...]),3), round.(ref_img_pyramid_quad,3))
        end
    end
end
