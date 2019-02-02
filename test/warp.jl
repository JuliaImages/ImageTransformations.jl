using CoordinateTransformations, TestImages, ImageCore, Colors, FixedPointNumbers, StaticArrays, OffsetArrays, Interpolations, LinearAlgebra
using Test, ReferenceTests

# helper function to compare NaN
nearlysame(x, y) = x ≈ y || (isnan(x) & isnan(y))
nearlysame(A::AbstractArray, B::AbstractArray) = all(map(nearlysame, A, B))
#img_square = Gray{N0f8}.(reshape(linspace(0,1,9), (3,3)))

SPACE = " " # julia PR #20288

# These module qualifications (used in showarg output) vanished for a while;
# they are left as variables in case that happens again.
#ctqual = "ColorTypes."
#fpqual = "FixedPointNumbers."
ctqual = ""
fpqual = ""

if VERSION >= v"1.2.0-DEV.229"
    sumfmt(ax,rest,img) = Base.dims2string(size(img)) * ' ' * rest * " with indices " * ax
else
    sumfmt(ax,rest,img) = rest * " with indices " * ax
end

include("twoints.jl")

img_camera = testimage("camera")
@testset "Interface tests" begin
    tfm = recenter(RotMatrix(pi/8), center(img_camera))
    ref_inds = (-78:591, -78:591)
    ref_size = map(length,ref_inds)

    @testset "warp" begin
        imgr = @inferred(warp(img_camera, tfm))
        @test typeof(imgr) <: OffsetArray
        @test axes(imgr) == ref_inds
        @test eltype(imgr) == eltype(img_camera)
        @test_reference "reference/warp_cameraman_rotate_r22deg.txt" imgr

        imgr2 = imgr[axes(img_camera)...]
        @test_reference "reference/warp_cameraman_rotate_r22deg_crop.txt" imgr2

        imgr = @inferred(warp(img_camera, tfm, axes(img_camera)))
        @test typeof(imgr) <: Array
        @test eltype(imgr) == eltype(img_camera)
        @test_reference "reference/warp_cameraman_rotate_r22deg_crop.txt" imgr

        imgr = @inferred(warp(img_camera, tfm, axes(img_camera), 1))
        @test typeof(imgr) <: Array
        @test eltype(imgr) == eltype(img_camera)
        @test_reference "reference/warp_cameraman_rotate_r22deg_crop_white.txt" imgr

        imgr = @inferred(warp(img_camera, tfm, axes(img_camera), Linear(), 1))
        @test typeof(imgr) <: Array
        @test eltype(imgr) == eltype(img_camera)
        @test_reference "reference/warp_cameraman_rotate_r22deg_crop_white.txt" imgr

        imgr = @inferred(warp(img_camera, tfm, 1))
        @test typeof(imgr) <: OffsetArray
        @test eltype(imgr) == eltype(img_camera)
        @test_reference "reference/warp_cameraman_rotate_r22deg_white.txt" imgr
        imgr2 = @inferred warp(imgr, inv(tfm))
        @test eltype(imgr2) == eltype(img_camera)
        @test_reference "reference/warp_cameraman.txt" imgr2[axes(img_camera)...]
        # look the same but are not similar enough to pass test
        # @test imgr2[axes(img_camera)...] ≈ img_camera

        imgr = @inferred(warp(img_camera, tfm, Flat()))
        @test typeof(imgr) <: OffsetArray
        @test eltype(imgr) == eltype(img_camera)
        @test_reference "reference/warp_cameraman_rotate_r22deg_flat.txt" imgr
        imgr = @inferred(warp(img_camera, tfm, ref_inds, Flat()))
        @test eltype(imgr) == eltype(img_camera)
        @test_reference "reference/warp_cameraman_rotate_r22deg_flat.txt" imgr

        imgr = @inferred(warp(img_camera, tfm, Constant(), Periodic()))
        @test typeof(imgr) <: OffsetArray
        @test eltype(imgr) == eltype(img_camera)
        @test_reference "reference/warp_cameraman_rotate_r22deg_periodic.txt" imgr
        imgr = @inferred(warp(img_camera, tfm, ref_inds, Constant(), Periodic()))
        @test eltype(imgr) == eltype(img_camera)
        @test_reference "reference/warp_cameraman_rotate_r22deg_periodic.txt" imgr

        # Ensure that dynamic arrays work as transformations
        tfmd = AffineMap(Matrix(tfm.linear), Vector(tfm.translation))
        imgrd = @inferred(warp(img_camera, tfmd))
        @test imgrd == warp(img_camera, tfm)
        tfmd = LinearMap(Matrix(tfm.linear))
        @test @inferred(warp(img_camera, tfmd)) == warp(img_camera, LinearMap(tfm.linear))
        tfmd = Translation([-2, 2])
        @test @inferred(warp(img_camera, tfmd)) == warp(img_camera, Translation(-2, 2))
        @test_throws DimensionMismatch("expected input array of length 2, got length 3") warp(img_camera, Translation([1,2,3]))

        # Since Translation can be constructed from any iterable, check that we support this too.
        # (This ensures the fallback for `_getindex` gets called even if we fix the issue by other means)
        tfmt = Translation(TwoInts(1, 2))
        @test tfmt isa Translation{TwoInts}
        imgt = warp(img_camera, tfmt)  # not necessarily inferrable, that's OK
        @test imgt == warp(img_camera, Translation(1,2))
    end

    @testset "warpedview" begin
        imgr = @inferred(warpedview(img_camera, tfm))
        @test imgr == @inferred(WarpedView(img_camera, tfm))
        @test summary(imgr) == sumfmt("-78:591×-78:591","WarpedView(::Array{Gray{N0f8},2}, AffineMap([0.92388 -0.382683; 0.382683 0.92388], [117.683,$(SPACE)-78.6334])) with eltype $(ctqual)Gray{$(fpqual)Normed{UInt8,8}}", imgr)
        @test @inferred(getindex(imgr,2,2)) == imgr[2,2]
        @test typeof(imgr[2,2]) == eltype(imgr)
        @test size(imgr) == ref_size
        @test parent(imgr) === img_camera
        @test typeof(imgr) <: WarpedView
        @test axes(imgr) == ref_inds
        @test eltype(imgr) == eltype(img_camera)
        @test_reference "reference/warp_cameraman_rotate_r22deg.txt" imgr

        imgr2 = imgr[axes(img_camera)...]
        @test_reference "reference/warp_cameraman_rotate_r22deg_crop.txt" imgr2

        imgr = @inferred(warpedview(img_camera, tfm, axes(img_camera)))
        @test imgr == @inferred(WarpedView(img_camera, tfm, axes(img_camera)))
        @test summary(imgr) == "512×512 WarpedView(::Array{Gray{N0f8},2}, AffineMap([0.92388 -0.382683; 0.382683 0.92388], [117.683,$(SPACE)-78.6334])) with eltype $(ctqual)Gray{$(fpqual)Normed{UInt8,8}}"
        @test @inferred(size(imgr)) == size(img_camera)
        @test @inferred(size(imgr,3)) == 1
        @test parent(imgr) === img_camera
        @test axes(imgr) === axes(img_camera)
        @test typeof(imgr) <: WarpedView
        @test eltype(imgr) == eltype(img_camera)
        @test_reference "reference/warp_cameraman_rotate_r22deg_crop.txt" imgr

        imgr = @inferred(warpedview(img_camera, tfm, axes(img_camera), 1))
        @test summary(imgr) == "512×512 WarpedView(extrapolate(interpolate(::Array{Gray{N0f8},2}, BSpline(Linear())), Gray{N0f8}(1.0)), AffineMap([0.92388 -0.382683; 0.382683 0.92388], [117.683,$(SPACE)-78.6334])) with eltype $(ctqual)Gray{$(fpqual)Normed{UInt8,8}}"
        @test @inferred(size(imgr)) == size(img_camera)
        @test @inferred(size(imgr,3)) == 1
        @test typeof(parent(imgr)) <: Interpolations.FilledExtrapolation
        @test parent(imgr).itp.coefs === img_camera
        @test axes(imgr) === axes(img_camera)
        @test typeof(imgr) <: WarpedView
        @test eltype(imgr) == eltype(img_camera)
        @test_reference "reference/warp_cameraman_rotate_r22deg_crop_white.txt" imgr

        imgr = @inferred(warpedview(img_camera, tfm, axes(img_camera), Linear(), 1))
        @test summary(imgr) == "512×512 WarpedView(extrapolate(interpolate(::Array{Gray{N0f8},2}, BSpline(Linear())), Gray{N0f8}(1.0)), AffineMap([0.92388 -0.382683; 0.382683 0.92388], [117.683,$(SPACE)-78.6334])) with eltype $(ctqual)Gray{$(fpqual)Normed{UInt8,8}}"
        @test @inferred(size(imgr)) == size(img_camera)
        @test @inferred(size(imgr,3)) == 1
        @test typeof(parent(imgr)) <: Interpolations.FilledExtrapolation
        @test parent(imgr).itp.coefs === img_camera
        @test axes(imgr) === axes(img_camera)
        @test typeof(imgr) <: WarpedView
        @test eltype(imgr) == eltype(img_camera)
        @test_reference "reference/warp_cameraman_rotate_r22deg_crop_white.txt" imgr

        imgr = @inferred(warpedview(img_camera, tfm, 1))
        @test summary(imgr) == sumfmt("-78:591×-78:591","WarpedView(extrapolate(interpolate(::Array{Gray{N0f8},2}, BSpline(Linear())), Gray{N0f8}(1.0)), AffineMap([0.92388 -0.382683; 0.382683 0.92388], [117.683,$(SPACE)-78.6334])) with eltype $(ctqual)Gray{$(fpqual)Normed{UInt8,8}}", imgr)
        @test size(imgr) == ref_size
        @test typeof(parent(imgr)) <: Interpolations.FilledExtrapolation
        @test parent(imgr).itp.coefs === img_camera
        @test typeof(imgr) <: WarpedView
        @test eltype(imgr) == eltype(img_camera)
        @test_reference "reference/warp_cameraman_rotate_r22deg_white.txt" imgr
        imgr2 = @inferred warpedview(imgr, inv(tfm))
        @test eltype(imgr2) == eltype(img_camera)
        @test_reference "reference/warp_cameraman.txt" imgr2[axes(img_camera)...]
        # look the same but are not similar enough to pass test
        # @test imgr2[axes(img_camera)...] ≈ img_camera

        imgr = @inferred(warpedview(img_camera, tfm, Flat()))
        @test summary(imgr) == sumfmt("-78:591×-78:591","WarpedView(extrapolate(interpolate(::Array{Gray{N0f8},2}, BSpline(Linear())), Flat()), AffineMap([0.92388 -0.382683; 0.382683 0.92388], [117.683,$(SPACE)-78.6334])) with eltype $(ctqual)Gray{$(fpqual)Normed{UInt8,8}}", imgr)
        @test size(imgr) == ref_size
        @test typeof(parent(imgr)) <: Interpolations.Extrapolation
        @test parent(imgr).itp.coefs === img_camera
        @test typeof(imgr) <: WarpedView
        @test eltype(imgr) == eltype(img_camera)
        @test_reference "reference/warp_cameraman_rotate_r22deg_flat.txt" imgr
        imgr = @inferred(warpedview(img_camera, tfm, ref_inds, Flat()))
        @test eltype(imgr) == eltype(img_camera)
        @test axes(imgr) === ref_inds
        @test_reference "reference/warp_cameraman_rotate_r22deg_flat.txt" imgr

        imgr = @inferred(warpedview(img_camera, tfm, Constant(), Periodic()))
        @test summary(imgr) == sumfmt("-78:591×-78:591","WarpedView(extrapolate(interpolate(::Array{Gray{N0f8},2}, BSpline(Constant())), Periodic()), AffineMap([0.92388 -0.382683; 0.382683 0.92388], [117.683,$(SPACE)-78.6334])) with eltype $(ctqual)Gray{$(fpqual)Normed{UInt8,8}}", imgr)
        @test size(imgr) == ref_size
        @test typeof(parent(imgr)) <: Interpolations.Extrapolation
        @test parent(imgr).itp.coefs === img_camera
        @test typeof(imgr) <: WarpedView
        @test eltype(imgr) == eltype(img_camera)
        @test_reference "reference/warp_cameraman_rotate_r22deg_periodic.txt" imgr

        imgr = @inferred(warpedview(img_camera, tfm, ref_inds, Constant(), Periodic()))
        @test summary(imgr) == sumfmt("-78:591×-78:591","WarpedView(extrapolate(interpolate(::Array{Gray{N0f8},2}, BSpline(Constant())), Periodic()), AffineMap([0.92388 -0.382683; 0.382683 0.92388], [117.683,$(SPACE)-78.6334])) with eltype $(ctqual)Gray{$(fpqual)Normed{UInt8,8}}", imgr)
        @test size(imgr) == ref_size
        @test eltype(imgr) == eltype(img_camera)
        @test_reference "reference/warp_cameraman_rotate_r22deg_periodic.txt" imgr
    end

    tfm = recenter(RotMatrix(-pi/8), center(img_camera))
    @testset "invwarpedview" begin
        wv = @inferred(InvWarpedView(img_camera, tfm))
        @test wv ≈ @inferred(InvWarpedView(WarpedView(img_camera, inv(tfm))))
        @test_reference "reference/invwarpedview_cameraman_rotate_r22deg.txt" wv
        @test size(wv) == ref_size
        @test axes(wv) == ref_inds
        @test eltype(wv) === eltype(img_camera)
        @test parent(wv) === img_camera

        # check nested transformation using the inverse
        wv2 = @inferred(InvWarpedView(wv, inv(tfm)))
        @test_reference "reference/invwarpedview_cameraman.txt" wv2
        @test axes(wv2) == axes(img_camera)
        @test eltype(wv2) === eltype(img_camera)
        @test parent(wv2) === img_camera
        @test wv2 ≈ img_camera

        imgr = @inferred(invwarpedview(img_camera, tfm))
        @test imgr == @inferred(InvWarpedView(img_camera, tfm))
        @test summary(imgr) == sumfmt("-78:591×-78:591","InvWarpedView(::Array{Gray{N0f8},2}, AffineMap([0.92388 0.382683; -0.382683 0.92388], [-78.6334,$(SPACE)117.683])) with eltype $(ctqual)Gray{$(fpqual)Normed{UInt8,8}}", imgr)
        @test size(imgr) == ref_size
        @test parent(imgr) === img_camera
        @test typeof(imgr) <: InvWarpedView
        @test axes(imgr) == ref_inds
        @test eltype(imgr) == eltype(img_camera)
        @test_reference "reference/warp_cameraman_rotate_r22deg.txt" imgr

        imgr2 = imgr[axes(img_camera)...]
        @test_reference "reference/warp_cameraman_rotate_r22deg_crop.txt" imgr2

        imgr = @inferred(invwarpedview(img_camera, tfm, axes(img_camera)))
        @test imgr == @inferred(InvWarpedView(img_camera, tfm, axes(img_camera)))
        @test summary(imgr) == "512×512 InvWarpedView(::Array{Gray{N0f8},2}, AffineMap([0.92388 0.382683; -0.382683 0.92388], [-78.6334,$(SPACE)117.683])) with eltype $(ctqual)Gray{$(fpqual)Normed{UInt8,8}}"
        @test @inferred(size(imgr)) == size(img_camera)
        @test @inferred(size(imgr,3)) == 1
        @test parent(imgr) === img_camera
        @test axes(imgr) === axes(img_camera)
        @test typeof(imgr) <: InvWarpedView
        @test eltype(imgr) == eltype(img_camera)
        @test_reference "reference/warp_cameraman_rotate_r22deg_crop.txt" imgr

        imgr = @inferred(invwarpedview(img_camera, tfm, axes(img_camera), 1))
        @test summary(imgr) == "512×512 InvWarpedView(extrapolate(interpolate(::Array{Gray{N0f8},2}, BSpline(Linear())), Gray{N0f8}(1.0)), AffineMap([0.92388 0.382683; -0.382683 0.92388], [-78.6334,$(SPACE)117.683])) with eltype $(ctqual)Gray{$(fpqual)Normed{UInt8,8}}"
        @test @inferred(size(imgr)) == size(img_camera)
        @test @inferred(size(imgr,3)) == 1
        @test typeof(parent(imgr)) <: Interpolations.FilledExtrapolation
        @test parent(imgr).itp.coefs === img_camera
        @test axes(imgr) === axes(img_camera)
        @test typeof(imgr) <: InvWarpedView
        @test eltype(imgr) == eltype(img_camera)
        @test_reference "reference/warp_cameraman_rotate_r22deg_crop_white.txt" imgr

        imgr = @inferred(invwarpedview(img_camera, tfm, axes(img_camera), Linear(), 1))
        @test summary(imgr) == "512×512 InvWarpedView(extrapolate(interpolate(::Array{Gray{N0f8},2}, BSpline(Linear())), Gray{N0f8}(1.0)), AffineMap([0.92388 0.382683; -0.382683 0.92388], [-78.6334,$(SPACE)117.683])) with eltype $(ctqual)Gray{$(fpqual)Normed{UInt8,8}}"
        @test @inferred(size(imgr)) == size(img_camera)
        @test @inferred(size(imgr,3)) == 1
        @test typeof(parent(imgr)) <: Interpolations.FilledExtrapolation
        @test parent(imgr).itp.coefs === img_camera
        @test axes(imgr) === axes(img_camera)
        @test typeof(imgr) <: InvWarpedView
        @test eltype(imgr) == eltype(img_camera)
        @test_reference "reference/warp_cameraman_rotate_r22deg_crop_white.txt" imgr

        imgr = @inferred(invwarpedview(img_camera, tfm, 1))
        @test summary(imgr) == sumfmt("-78:591×-78:591","InvWarpedView(extrapolate(interpolate(::Array{Gray{N0f8},2}, BSpline(Linear())), Gray{N0f8}(1.0)), AffineMap([0.92388 0.382683; -0.382683 0.92388], [-78.6334,$(SPACE)117.683])) with eltype $(ctqual)Gray{$(fpqual)Normed{UInt8,8}}", imgr)
        @test size(imgr) == ref_size
        @test typeof(parent(imgr)) <: Interpolations.FilledExtrapolation
        @test parent(imgr).itp.coefs === img_camera
        @test typeof(imgr) <: InvWarpedView
        @test eltype(imgr) == eltype(img_camera)
        @test_reference "reference/warp_cameraman_rotate_r22deg_white.txt" imgr

        imgr = @inferred(invwarpedview(img_camera, tfm, Flat()))
        @test summary(imgr) == sumfmt("-78:591×-78:591","InvWarpedView(extrapolate(interpolate(::Array{Gray{N0f8},2}, BSpline(Linear())), Flat()), AffineMap([0.92388 0.382683; -0.382683 0.92388], [-78.6334,$(SPACE)117.683])) with eltype $(ctqual)Gray{$(fpqual)Normed{UInt8,8}}", imgr)
        @test size(imgr) == ref_size
        @test typeof(parent(imgr)) <: Interpolations.Extrapolation
        @test parent(imgr).itp.coefs === img_camera
        @test typeof(imgr) <: InvWarpedView
        @test eltype(imgr) == eltype(img_camera)
        @test_reference "reference/warp_cameraman_rotate_r22deg_flat.txt" imgr
        imgr = @inferred(invwarpedview(img_camera, tfm, ref_inds, Flat()))
        @test eltype(imgr) == eltype(img_camera)
        @test axes(imgr) === ref_inds
        @test_reference "reference/warp_cameraman_rotate_r22deg_flat.txt" imgr

        imgr = @inferred(invwarpedview(img_camera, tfm, Constant(), Periodic()))
        @test summary(imgr) == sumfmt("-78:591×-78:591","InvWarpedView(extrapolate(interpolate(::Array{Gray{N0f8},2}, BSpline(Constant())), Periodic()), AffineMap([0.92388 0.382683; -0.382683 0.92388], [-78.6334,$(SPACE)117.683])) with eltype $(ctqual)Gray{$(fpqual)Normed{UInt8,8}}", imgr)
        @test size(imgr) == ref_size
        @test typeof(parent(imgr)) <: Interpolations.Extrapolation
        @test parent(imgr).itp.coefs === img_camera
        @test typeof(imgr) <: InvWarpedView
        @test eltype(imgr) == eltype(img_camera)
        @test_reference "reference/warp_cameraman_rotate_r22deg_periodic.txt" imgr

        imgr = @inferred(invwarpedview(img_camera, tfm, ref_inds, Constant(), Periodic()))
        @test summary(imgr) == sumfmt("-78:591×-78:591","InvWarpedView(extrapolate(interpolate(::Array{Gray{N0f8},2}, BSpline(Constant())), Periodic()), AffineMap([0.92388 0.382683; -0.382683 0.92388], [-78.6334,$(SPACE)117.683])) with eltype $(ctqual)Gray{$(fpqual)Normed{UInt8,8}}", imgr)
        @test size(imgr) == ref_size
        @test eltype(imgr) == eltype(img_camera)
        @test_reference "reference/warp_cameraman_rotate_r22deg_periodic.txt" imgr
    end

    tfm = recenter(RotMatrix(-pi/8), center(img_camera))
    @testset "view of invwarpedview" begin
        wv = @inferred(InvWarpedView(img_camera, tfm))
        # tight crop that barely contains head and camera
        v = @inferred view(wv, 75:195, 245:370)
        @test summary(v) == "121×126 view(InvWarpedView(::Array{Gray{N0f8},2}, AffineMap([0.92388 0.382683; -0.382683 0.92388], [-78.6334,$(SPACE)117.683])), 75:195, 245:370) with eltype $(ctqual)Gray{$(fpqual)Normed{UInt8,8}}"
        tfm2 = AffineMap(@SMatrix([0.6 0.;0. 0.8]), @SVector([10.,50.]))
        # this should still be a tight crop that
        # barely contains head and camera !
        wv2 = @inferred invwarpedview(v, tfm2)
        @test axes(wv2) == (55:127,246:346)
        @test typeof(wv2) <: SubArray
        @test typeof(parent(wv2)) <: InvWarpedView
        @test typeof(parent(wv2)) <: InvWarpedView
        @test parent(parent(wv2)) === img_camera
        @test summary(wv2) == sumfmt("55:127×246:346","view(InvWarpedView(::Array{Gray{N0f8},2}, AffineMap([0.554328 0.22961; -0.306147 0.739104], [-37.18,$(SPACE)144.147])), IdentityRange(55:127), IdentityRange(246:346)) with eltype $(ctqual)Gray{$(fpqual)Normed{UInt8,8}}", wv2)
        @test_reference "reference/warp_cameraman_rotate_crop_scale.txt" wv2
        wv3 = @inferred invwarpedview(v, tfm2, wv2.indices)
        @test wv3 == wv2
        @test axes(wv3) == (55:127,246:346)

        # test_broken summary for a view(InvWarpedView,...) for number eltypes
        float_array = rand(10,10)
        tfm = recenter(RotMatrix(-pi/8), center(float_array))
        wv = @inferred(InvWarpedView(float_array, tfm))
        v = @inferred view(wv, 1:10, 1:10)
        @test summary(v) == "10×10 view(InvWarpedView(::Array{Float64,2}, AffineMap([0.92388 0.382683; -0.382683 0.92388], [-1.6861,$(SPACE)2.52342])), 1:10, 1:10) with eltype Float64"
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
ref_img_pyramid_grid = Float64[
    NaN  NaN         NaN         NaN         NaN         NaN         NaN;
    NaN  NaN         NaN           0.157977  NaN         NaN         NaN;
    NaN  NaN           0.223858    0.654962    0.223858  NaN         NaN;
    NaN    0.157977    0.654962    1.0         0.654962    0.157977  NaN;
    NaN  NaN           0.223858    0.654962    0.223858  NaN         NaN;
    NaN  NaN         NaN           0.157977  NaN         NaN         NaN;
    NaN  NaN         NaN         NaN         NaN         NaN         NaN;
]

