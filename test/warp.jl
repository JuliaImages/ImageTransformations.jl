# helper function to compare NaN
nearlysame(x, y) = x ≈ y || (isnan(x) & isnan(y))
nearlysame(A::AbstractArray, B::AbstractArray) = all(map(nearlysame, A, B))
#img_square = Gray{N0f8}.(reshape(linspace(0,1,9), (3,3)))

SPACE = VERSION < v"0.6.0-dev.2505" ? "" : " " # julia PR #20288

img_camera = testimage("camera")
@testset "Constructor" begin
    tfm = recenter(RotMatrix(-pi/8), center(img_camera))
    ref_inds = (-78:591, -78:591)

    @testset "warp" begin
        imgr = @inferred(warp(img_camera, inv(tfm)))
        @test indices(imgr) == ref_inds
        @test eltype(imgr) == eltype(img_camera)
        @test_reference "warp_cameraman_rotate_r22deg" imgr

        imgr = @inferred(warp(img_camera, inv(tfm), 1))
        @test eltype(imgr) == eltype(img_camera)
        @test_reference "warp_cameraman_rotate_r22deg_white" imgr
        imgr2 = @inferred warp(imgr, tfm)
        @test eltype(imgr2) == eltype(img_camera)
        @test_reference "warp_cameraman" imgr2[indices(img_camera)...]
        # look the same but are not similar enough to pass test
        # @test imgr2[indices(img_camera)...] ≈ img_camera
    end

    @testset "InvWarpedView" begin
        wv = @inferred(InvWarpedView(img_camera, tfm))
        @test summary(wv) == "-78:591×-78:591 InvWarpedView(::Array{Gray{N0f8},2}, AffineMap([0.92388 0.382683; -0.382683 0.92388], [-78.6334,$(SPACE)117.683])) with element type ColorTypes.Gray{FixedPointNumbers.Normed{UInt8,8}}"
        @test_reference "invwarpedview_cameraman_rotate_r22deg" wv
        @test_throws ErrorException size(wv)
        @test_throws ErrorException size(wv, 1)
        @test indices(wv) == ref_inds
        @test eltype(wv) === eltype(img_camera)
        @test parent(wv) === img_camera

        # check nested transformation using the inverse
        wv2 = @inferred(InvWarpedView(wv, inv(tfm)))
        @test_reference "invwarpedview_cameraman" wv2
        @test indices(wv2) == indices(img_camera)
        @test eltype(wv2) === eltype(img_camera)
        @test parent(wv2) === img_camera
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
        imgr = warp(img_pyramid, inv(tfm1))
        @test indices(imgr) == (0:6, 0:6)
        @test eltype(imgr) == eltype(img_pyramid)
        # Use map and === because of the NaNs
        @test nearlysame(round.(Float64.(parent(imgr)),3), round.(ref_img_pyramid,3))

        @testset "OffsetArray" begin
            imgr_cntr = warp(img_pyramid_cntr, inv(tfm2))
            @test indices(imgr_cntr) == (-3:3, -3:3)
            @test nearlysame(parent(imgr_cntr), parent(imgr))
        end

        @testset "Quadratic Interpolation" begin
            itp = interpolate(img_pyramid_cntr, BSpline(Quadratic(Flat())), OnCell())
            imgrq_cntr = warp(itp, inv(tfm2))
            @test indices(imgrq_cntr) == (-3:3, -3:3)
            @test nearlysame(round.(Float64.(parent(imgrq_cntr)),3), round.(ref_img_pyramid_quad,3))
        end
    end

    @testset "InvWarpedView" begin
        imgr = InvWarpedView(img_pyramid, tfm1)
        @test indices(imgr) == (0:6, 0:6)
        # Use map and === because of the NaNs
        @test nearlysame(round.(Float64.(imgr[0:6, 0:6]),3), round.(ref_img_pyramid,3))

        @testset "OffsetArray" begin
            imgr_cntr = InvWarpedView(img_pyramid_cntr, tfm2)
            @test indices(imgr_cntr) == (-3:3, -3:3)
            @test nearlysame(imgr_cntr[indices(imgr_cntr)...], imgr[indices(imgr)...])
        end

        @testset "Quadratic Interpolation" begin
            itp = interpolate(img_pyramid_cntr, BSpline(Quadratic(Flat())), OnCell())
            imgrq_cntr = InvWarpedView(itp, tfm2)
            @test parent(imgrq_cntr) === itp
            @test summary(imgrq_cntr) == "-3:3×-3:3 InvWarpedView(interpolate(::OffsetArray{Gray{Float64},2}, BSpline(Quadratic(Flat())), OnCell()), LinearMap([0.707107 0.707107; -0.707107 0.707107])) with element type ColorTypes.Gray{Float64}"
            @test indices(imgrq_cntr) == (-3:3, -3:3)
            @test nearlysame(round.(Float64.(imgrq_cntr[indices(imgrq_cntr)...]),3), round.(ref_img_pyramid_quad,3))
        end
    end
end
