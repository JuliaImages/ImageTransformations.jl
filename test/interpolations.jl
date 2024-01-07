@testset "_default_fillvalue" begin
    @test_throws UndefVarError _default_fillvalue
    @test typeof(ImageTransformations._default_fillvalue) <: Function

    @test @inferred(ImageTransformations._default_fillvalue(N0f8)) === N0f8(0)
    @test @inferred(ImageTransformations._default_fillvalue(Int)) === 0
    @test @inferred(ImageTransformations._default_fillvalue(Float16)) === NaN16
    @test @inferred(ImageTransformations._default_fillvalue(Float32)) === NaN32
    @test @inferred(ImageTransformations._default_fillvalue(Float64)) === NaN

    @test @inferred(ImageTransformations._default_fillvalue(Gray{N0f8})) === Gray{N0f8}(0)
    @test @inferred(ImageTransformations._default_fillvalue(Gray{Float16})) === Gray{Float16}(NaN16)
    @test @inferred(ImageTransformations._default_fillvalue(Gray{Float32})) === Gray{Float32}(NaN32)
    @test @inferred(ImageTransformations._default_fillvalue(Gray{Float64})) === Gray{Float64}(NaN)

    @test @inferred(ImageTransformations._default_fillvalue(GrayA{N0f8})) === GrayA{N0f8}(0,0)
    @test @inferred(ImageTransformations._default_fillvalue(GrayA{Float16})) === GrayA{Float16}(NaN16,NaN16)
    @test @inferred(ImageTransformations._default_fillvalue(GrayA{Float32})) === GrayA{Float32}(NaN32,NaN32)
    @test @inferred(ImageTransformations._default_fillvalue(GrayA{Float64})) === GrayA{Float64}(NaN,NaN)

    @test @inferred(ImageTransformations._default_fillvalue(RGB{N0f8})) === RGB{N0f8}(0,0,0)
    @test @inferred(ImageTransformations._default_fillvalue(RGB{Float16})) === RGB{Float16}(NaN16,NaN16,NaN16)
    @test @inferred(ImageTransformations._default_fillvalue(RGB{Float32})) === RGB{Float32}(NaN32,NaN32,NaN32)
    @test @inferred(ImageTransformations._default_fillvalue(RGB{Float64})) === RGB{Float64}(NaN,NaN,NaN)

    @test @inferred(ImageTransformations._default_fillvalue(RGBA{N0f8})) === RGBA{N0f8}(0,0,0,0)
    @test @inferred(ImageTransformations._default_fillvalue(RGBA{Float16})) === RGBA{Float16}(NaN16,NaN16,NaN16,NaN16)
    @test @inferred(ImageTransformations._default_fillvalue(RGBA{Float32})) === RGBA{Float32}(NaN32,NaN32,NaN32,NaN32)
    @test @inferred(ImageTransformations._default_fillvalue(RGBA{Float64})) === RGBA{Float64}(NaN,NaN,NaN,NaN)

    @test @inferred(ImageTransformations._default_fillvalue(HSV{Float16})) === HSV{Float16}(NaN16,NaN16,NaN16)
    @test @inferred(ImageTransformations._default_fillvalue(HSV{Float32})) === HSV{Float32}(NaN32,NaN32,NaN32)
    @test @inferred(ImageTransformations._default_fillvalue(HSV{Float64})) === HSV{Float64}(NaN,NaN,NaN)
end

