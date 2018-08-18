#ctqual = "ColorTypes."
ctqual = ""
# fpqual = "FixedPointNumbers."
fpqual = ""

@testset "_default_fill" begin
    @test_throws UndefVarError _default_fill
    @test typeof(ImageTransformations._default_fill) <: Function

    @test @inferred(ImageTransformations._default_fill(N0f8)) === N0f8(0)
    @test @inferred(ImageTransformations._default_fill(Int)) === 0
    @test @inferred(ImageTransformations._default_fill(Float16)) === NaN16
    @test @inferred(ImageTransformations._default_fill(Float32)) === NaN32
    @test @inferred(ImageTransformations._default_fill(Float64)) === NaN

    @test @inferred(ImageTransformations._default_fill(Gray{N0f8})) === Gray{N0f8}(0)
    @test @inferred(ImageTransformations._default_fill(Gray{Float16})) === Gray{Float16}(NaN16)
    @test @inferred(ImageTransformations._default_fill(Gray{Float32})) === Gray{Float32}(NaN32)
    @test @inferred(ImageTransformations._default_fill(Gray{Float64})) === Gray{Float64}(NaN)

    @test @inferred(ImageTransformations._default_fill(GrayA{N0f8})) === GrayA{N0f8}(0,0)
    @test @inferred(ImageTransformations._default_fill(GrayA{Float16})) === GrayA{Float16}(NaN16,NaN16)
    @test @inferred(ImageTransformations._default_fill(GrayA{Float32})) === GrayA{Float32}(NaN32,NaN32)
    @test @inferred(ImageTransformations._default_fill(GrayA{Float64})) === GrayA{Float64}(NaN,NaN)

    @test @inferred(ImageTransformations._default_fill(RGB{N0f8})) === RGB{N0f8}(0,0,0)
    @test @inferred(ImageTransformations._default_fill(RGB{Float16})) === RGB{Float16}(NaN16,NaN16,NaN16)
    @test @inferred(ImageTransformations._default_fill(RGB{Float32})) === RGB{Float32}(NaN32,NaN32,NaN32)
    @test @inferred(ImageTransformations._default_fill(RGB{Float64})) === RGB{Float64}(NaN,NaN,NaN)

    @test @inferred(ImageTransformations._default_fill(RGBA{N0f8})) === RGBA{N0f8}(0,0,0,0)
    @test @inferred(ImageTransformations._default_fill(RGBA{Float16})) === RGBA{Float16}(NaN16,NaN16,NaN16,NaN16)
    @test @inferred(ImageTransformations._default_fill(RGBA{Float32})) === RGBA{Float32}(NaN32,NaN32,NaN32,NaN32)
    @test @inferred(ImageTransformations._default_fill(RGBA{Float64})) === RGBA{Float64}(NaN,NaN,NaN,NaN)

    @test @inferred(ImageTransformations._default_fill(HSV{Float16})) === HSV{Float16}(NaN16,NaN16,NaN16)
    @test @inferred(ImageTransformations._default_fill(HSV{Float32})) === HSV{Float32}(NaN32,NaN32,NaN32)
    @test @inferred(ImageTransformations._default_fill(HSV{Float64})) === HSV{Float64}(NaN,NaN,NaN)
end

