@testset "_default_fill" begin
    @test_throws UndefVarError _default_fill
    @test typeof(ImageTransformations._default_fill) <: Function
    import ImageTransformations._default_fill

    @test @inferred(_default_fill(N0f8)) === N0f8(0)
    @test @inferred(_default_fill(Int)) === 0
    @test @inferred(_default_fill(Float16)) === NaN16
    @test @inferred(_default_fill(Float32)) === NaN32
    @test @inferred(_default_fill(Float64)) === NaN

    @test @inferred(_default_fill(Gray{N0f8})) === Gray{N0f8}(0)
    @test @inferred(_default_fill(Gray{Float16})) === Gray{Float16}(NaN16)
    @test @inferred(_default_fill(Gray{Float32})) === Gray{Float32}(NaN32)
    @test @inferred(_default_fill(Gray{Float64})) === Gray{Float64}(NaN)

    @test @inferred(_default_fill(GrayA{N0f8})) === GrayA{N0f8}(0,0)
    @test @inferred(_default_fill(GrayA{Float16})) === GrayA{Float16}(NaN16,NaN16)
    @test @inferred(_default_fill(GrayA{Float32})) === GrayA{Float32}(NaN32,NaN32)
    @test @inferred(_default_fill(GrayA{Float64})) === GrayA{Float64}(NaN,NaN)

    @test @inferred(_default_fill(RGB{N0f8})) === RGB{N0f8}(0,0,0)
    @test @inferred(_default_fill(RGB{Float16})) === RGB{Float16}(NaN16,NaN16,NaN16)
    @test @inferred(_default_fill(RGB{Float32})) === RGB{Float32}(NaN32,NaN32,NaN32)
    @test @inferred(_default_fill(RGB{Float64})) === RGB{Float64}(NaN,NaN,NaN)

    @test @inferred(_default_fill(RGBA{N0f8})) === RGBA{N0f8}(0,0,0,0)
    @test @inferred(_default_fill(RGBA{Float16})) === RGBA{Float16}(NaN16,NaN16,NaN16,NaN16)
    @test @inferred(_default_fill(RGBA{Float32})) === RGBA{Float32}(NaN32,NaN32,NaN32,NaN32)
    @test @inferred(_default_fill(RGBA{Float64})) === RGBA{Float64}(NaN,NaN,NaN,NaN)

    @test @inferred(_default_fill(HSV{Float16})) === HSV{Float16}(NaN16,NaN16,NaN16)
    @test @inferred(_default_fill(HSV{Float32})) === HSV{Float32}(NaN32,NaN32,NaN32)
    @test @inferred(_default_fill(HSV{Float64})) === HSV{Float64}(NaN,NaN,NaN)
end

@testset "_box_extrapolation" begin
    @test_throws UndefVarError _box_extrapolation
    @test typeof(ImageTransformations._box_extrapolation) <: Function
    import ImageTransformations._box_extrapolation

    img = rand(Gray{N0f8}, 2, 2)

    etp = @inferred _box_extrapolation(img)
    @test @inferred(_box_extrapolation(etp)) === etp
    @test summary(etp) == "2×2 extrapolate(interpolate(::Array{Gray{N0f8},2}, BSpline(Linear()), OnGrid()), Gray{N0f8}(0.0)) with element type ColorTypes.Gray{FixedPointNumbers.Normed{UInt8,8}}"
    @test typeof(etp) <: Interpolations.FilledExtrapolation
    @test etp.fillvalue === Gray{N0f8}(0.0)
    @test etp.itp.coefs === img

    etp2 = @inferred _box_extrapolation(etp.itp)
    @test summary(etp2) == "2×2 extrapolate(interpolate(::Array{Gray{N0f8},2}, BSpline(Linear()), OnGrid()), Gray{N0f8}(0.0)) with element type ColorTypes.Gray{FixedPointNumbers.Normed{UInt8,8}}"
    @test typeof(etp2) <: Interpolations.FilledExtrapolation
    @test etp2.fillvalue === Gray{N0f8}(0.0)
    @test etp2 !== etp
    @test etp2.itp === etp.itp

    etp2 = @inferred _box_extrapolation(etp.itp, Flat())
    @test summary(etp2) == "2×2 extrapolate(interpolate(::Array{Gray{N0f8},2}, BSpline(Linear()), OnGrid()), Flat()) with element type ColorTypes.Gray{FixedPointNumbers.Normed{UInt8,8}}"
    @test typeof(etp2) <: Interpolations.Extrapolation
    @test etp2 !== etp
    @test etp2.itp === etp.itp

    etp = @inferred _box_extrapolation(img, 1)
    @test summary(etp) == "2×2 extrapolate(interpolate(::Array{Gray{N0f8},2}, BSpline(Linear()), OnGrid()), Gray{N0f8}(1.0)) with element type ColorTypes.Gray{FixedPointNumbers.Normed{UInt8,8}}"
    @test typeof(etp) <: Interpolations.FilledExtrapolation
    @test etp.fillvalue === Gray{N0f8}(1.0)
    @test etp.itp.coefs === img

    etp = @inferred _box_extrapolation(img, Flat())
    @test @inferred(_box_extrapolation(etp)) === etp
    @test summary(etp) == "2×2 extrapolate(interpolate(::Array{Gray{N0f8},2}, BSpline(Linear()), OnGrid()), Flat()) with element type ColorTypes.Gray{FixedPointNumbers.Normed{UInt8,8}}"
    @test typeof(etp) <: Interpolations.Extrapolation
    @test etp.itp.coefs === img

    etp = @inferred _box_extrapolation(img, Constant())
    @test summary(etp) == "2×2 extrapolate(interpolate(::Array{Gray{N0f8},2}, BSpline(Constant()), OnGrid()), Gray{N0f8}(0.0)) with element type ColorTypes.Gray{FixedPointNumbers.Normed{UInt8,8}}"
    @test typeof(etp) <: Interpolations.FilledExtrapolation
    @test etp.itp.coefs === img

    etp = @inferred _box_extrapolation(img, Constant(), Flat())
    @test summary(etp) == "2×2 extrapolate(interpolate(::Array{Gray{N0f8},2}, BSpline(Constant()), OnGrid()), Flat()) with element type ColorTypes.Gray{FixedPointNumbers.Normed{UInt8,8}}"
    @test typeof(etp) <: Interpolations.Extrapolation
    @test etp.itp.coefs === img
end

@testset "AxisAlgorithms.A_ldiv_B_md" begin
    # TODO
end
