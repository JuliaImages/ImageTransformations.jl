@testset "restrict" begin
    img = repeat(range(0, stop=1, length=100), 1, 100)
    tfm = recenter(RotMatrix(pi/8), center(img))

    for wv in [
        WarpedView(img, tfm),
        InvWarpedView(img, tfm)
    ]
        out = restrict(wv)
        ref = restrict(OffsetArray(collect(wv), axes(wv)))
        @test nearlysame(out, ref)
        @test out isa OffsetArray

        for dims in [1, (2, )]
            out = restrict(wv, dims)
            ref = restrict(OffsetArray(collect(wv), axes(wv)), dims)
            @test nearlysame(out, ref)
            @test out isa OffsetArray
        end
    end
end

@testset "Image resize" begin
    testcolor = (RGB,Gray)
    testtype = (Float32, Float64, N0f8, N0f16)

    @testset "Interface" begin
        function test_imresize_interface(src_img, outsz, outinds, args...; kwargs...)
            out = @inferred imresize(src_img, args...; kwargs...)
            @test size(out) == outsz
            @test axes(out) == outinds
            @test eltype(out) == eltype(src_img)
            return out
        end
        for C in testcolor, T in testtype
            img = rand(C{T},10,10)

            @test test_imresize_interface(img, (10,10), (1:10, 1:10), ()) isa Array

            @test test_imresize_interface(img, (5,5), (1:5, 1:5), (5,5)) isa Array
            @test test_imresize_interface(img, (5,5), (1:5, 1:5), 5, 5) isa Array
            @test test_imresize_interface(img, (5,10), (1:5, 1:10), 5) isa Array
            @test test_imresize_interface(img, (5,10), (1:5, 1:10), (5,)) isa Array

            @test test_imresize_interface(img, (5,5), (1:5, 1:5), ratio = 0.5) isa Array
            @test test_imresize_interface(img, (20,20), (1:20, 1:20), ratio = 2) isa Array
            @test test_imresize_interface(img, (20,20), (1:20, 1:20), ratio = (2, 2)) isa Array
            @test test_imresize_interface(img, (20,10), (1:20, 1:10), ratio = (2, 1)) isa Array
            
            # indices method always return OffsetArray
            @test test_imresize_interface(img, (5,5), (1:5, 1:5), (1:5,1:5)) isa OffsetArray
            @test test_imresize_interface(img, (5,5), (1:5, 1:5), 1:5,1:5) isa OffsetArray
            @test test_imresize_interface(img, (5,10), (1:5, 1:10), 1:5) isa OffsetArray
            @test test_imresize_interface(img, (5,10), (1:5, 1:10), (1:5,)) isa OffsetArray

            @test_throws MethodError imresize(img,5.0,5.0)
            @test_throws MethodError imresize(img,(5.0,5.0))
            @test_throws MethodError imresize(img,(5, 5.0))
            @test_throws MethodError imresize(img,[5,5])
            @test_throws UndefKeywordError imresize(img)
            @test_throws DimensionMismatch imresize(img,(5,5,5))
            @test_throws ArgumentError imresize(img, ratio = -0.5)
            @test_throws ArgumentError imresize(img, ratio = (-0.5, 1))
            @test_throws DimensionMismatch imresize(img, ratio=(5,5,5))
            @test_throws DimensionMismatch imresize(img, (5,5,1))
        end

        for C in testcolor, T in testtype
            img = OffsetArray(rand(C{T},10,10), -5, -4)

            @test test_imresize_interface(img, (5,5), (-4:0, -3:1), (5,5)) isa OffsetArray
            @test test_imresize_interface(img, (5,5), (-4:0, -3:1), 5, 5) isa OffsetArray
            @test test_imresize_interface(img, (5,5), (1:5, 1:5), (1:5,1:5)) isa OffsetArray
            @test test_imresize_interface(img, (5,5), (1:5, 1:5), 1:5,1:5) isa OffsetArray
            @test test_imresize_interface(img, (5,5), (-4:0, -3:1), ratio = 0.5) isa OffsetArray
            @test test_imresize_interface(img, (20,20), (-4:15, -3:16), ratio = 2) isa OffsetArray
            @test test_imresize_interface(img, (20,20), (-4:15, -3:16), ratio = (2, 2)) isa OffsetArray
            @test test_imresize_interface(img, (20,10), (-4:15, -3:6), ratio = (2, 1)) isa OffsetArray
            @test test_imresize_interface(img, (10,10), (-4:5, -3:6), ()) isa OffsetArray
            @test test_imresize_interface(img, (5,10), (-4:0, -3:6), 5) isa OffsetArray
            @test test_imresize_interface(img, (5,10), (-4:0, -3:6), (5,)) isa OffsetArray
            @test test_imresize_interface(img, (5,10), (1:5, -3:6), 1:5) isa OffsetArray
            @test test_imresize_interface(img, (5,10), (1:5, -3:6), (1:5,)) isa OffsetArray

            @test_throws MethodError imresize(img,5.0,5.0)
            @test_throws MethodError imresize(img,(5.0,5.0))
            @test_throws MethodError imresize(img,(5, 5.0))
            @test_throws MethodError imresize(img,[5,5])
            @test_throws UndefKeywordError imresize(img)
            @test_throws DimensionMismatch imresize(img,(5,5,5))
            @test_throws ArgumentError imresize(img, ratio = -0.5)
            @test_throws ArgumentError imresize(img, ratio = (-0.5, 1))
            @test_throws DimensionMismatch imresize(img, ratio=(5,5,5))
            @test_throws DimensionMismatch imresize(img, (5,5,1))
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
            @test axes(R) === axes(Ao)
            R = imresize(Ao, axes(Ao))
            @test axes(R) === axes(Ao)
            @test !(R === A)
            img = reshape([0.5])
            R = imresize(img, ())
            @test ndims(R) == 0
            @test !(R === A)
        end

    @testset "Interpolation" begin
        img = rand(16,16)
        out = imresize(img, (128,128), method=Lanczos4OpenCV())
        @test size(out) == (128,128)

        out = imresize(img, (128,128), method=Linear())
        @test size(out) == (128,128)

        out = imresize(img, (16,16), method=Lanczos4OpenCV())
        @test size(out) == (16,16)

        #test default behavior
        @test imresize(img, (128,128)) == imresize(img, (128,128), method=Linear())

        #check error handling
        @test_throws ArgumentError imresize(img, BSpline(Linear()))
        @test_throws ArgumentError imresize(img, Linear())

        #consisency checks
        imgo = OffsetArray(img, -1, -1)
        @test imresize(img, (128, 128), method=Linear()) == OffsetArrays.no_offset_view(imresize(imgo, (128, 128), method=Linear()))
        @test imresize(img, (128, 128), method=BSpline(Linear())) == OffsetArrays.no_offset_view(imresize(imgo, (128, 128), method=BSpline(Linear())))
        @test imresize(img, (128, 128), method=Lanczos4OpenCV()) == OffsetArrays.no_offset_view(imresize(imgo, (128, 128), method=Lanczos4OpenCV()))

        out = imresize(img, (0:127, 0:127), method=Linear())
        @test axes(out) == (0:127, 0:127)
        @test OffsetArrays.no_offset_view(out) == imresize(img, (128, 128), method=Linear())

        out = imresize(img, (0:127, 0:127), method=BSpline(Linear()))
        @test axes(out) == (0:127, 0:127)
        @test OffsetArrays.no_offset_view(out) == imresize(img, (128, 128), method=BSpline(Linear()))

        out = imresize(img, (0:127, 0:127), method=Lanczos4OpenCV())
        @test axes(out) == (0:127, 0:127)
        @test OffsetArrays.no_offset_view(out) == imresize(img, (128, 128), method=Lanczos4OpenCV())
        end
    end

    @testset "special RGB/Gray types (#97)" begin
        ori = repeat(distinguishable_colors(10), inner=(1, 10))
        for T in (
            RGB, BGR, RGBX, XRGB,
            ARGB, RGBA,
            RGB24, ARGB32,
        )
            img = T.(ori)
            out = @inferred imresize(img, ratio=2)
            @test eltype(out) <: T
            ref = imresize(ori, ratio=2)
            @test ref ≈ RGB.(out)
        end
        for T in (Gray, AGray, GrayA, Gray24)
            img = T.(ori)
            out = @inferred imresize(img, ratio=2)
            @test eltype(out) <: T
            ref = imresize(Gray.(ori), ratio=2)
            @test ref ≈ Gray.(out)
        end
    end
end
