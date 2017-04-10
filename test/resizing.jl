@testset "Restriction" begin
    A = reshape([convert(UInt16, i) for i = 1:60], 4, 5, 3)
    B = restrict(A, (1,2))
    Btarget = cat(3, [  0.96875   4.625   5.96875;
                        2.875    10.5    12.875;
                        1.90625   5.875   6.90625],
                     [  8.46875  14.625  13.46875;
                       17.875    30.5    27.875;
                        9.40625  15.875  14.40625],
                     [ 15.96875  24.625  20.96875;
                       32.875    50.5    42.875;
                       16.90625  25.875  21.90625])
    @test B ≈ Btarget
    Argb = reinterpret(RGB, reinterpret(N0f16, permutedims(A, (3,1,2))))
    B = restrict(Argb)
    Bf = permutedims(reinterpret(eltype(eltype(B)), B), (2,3,1))
    @test isapprox(Bf, Btarget/reinterpret(one(N0f16)), atol=1e-12)
    Argba = reinterpret(RGBA{N0f16}, reinterpret(N0f16, A))
    B = restrict(Argba)
    @test isapprox(reinterpret(eltype(eltype(B)), B), restrict(A, (2,3))/reinterpret(one(N0f16)), atol=1e-12)
    A = reshape(1:60, 5, 4, 3)
    B = restrict(A, (1,2,3))
    @test cat(3, [  2.6015625   8.71875   6.1171875;
                    4.09375    12.875     8.78125;
                    3.5390625  10.59375   7.0546875],
                 [ 10.1015625  23.71875  13.6171875;
                   14.09375    32.875    18.78125;
                   11.0390625  25.59375  14.5546875]) ≈ B
    # Issue #395
    img1 = colorview(RGB, fill(0.9, 3, 5, 5))
    img2 = colorview(RGB, fill(N0f8(0.9), 3, 5, 5))
    @test isapprox(channelview(restrict(img1)), channelview(restrict(img2)), rtol=0.01)
end

@testset "Image resize" begin
    img = zeros(10,10)
    img2 = @inferred(imresize(img, (5,5)))
    @test length(img2) == 25
    img = rand(RGB{Float32}, 10, 10)
    img2 = imresize(img, (6,7))
    @test size(img2) == (6,7)
    @test eltype(img2) == RGB{Float32}

    A = [1 0; 0 1]
    @test imresize(A, (1, 1)) ≈ reshape([0.5], 1, 1)
    # if only 1 of 4 pixels is nonzero, check that you get 1/4 the
    # value (no matter where it is)
    for i = 1:4
        fill!(A, 0)
        A[i] = 1
        @test imresize(A, (1, 1)) ≈ reshape([0.25], 1, 1)
    end
    A = [1 0; 0 0]
    @test imresize(A, (2, 1)) ≈ reshape([0.5, 0], (2, 1))
    @test imresize(A, (1, 2)) ≈ reshape([0.5, 0], (1, 2))
    A = [1 0 0; 0 0 0; 0 0 0]
    @test imresize(A, (2, 2)) ≈ [0.75^2 0; 0 0]

    A = Gray{N0f8}[1 0; 0 0]
    R = imresize(A, (1, 1))
    @test eltype(R) == Gray{N0f8} && R[1,1] == Gray(N0f8(0.25f0))
    @test gray.(imresize(A, (2, 1))) ≈ reshape([N0f8(0.5f0), 0], (2, 1))
    @test gray.(imresize(A, (1, 2))) ≈ reshape([N0f8(0.5f0), 0], (1, 2))

    A = ones(5,5)
    for l2 = 3:7, l1 = 3:7
        R = imresize(A, (l1, l2))
        @test all(x->x==1, R)
    end
end
