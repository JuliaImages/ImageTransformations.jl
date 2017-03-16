@testset "compare against old restrict to check for consistency" begin
    for img in (testimage("lena_color_256"),
                testimage("lighthouse"),
                testimage("camera"),
                rand(Float32, 10, 11),
                rand(Float32, 11, 10),
                rand(Float64, 10, 11),
                rand(Float64, 11, 10))
        @test size(restrict(img)) == size(ImageTransformations.restrict_old(img))
        @test restrict(img) ≈ ImageTransformations.restrict_old(img)
        @test typeof(restrict(img)) == typeof(ImageTransformations.restrict_old(img))
    end
end
