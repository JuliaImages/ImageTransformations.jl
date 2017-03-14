@testset "CornerIterator" begin
    # check that CornerIterator is not exported
    @test_throws UndefVarError CornerIterator

    # test interface and behaviour under normal circumstances
    # (i.e. without any singleton array dimension of size 1)
    si(num::Number) = 1
    ei(num::Number) = num
    si(num::Range)  = minimum(num)
    ei(num::Range)  = maximum(num)
    for t in ((2,), (2,3), (2,3,4), (2,3,4,5),        # OneTo
              (-1:2,), (-1:2,-2:3), (-1:2,-2:3,-3:4)) # Non OneTo
        N = length(t)
        @testset "$N-d array without singleton dimension" begin
            cr = CartesianRange(t)
            ci = @inferred(ImageTransformations.CornerIterator(cr))
            @test typeof(ci) <: ImageTransformations.CornerIterator{CartesianIndex{N}}
            @test ci.start === cr.start
            @test ci.stop === cr.stop
            @test @inferred(eltype(ci)) === CartesianIndex{N}
            @test @inferred(size(ci)) === ntuple(x->2, N)
            @test @inferred(length(ci)) === 2^N
            # Check for correct shape and values
            A = @inferred(collect(ci))
            @test typeof(A) <: Array{CartesianIndex{N},N}
            if N == 1
                @test A == [CartesianIndex{1}((si(t[1]),)), CartesianIndex{1}((ei(t[1]),))]
            elseif N == 2
                @test A == [
                    CartesianIndex{2}((si(t[1]),si(t[2])))  CartesianIndex{2}((si(t[1]),ei(t[2])));
                    CartesianIndex{2}((ei(t[1]),si(t[2])))  CartesianIndex{2}((ei(t[1]),ei(t[2])));
                ]
            elseif N == 3
                for (i,v) in zip(1:2,[si(t[3]),ei(t[3])])
                    @test A[:,:,i] == [
                        CartesianIndex{3}((si(t[1]),si(t[2]),v))  CartesianIndex{3}((si(t[1]),ei(t[2]),v));
                        CartesianIndex{3}((ei(t[1]),si(t[2]),v))  CartesianIndex{3}((ei(t[1]),ei(t[2]),v));
                    ]
                end
            elseif N == 4
                for (i2,v2) in zip(1:2,[si(t[4]),ei(t[4])])
                    for (i1,v1) in zip(1:2,[si(t[3]),ei(t[3])])
                        @test A[:,:,i1,i2] == [
                            CartesianIndex{4}((si(t[1]),si(t[2]),v1,v2))  CartesianIndex{4}((si(t[1]),ei(t[2]),v1,v2));
                            CartesianIndex{4}((ei(t[1]),si(t[2]),v1,v2))  CartesianIndex{4}((ei(t[1]),ei(t[2]),v1,v2));
                        ]
                    end
                end
            else
                error("This code must be unreached")
            end
        end
    end

    @testset "0-element and 1-element edge cases" begin
        for t in ((),(1,),(1,1),(1,1,1))
            N = length(t)
            cr = CartesianRange(t)
            ci = @inferred(ImageTransformations.CornerIterator(cr))
            @test ci.start === cr.start
            @test ci.stop === cr.stop
            @test @inferred(collect(ci)) == collect(cr)
            @test @inferred(size(ci)) === t
            @test @inferred(length(ci)) === 1
            @test length(collect(ci)) === 1
            @test typeof(collect(ci)) <: Array{CartesianIndex{N},N}
            @test all(collect(ci) .== [CartesianIndex{N}(t)])
        end
    end

    @testset "arrays with singleton dimensions" begin
        cr = CartesianRange((1,3))
        ci = @inferred(ImageTransformations.CornerIterator(cr))
        @test ci.start === cr.start
        @test ci.stop === cr.stop
        @test @inferred(size(ci)) === (1,2)
        @test @inferred(length(ci)) === 2
        @test length(@inferred(collect(ci))) === 2
        @test typeof(collect(ci)) <: Array{CartesianIndex{2},2}
        @test collect(ci) == [
            CartesianIndex{2}((1,1)) CartesianIndex{2}((1,3))
        ]
        # two singleton dimensions
        cr = CartesianRange((1,3,1,3))
        ci = @inferred(ImageTransformations.CornerIterator(cr))
        @test ci.start === cr.start
        @test ci.stop === cr.stop
        @test @inferred(size(ci)) === (1,2,1,2)
        @test @inferred(length(ci)) === 4
        @test length(@inferred(collect(ci))) === 4
        @test typeof(collect(ci)) <: Array{CartesianIndex{4},4}
        @test size(collect(ci)) === (1,2,1,2)
        @test collect(ci)[1,:,1,:] == [
            CartesianIndex{4}((1,1,1,1)) CartesianIndex{4}((1,1,1,3));
            CartesianIndex{4}((1,3,1,1)) CartesianIndex{4}((1,3,1,3))
        ]
    end
end
