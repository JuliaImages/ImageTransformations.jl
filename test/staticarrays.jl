@testset "StaticArrays" begin
    # ComposedFunction (issue #110)
    M = SMatrix{3,3}([1 0 0; 0 1 0; -1/1000 0 1])
    push1(x) = push(x, 1)
    tfm = PerspectiveMap() ∘ inv(LinearMap(M)) ∘ push1
    tst_img = zeros(5, 5)
    @test ImageTransformations.autorange(tst_img, tfm) == (0:5, 0:5)
end
