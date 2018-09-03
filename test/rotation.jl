using Test, FixedPointNumbers
const test_types = (Float32, Float64, N0f8, N0f16)

@testset "imrotate" begin
    # imrotate is a wrapper, hence only need to guarantee the interface
    graybar = repeat(range(0,stop=1,length=100),1,100)
    @testset "interface" begin
        for T in test_types
            img = Gray{T}.(graybar)
            @test_nowarn imrotate(img, 45)
            @test_nowarn imrotate(img, 45, method = "nearest")
            @test_nowarn imrotate(img, 45, method = "bilinear")
            @test_nowarn imrotate(img, 45, bbox = "crop")
            @test size(imrotate(img, 45, bbox = "crop")) == size(img)
            @test_nowarn imrotate(img, 45, bbox = "loose")
            @test_nowarn imrotate(img, 45, fill = 0)
        end
    end

    @testset "numerical" begin
        repeats = 50
        for T in test_types[3:4]
            img = Gray{T}.(graybar)
            for i in 1:repeats
                p = 2pi*randn()
                @test imrotate(img,p-2pi) == imrotate(img,p+2pi)
            end
        end
        # FIXME: Floats are not accurate enough due to RotMatrix is not accurate
        for T in test_types[1:2]
            img = Gray{T}.(graybar)
            for i in 1:repeats
                p = 2pi*randn()
                @test_broken imrotate(img,p) ≈ imrotate(img,p)
            end
        end
    end
end