@testset "box_extrapolation" begin
    @test_throws UndefVarError box_extrapolation
    @test typeof(ImageTransformations.box_extrapolation) <: Function

    img = rand(Gray{N0f8}, 2, 2)

    for method in (Linear(), BSpline(Linear()), Constant(), BSpline(Constant()))
        etp = @inferred ImageTransformations.box_extrapolation(img, method=method)
        @test @inferred(ImageTransformations.box_extrapolation(etp)) === etp
        @test_nowarn summary(etp)
        @test size(etp) == size(img)
        @test eltype(etp) == eltype(img)
        @test etp.itp isa Interpolations.BSplineInterpolation
        @test etp isa Interpolations.FilledExtrapolation
        @test etp.fillvalue === Gray{N0f8}(0.0)
        @test etp.itp.coefs === img
    end

    # to catch regressions like #60
    @test @inferred(ImageTransformations._getindex(img, @SVector([1,2]))) isa Gray{N0f8}

    etp = @inferred ImageTransformations.box_extrapolation(img)
    etp2 = @inferred ImageTransformations.box_extrapolation(etp.itp)
    @test_nowarn summary(etp2)
    @test size(etp2) == size(img)
    @test eltype(etp2) == eltype(img)
    @test etp2.itp isa Interpolations.BSplineInterpolation
    @test etp2 isa Interpolations.FilledExtrapolation
    @test etp2.fillvalue === Gray{N0f8}(0.0)
    @test etp2.itp === etp.itp

    etp = @inferred ImageTransformations.box_extrapolation(img)
    etp2 = @inferred ImageTransformations.box_extrapolation(etp.itp, fillvalue=Flat())
    @test_nowarn summary(etp2)
    @test size(etp2) == size(img)
    @test eltype(etp2) == eltype(img)
    @test etp2.itp isa Interpolations.BSplineInterpolation
    @test etp2 isa Interpolations.Extrapolation
    @test etp2.et == Flat()
    @test etp2 !== etp
    @test etp2.itp === etp.itp

    etp = @inferred ImageTransformations.box_extrapolation(img, fillvalue=1)
    @test_nowarn summary(etp)
    @test size(etp) == size(img)
    @test eltype(etp) == eltype(img)
    @test etp.itp isa Interpolations.BSplineInterpolation
    @test etp isa Interpolations.FilledExtrapolation
    @test etp.fillvalue === Gray{N0f8}(1.0)
    @test etp.itp.coefs === img

    etp = @inferred ImageTransformations.box_extrapolation(img, fillvalue=Flat())
    @test @inferred(ImageTransformations.box_extrapolation(etp)) === etp
    @test_nowarn summary(etp)
    @test size(etp) == size(img)
    @test eltype(etp) == eltype(img)
    @test etp.itp isa Interpolations.BSplineInterpolation
    @test etp isa Interpolations.Extrapolation
    @test etp.et == Flat()
    @test etp.itp.coefs === img

    etp = @inferred ImageTransformations.box_extrapolation(img, method=Constant())
    @test_nowarn summary(etp)
    @test size(etp) == size(img)
    @test eltype(etp) == eltype(img)
    @test etp.itp.it == BSpline(Constant{Nearest}())
    @test etp isa Interpolations.FilledExtrapolation
    @test etp.itp.coefs === img

    etp = @inferred ImageTransformations.box_extrapolation(img, method=Constant(), fillvalue=Flat())
    @test_nowarn summary(etp)
    @test size(etp) == size(img)
    @test eltype(etp) == eltype(img)
    @test etp.itp.it == BSpline(Constant{Nearest}())
    @test etp isa Interpolations.Extrapolation
    @test etp.et == Flat()
    @test etp.itp.coefs === img

    imgfloat = Float64.(img)
    etp = @inferred ImageTransformations.box_extrapolation(imgfloat, method=Quadratic(Flat(OnGrid())))
    @test_nowarn summary(etp)
    @test size(etp) == size(imgfloat)
    @test eltype(etp) == eltype(imgfloat)
    @test etp.itp.it == BSpline(Quadratic(Flat(OnGrid())))
    @test etp isa Interpolations.FilledExtrapolation

    etp = @inferred ImageTransformations.box_extrapolation(imgfloat, method=Cubic(Flat(OnGrid())), fillvalue=Flat())
    @test_nowarn summary(etp)
    @test size(etp) == size(imgfloat)
    @test eltype(etp) == eltype(imgfloat)
    @test etp.itp.it == BSpline(Cubic(Flat(OnGrid())))
    @test etp isa Interpolations.Extrapolation

    etp = @inferred ImageTransformations.box_extrapolation(imgfloat, method=Lanczos4OpenCV())
    @test_nowarn summary(etp)
    @test size(etp) == size(imgfloat)
    @test eltype(etp) == eltype(imgfloat)
    @test etp.itp.it == Lanczos4OpenCV()
    @test etp isa Interpolations.FilledExtrapolation
end

@testset "AxisAlgorithms.A_ldiv_B_md" begin
    # TODO
end