@testset "Result against reference" begin

    tfm1 = recenter(RotMatrix(pi/4), center(img_pyramid))
    tfm2 = LinearMap(RotMatrix(pi/4))

    @testset "warp" begin
        imgr = warp(img_pyramid, tfm1)
        @test axes(imgr) == (0:6, 0:6)
        @test eltype(imgr) == eltype(img_pyramid)
        # Use map and === because of the NaNs
        @test nearlysame(round.(Float64.(parent(imgr)), digits=3), round.(ref_img_pyramid,digits=3))

        @testset "OffsetArray" begin
            imgr_cntr = warp(img_pyramid_cntr, tfm2)
            @test axes(imgr_cntr) == (-3:3, -3:3)
            @test nearlysame(parent(imgr_cntr), parent(imgr))

            imgr_cntr = warp(img_pyramid_cntr, tfm2, (-1:1,-1:1))
            @test axes(imgr_cntr) == (-1:1, -1:1)
            @test nearlysame(parent(imgr_cntr), imgr[2:4,2:4])
        end

        @testset "Quadratic Interpolation" begin
            itp = interpolate(img_pyramid_cntr, BSpline(Quadratic(Flat(OnCell()))))
            imgrq_cntr = warp(itp, tfm2)
            @test axes(imgrq_cntr) == (-3:3, -3:3)
            @test nearlysame(round.(Float64.(parent(imgrq_cntr)), digits=3), round.(ref_img_pyramid_quad, digits=3))

            imgrq_cntr = warp(img_pyramid_cntr, tfm2, Quadratic(Flat(OnGrid())))
            @test axes(imgrq_cntr) == (-3:3, -3:3)
            @test nearlysame(round.(Float64.(parent(imgrq_cntr)), digits=3), round.(ref_img_pyramid_grid, digits=3))
        end
    end

    @testset "InvWarpedView" begin
        imgr = InvWarpedView(img_pyramid, inv(tfm1))
        @test axes(imgr) == (0:6, 0:6)
        # Use map and === because of the NaNs
        @test nearlysame(round.(Float64.(imgr[0:6, 0:6]), digits=3), round.(ref_img_pyramid, digits=3))

        @testset "OffsetArray" begin
            imgr_cntr = InvWarpedView(img_pyramid_cntr, inv(tfm2))
            @test axes(imgr_cntr) == (-3:3, -3:3)
            @test nearlysame(imgr_cntr[axes(imgr_cntr)...], imgr[axes(imgr)...])
        end

        @testset "Quadratic Interpolation" begin
            itp = interpolate(img_pyramid_cntr, BSpline(Quadratic(Flat(OnCell()))))
            imgrq_cntr = InvWarpedView(itp, inv(tfm2))
            @test parent(imgrq_cntr) === itp
            @test summary(imgrq_cntr) == sumfmt("-3:3×-3:3","InvWarpedView(interpolate(OffsetArray(::Array{Gray{Float64},2}, -3:3, -3:3), BSpline(Quadratic(Flat(OnCell())))), LinearMap([0.707107 0.707107; -0.707107 0.707107])) with eltype $(ctqual)Gray{Float64}", imgr)
            @test axes(imgrq_cntr) == (-3:3, -3:3)
            @test nearlysame(round.(Float64.(imgrq_cntr[axes(imgrq_cntr)...]), digits=3), round.(ref_img_pyramid_quad, digits=3))
        end
    end

    @testset "imrotate" begin
    # imrotate is a wrapper, hence only need to guarantee the interface works as expected

        test_types = (Float32, Float64, N0f8, N0f16)
        graybar = repeat(range(0,stop=1,length=100),1,100)
        @testset "interface" begin
            for T in test_types
                img = Gray{T}.(graybar)
                @test_nowarn imrotate(img, π/4)
                @test_nowarn imrotate(img, π/4, Constant())
                @test_nowarn imrotate(img, π/4, Linear())
                @test_nowarn imrotate(img, π/4, axes(img))
                @test_nowarn imrotate(img, π/4, axes(img), Constant())
                @test isequal(channelview(imrotate(img,π/4)), channelview(imrotate(img, π/4, Linear()))) # TODO: if we remove channelview the test will break for Float
            end
        end

        @testset "numerical" begin
            for T in test_types
                img = Gray{T}.(graybar)
                for θ in range(0,stop=2π,length = 100)
                    @test isequal(channelview(imrotate(img,θ)), channelview(imrotate(img,θ+2π))) # TODO: if we remove channelview the test will break for Float
                end
            end
        end
    end
end