@testset "box_extrapolation" begin
    @test_throws UndefVarError box_extrapolation
    @test typeof(ImageTransformations.box_extrapolation) <: Function

    img = rand(Gray{N0f8}, 2, 2)

    etp = @inferred ImageTransformations.box_extrapolation(img)
    @test @inferred(ImageTransformations.box_extrapolation(etp)) === etp
    @test_broken summary(etp) == "2×2 extrapolate(interpolate(::Array{Gray{N0f8},2}, BSpline(Linear()), OnGrid()), Gray{N0f8}(0.0)) with element type $(ctqual)Gray{$(fpqual)Normed{UInt8,8}}"
    @test typeof(etp) <: Interpolations.FilledExtrapolation
    @test etp.fillvalue === Gray{N0f8}(0.0)
    @test etp.itp.coefs === img

    @test_throws ArgumentError ImageTransformations.box_extrapolation(etp, 0)
    @test_throws ArgumentError ImageTransformations.box_extrapolation(etp, Flat())
    @test_throws ArgumentError ImageTransformations.box_extrapolation(etp, Quadratic(Flat()))
    @test_throws ArgumentError ImageTransformations.box_extrapolation(etp, Quadratic(Flat()), Flat())
    @test_throws ArgumentError ImageTransformations.box_extrapolation(etp, Constant())
    @test_throws ArgumentError ImageTransformations.box_extrapolation(etp, Constant(), Flat())
    @test_throws ArgumentError ImageTransformations.box_extrapolation(etp.itp, Constant())
    @test_throws ArgumentError ImageTransformations.box_extrapolation(etp.itp, Constant(), Flat())

    etp2 = @inferred ImageTransformations.box_extrapolation(etp.itp)
    @test_skip summary(etp2) == "2×2 extrapolate(interpolate(::Array{Gray{N0f8},2}, BSpline(Linear()), OnGrid()), Gray{N0f8}(0.0)) with element type $(ctqual)Gray{$(fpqual)Normed{UInt8,8}}"
    @test typeof(etp2) <: Interpolations.FilledExtrapolation
    @test etp2.fillvalue === Gray{N0f8}(0.0)
    @test etp2 !== etp
    @test etp2.itp === etp.itp

    etp2 = @inferred ImageTransformations.box_extrapolation(etp.itp, Flat())
    @test_skip summary(etp2) == "2×2 extrapolate(interpolate(::Array{Gray{N0f8},2}, BSpline(Linear()), OnGrid()), Flat()) with element type $(ctqual)Gray{$(fpqual)Normed{UInt8,8}}"
    @test typeof(etp2) <: Interpolations.Extrapolation
    @test etp2 !== etp
    @test etp2.itp === etp.itp

    etp = @inferred ImageTransformations.box_extrapolation(img, 1)
    @test_skip summary(etp) == "2×2 extrapolate(interpolate(::Array{Gray{N0f8},2}, BSpline(Linear()), OnGrid()), Gray{N0f8}(1.0)) with element type $(ctqual)Gray{$(fpqual)Normed{UInt8,8}}"
    @test typeof(etp) <: Interpolations.FilledExtrapolation
    @test etp.fillvalue === Gray{N0f8}(1.0)
    @test etp.itp.coefs === img

    etp = @inferred ImageTransformations.box_extrapolation(img, Flat())
    @test @inferred(ImageTransformations.box_extrapolation(etp)) === etp
    @test_skip summary(etp) == "2×2 extrapolate(interpolate(::Array{Gray{N0f8},2}, BSpline(Linear()), OnGrid()), Flat()) with element type $(ctqual)Gray{$(fpqual)Normed{UInt8,8}}"
    @test typeof(etp) <: Interpolations.Extrapolation
    @test etp.itp.coefs === img

    etp = @inferred ImageTransformations.box_extrapolation(img, Constant())
    @test_skip summary(etp) == "2×2 extrapolate(interpolate(::Array{Gray{N0f8},2}, BSpline(Constant()), OnGrid()), Gray{N0f8}(0.0)) with element type $(ctqual)Gray{$(fpqual)Normed{UInt8,8}}"
    @test typeof(etp) <: Interpolations.FilledExtrapolation
    @test etp.itp.coefs === img

    etp = @inferred ImageTransformations.box_extrapolation(img, Constant(), Flat())
    @test_skip summary(etp) == "2×2 extrapolate(interpolate(::Array{Gray{N0f8},2}, BSpline(Constant()), OnGrid()), Flat()) with element type $(ctqual)Gray{$(fpqual)Normed{UInt8,8}}"
    @test typeof(etp) <: Interpolations.Extrapolation
    @test etp.itp.coefs === img

    imgfloat = Float64.(img)
    etp = @inferred ImageTransformations.box_extrapolation(imgfloat, Quadratic(Flat()))
    @test typeof(etp) <: Interpolations.FilledExtrapolation
    @test_skip summary(etp) == "2×2 extrapolate(interpolate(::Array{Float64,2}, BSpline(Quadratic(Flat())), OnGrid()), NaN) with element type Float64"

    etp = @inferred ImageTransformations.box_extrapolation(imgfloat, Cubic(Flat()), Flat())
    @test typeof(etp) <: Interpolations.Extrapolation
    @test_skip summary(etp) == "2×2 extrapolate(interpolate(::Array{Float64,2}, BSpline(Cubic(Flat())), OnGrid()), Flat()) with element type Float64"
end

@testset "AxisAlgorithms.A_ldiv_B_md" begin
    # TODO
end
