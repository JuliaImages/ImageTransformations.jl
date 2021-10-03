@testset "Swirl Operation" begin
    img = [0 0 0 0 0
           0 0 1 0 0
           0 1 0 0 0
           0 0 1 0 0
           0 0 0 0 0]
    expected = [ NaN NaN       0.0        0.0      NaN
                 0.0 0.431797  0.476449   0.431797 NaN
                 0.0 0.476449  0.0        0.393894 0.0
                 NaN 0.431797  0.0825553  0.0      0.0
                 NaN 0.0       0.0        NaN      NaN]
    res = swirl(img, 1, 10, 1)
    replace!(res, NaN=>0.0)
    replace!(expected, NaN=>0.0)
    @test isapprox(res, expected; atol=0.1)
end