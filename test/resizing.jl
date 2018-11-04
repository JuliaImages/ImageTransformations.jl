@testset "Restriction" begin
    A = reshape([UInt16(i) for i = 1:60], 4, 5, 3)
    B = restrict(A, (1,2))
    Btarget = cat(   [  0.96875   4.625   5.96875;
                        2.875    10.5    12.875;
                        1.90625   5.875   6.90625],
                     [  8.46875  14.625  13.46875;
                       17.875    30.5    27.875;
                        9.40625  15.875  14.40625],
                     [ 15.96875  24.625  20.96875;
                       32.875    50.5    42.875;
                       16.90625  25.875  21.90625], dims=3)
    @test B ≈ Btarget
    Argb = reinterpretc(RGB, reinterpret(N0f16, permutedims(A, (3,1,2))))
    B = restrict(Argb)
    Bf = permutedims(reinterpretc(eltype(eltype(B)), B), (2,3,1))
    # isapprox no longer lies, so atol is now serious
    @test isapprox(Bf, Btarget/reinterpret(one(N0f16)), atol=1e-10)
    Argba = reinterpretc(RGBA{N0f16}, reinterpret(N0f16, A))
    B = restrict(Argba)
    @test isapprox(reinterpretc(eltype(eltype(B)), B), restrict(A, (2,3))/reinterpret(one(N0f16)), atol=1e-10)
    A = reshape(1:60, 5, 4, 3)
    B = restrict(A, (1,2,3))
    @test cat(   [  2.6015625   8.71875   6.1171875;
                    4.09375    12.875     8.78125;
                    3.5390625  10.59375   7.0546875],
                 [ 10.1015625  23.71875  13.6171875;
                   14.09375    32.875    18.78125;
                   11.0390625  25.59375  14.5546875], dims=3) ≈ B
    # Issue #395
    img1 = colorview(RGB, fill(0.9, 3, 5, 5))
    img2 = colorview(RGB, fill(N0f8(0.9), 3, 5, 5))
    @test isapprox(channelview(restrict(img1)), channelview(restrict(img2)), rtol=0.01)
    # Non-1 indices
    Ao = OffsetArray(A, (-2,1,0))
    @test parent(@inferred(restrict(Ao, 1))) == restrict(A, 1)
    @test parent(@inferred(restrict(Ao, 2))) == restrict(A, 2)
    @test parent(@inferred(restrict(Ao, (1,2)))) == restrict(A, (1,2))
    # Arrays-of-arrays
    a = Vector{Int}[[3,3,3], [2,1,7],[-11,4,2]]
    @test restrict(a) == Vector{Float64}[[2,3.5/2,6.5/2], [-5,4.5/2,5.5/2]]
    # Images issue #652
    img = testimage("cameraman")
    @test eltype(@inferred(restrict(img))) == Gray{Float32}
    img = testimage("mandrill")
    @test eltype(@inferred(restrict(img))) == RGB{Float32}
    @test eltype(@inferred(restrict(Lab.(img)))) == RGB{Float32}
    img = rand(RGBA{N0f8}, 11, 11)
    @test eltype(@inferred(restrict(img))) == RGBA{Float32}
    @test eltype(@inferred(restrict(LabA.(img)))) == ARGB{Float32}
end

@testset "Image resize" begin
    testcolor = (RGB,Gray)
    testtype = (Float32, Float64, N0f8, N0f16)

    @testset "Interface" begin
        function test_imresize_interface(img, outsz, args...; kargs...)
            img2 = @test_broken @inferred imresize(img, args...; kargs...) # FIXME: @inferred failed
            img2 = @test_nowarn imresize(img, args...; kargs...)
            @test size(img2) == outsz
            @test eltype(img2) == eltype(img)
        end
        for C in testcolor, T in testtype
            img = rand(C{T},10,10)

            test_imresize_interface(img, (5,5), (5,5))
            test_imresize_interface(img, (5,5), (1:5,1:5)) # FIXME: @inferred failed
            test_imresize_interface(img, (5,5), 5,5)
            test_imresize_interface(img, (5,5), 1:5,1:5) # FIXME: @inferred failed
            test_imresize_interface(img, (5,5), ratio = 0.5)
            test_imresize_interface(img, (20,20), ratio = 2)
            test_imresize_interface(img, (10,10), ())
            test_imresize_interface(img, (5,10), 5)
            test_imresize_interface(img, (5,10), (5,))
            test_imresize_interface(img, (5,10), 1:5) # FIXME: @inferred failed
            test_imresize_interface(img, (5,10), (1:5,)) # FIXME: @inferred failed

            @test_throws MethodError imresize(img,5.0,5.0)
            @test_throws MethodError imresize(img,(5.0,5.0))
            @test_throws MethodError imresize(img,(5, 5.0))
            @test_throws MethodError imresize(img,[5,5])
            @test_throws UndefKeywordError imresize(img)
            @test_throws DimensionMismatch imresize(img,(5,5,5))
            @test_throws ArgumentError imresize(img, ratio = -0.5)
            @test_throws DimensionMismatch imresize(img,(5,5,1))
        end
    end

    @testset "Numerical" begin
        # RGB is skipped
        for C in (Gray,), T in testtype
            A = [1 0; 0 1] .|> C{T}
            @test imresize(A, (1, 1)) ≈ reshape([0.5], 1, 1) .|> C{T}
            # if only 1 of 4 pixels is nonzero, check that you get 1/4 the
            # value (no matter where it is)
            for i = 1:4
                fill!(A, 0)
                A[i] = 1
                A = C{T}.(A)
                @test imresize(A, (1, 1)) ≈ reshape([0.25], 1, 1) .|> C{T}
            end
            A = [1 0; 0 0] .|> C{T}
            @test imresize(A, (2, 1)) ≈ reshape([0.5, 0], (2, 1)) .|> C{T}
            @test imresize(A, (1, 2)) ≈ reshape([0.5, 0], (1, 2)) .|> C{T}
            A = [1 0 0; 0 0 0; 0 0 0] .|> C{T}
            @test imresize(A, (2, 2)) ≈ [0.75^2 0; 0 0] .|> C{T}

            A = ones(5,5) .|> C{T}
            for l2 = 3:7, l1 = 3:7
                R = imresize(A, (l1, l2))
                @test all(x->x==1, R)
            end
            for l2 = 3:7, l1 = 3:7
                R = imresize(A, (0:l1-1, 0:l2-1))
                @test all(x->x==1, R)
                @test axes(R) == (0:l1-1, 0:l2-1)
            end
            for l1 = 3:7
                R = imresize(A, (0:l1-1,))
                @test all(x->x==1, R)
                @test axes(R) == (0:l1-1, 1:5)
            end

            R = imresize(A, (2:6, 0:4))
            @test all(x->x==1, R)
            @test axes(R) == (2:6, 0:4)
            R = imresize(A, ())
            @test all(x->x==1, R)
            @test axes(R) == axes(A)
            @test !(R === A)
            Ao = OffsetArray(A, -2:2, 0:4)
            R = imresize(Ao, (5,5))
            @test axes(R) === axes(A)
            R = imresize(Ao, axes(Ao))
            @test axes(R) === axes(Ao)
            @test !(R === A)
            img = reshape([0.5])
            R = imresize(img, ())
            @test ndims(R) == 0
            @test !(R === A)
        end
    end
end
