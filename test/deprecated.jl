using ImageTransformations: box_extrapolation

@testset "deprecations" begin
    @info "deprecation warnings are expected"

    @testset "imrotate" begin
        # deprecate potionsal arguments in favor of keyword arguments
        img = repeat(range(0,stop=1,length=100), 1, 100)

        @test nearlysame(imrotate(img, π/4, Constant()),                imrotate(img, π/4, method=Constant()))
        @test nearlysame(imrotate(img, π/4, Constant(), 1),             imrotate(img, π/4, method=Constant(), fillvalue=1))
        @test nearlysame(imrotate(img, π/4, 1, Constant()),             imrotate(img, π/4, method=Constant(), fillvalue=1))
        @test nearlysame(imrotate(img, π/4, 1),                         imrotate(img, π/4, fillvalue=1))
        @test nearlysame(imrotate(img, π/4, Periodic()),                imrotate(img, π/4, fillvalue=Periodic()))

        @test nearlysame(imrotate(img, π/4, axes(img), Constant()),     imrotate(img, π/4, axes(img), method=Constant()))
        @test nearlysame(imrotate(img, π/4, axes(img), Constant(), 1),  imrotate(img, π/4, axes(img), method=Constant(), fillvalue=1))
        @test nearlysame(imrotate(img, π/4, axes(img), 1, Constant()),  imrotate(img, π/4, axes(img), method=Constant(), fillvalue=1))
        @test nearlysame(imrotate(img, π/4, axes(img), 1),              imrotate(img, π/4, axes(img), fillvalue=1))
        @test nearlysame(imrotate(img, π/4, axes(img), Periodic()),     imrotate(img, π/4, axes(img), fillvalue=Periodic()))
    end

    @testset "warp" begin
        # deprecate potionsal arguments in favor of keyword arguments
        img = repeat(range(0,stop=1,length=100), 1, 100)
        tfm = recenter(RotMatrix(pi/8), center(img))

        @test nearlysame(warp(img, tfm, Constant()),                warp(img, tfm, method=Constant()))
        @test nearlysame(warp(img, tfm, Constant(), 1),             warp(img, tfm, method=Constant(), fillvalue=1))
        @test nearlysame(warp(img, tfm, 1, Constant()),             warp(img, tfm, method=Constant(), fillvalue=1))
        @test nearlysame(warp(img, tfm, 1),                         warp(img, tfm, fillvalue=1))
        @test nearlysame(warp(img, tfm, Periodic()),                warp(img, tfm, fillvalue=Periodic()))

        @test nearlysame(warp(img, tfm, axes(img), Constant()),     warp(img, tfm, axes(img), method=Constant()))
        @test nearlysame(warp(img, tfm, axes(img), Constant(), 1),  warp(img, tfm, axes(img), method=Constant(), fillvalue=1))
        @test nearlysame(warp(img, tfm, axes(img), 1, Constant()),  warp(img, tfm, axes(img), method=Constant(), fillvalue=1))
        @test nearlysame(warp(img, tfm, axes(img), 1),              warp(img, tfm, axes(img), fillvalue=1))
        @test nearlysame(warp(img, tfm, axes(img), Periodic()),     warp(img, tfm, axes(img), fillvalue=Periodic()))
    end

    @testset "warpedview" begin
        # deprecate `warpedview` in favor of `WarpedView`
        img = repeat(range(0,stop=1,length=100), 1, 100)
        tfm = recenter(RotMatrix(pi/8), center(img))

        @test nearlysame(warpedview(img, tfm, Constant()),                WarpedView(img, tfm, method=Constant()))
        @test nearlysame(warpedview(img, tfm, Constant(), 1),             WarpedView(img, tfm, method=Constant(), fillvalue=1))
        @test nearlysame(warpedview(img, tfm, 1, Constant()),             WarpedView(img, tfm, method=Constant(), fillvalue=1))
        @test nearlysame(warpedview(img, tfm, 1),                         WarpedView(img, tfm, fillvalue=1))
        @test nearlysame(warpedview(img, tfm, Periodic()),                WarpedView(img, tfm, fillvalue=Periodic()))

        @test nearlysame(warpedview(img, tfm, axes(img), Constant()),     WarpedView(img, tfm, axes(img), method=Constant()))
        @test nearlysame(warpedview(img, tfm, axes(img), Constant(), 1),  WarpedView(img, tfm, axes(img), method=Constant(), fillvalue=1))
        @test nearlysame(warpedview(img, tfm, axes(img), 1, Constant()),  WarpedView(img, tfm, axes(img), method=Constant(), fillvalue=1))
        @test nearlysame(warpedview(img, tfm, axes(img), 1),              WarpedView(img, tfm, axes(img), fillvalue=1))
        @test nearlysame(warpedview(img, tfm, axes(img), Periodic()),     WarpedView(img, tfm, axes(img), fillvalue=Periodic()))
    end

    @testset "WarpedView" begin
        # deprecate potionsal arguments in favor of keyword arguments
        img = repeat(range(0,stop=1,length=100), 1, 100)
        tfm = recenter(RotMatrix(pi/8), center(img))

        @test nearlysame(WarpedView(img, tfm, Constant()),                WarpedView(img, tfm, method=Constant()))
        @test nearlysame(WarpedView(img, tfm, Constant(), 1),             WarpedView(img, tfm, method=Constant(), fillvalue=1))
        @test nearlysame(WarpedView(img, tfm, 1, Constant()),             WarpedView(img, tfm, method=Constant(), fillvalue=1))
        @test nearlysame(WarpedView(img, tfm, 1),                         WarpedView(img, tfm, fillvalue=1))
        @test nearlysame(WarpedView(img, tfm, Periodic()),                WarpedView(img, tfm, fillvalue=Periodic()))

        @test nearlysame(WarpedView(img, tfm, axes(img), Constant()),     WarpedView(img, tfm, axes(img), method=Constant()))
        @test nearlysame(WarpedView(img, tfm, axes(img), Constant(), 1),  WarpedView(img, tfm, axes(img), method=Constant(), fillvalue=1))
        @test nearlysame(WarpedView(img, tfm, axes(img), 1, Constant()),  WarpedView(img, tfm, axes(img), method=Constant(), fillvalue=1))
        @test nearlysame(WarpedView(img, tfm, axes(img), 1),              WarpedView(img, tfm, axes(img), fillvalue=1))
        @test nearlysame(WarpedView(img, tfm, axes(img), Periodic()),     WarpedView(img, tfm, axes(img), fillvalue=Periodic()))
    end

    @testset "invwarpedview" begin
        # deprecate potionsal arguments in favor of keyword arguments
        img = repeat(range(0,stop=1,length=100), 1, 100)
        tfm = recenter(RotMatrix(pi/8), center(img))
        
        @test nearlysame(invwarpedview(img, tfm, Constant()),                InvWarpedView(box_extrapolation(img; method=Constant()), tfm))
        @test nearlysame(invwarpedview(img, tfm, Constant(), 1),             InvWarpedView(box_extrapolation(img; method=Constant(), fillvalue=1), tfm))
        @test nearlysame(invwarpedview(img, tfm, 1, Constant()),             InvWarpedView(box_extrapolation(img; method=Constant(), fillvalue=1), tfm))
        @test nearlysame(invwarpedview(img, tfm, 1),                         InvWarpedView(box_extrapolation(img; fillvalue=1), tfm))
        @test nearlysame(invwarpedview(img, tfm, Periodic()),                InvWarpedView(box_extrapolation(img; fillvalue=Periodic()), tfm))

        @test nearlysame(InvWarpedView(img, tfm, Constant()),                InvWarpedView(img, tfm; method=Constant()))
        @test nearlysame(InvWarpedView(img, tfm, Constant(), 1),             InvWarpedView(img, tfm; method=Constant(), fillvalue=1))
        @test nearlysame(InvWarpedView(img, tfm, 1, Constant()),             InvWarpedView(img, tfm; method=Constant(), fillvalue=1))
        @test nearlysame(InvWarpedView(img, tfm, 1),                         InvWarpedView(img, tfm; fillvalue=1))
        @test nearlysame(InvWarpedView(img, tfm, Periodic()),                InvWarpedView(img, tfm; fillvalue=Periodic()))

        @test nearlysame(invwarpedview(img, tfm, axes(img), Constant()),                InvWarpedView(box_extrapolation(img; method=Constant()), tfm, axes(img)))
        @test nearlysame(invwarpedview(img, tfm, axes(img), Constant(), 1),             InvWarpedView(box_extrapolation(img; method=Constant(), fillvalue=1), tfm, axes(img)))
        @test nearlysame(invwarpedview(img, tfm, axes(img), 1, Constant()),             InvWarpedView(box_extrapolation(img; method=Constant(), fillvalue=1), tfm, axes(img)))
        @test nearlysame(invwarpedview(img, tfm, axes(img), 1),                         InvWarpedView(box_extrapolation(img; fillvalue=1), tfm, axes(img)))
        @test nearlysame(invwarpedview(img, tfm, axes(img), Periodic()),                InvWarpedView(box_extrapolation(img; fillvalue=Periodic()), tfm, axes(img)))

        @test nearlysame(InvWarpedView(img, tfm, axes(img), Constant()),                InvWarpedView(img, tfm, axes(img); method=Constant()))
        @test nearlysame(InvWarpedView(img, tfm, axes(img), Constant(), 1),             InvWarpedView(img, tfm, axes(img); method=Constant(), fillvalue=1))
        @test nearlysame(InvWarpedView(img, tfm, axes(img), 1, Constant()),             InvWarpedView(img, tfm, axes(img); method=Constant(), fillvalue=1))
        @test nearlysame(InvWarpedView(img, tfm, axes(img), 1),                         InvWarpedView(img, tfm, axes(img); fillvalue=1))
        @test nearlysame(InvWarpedView(img, tfm, axes(img), Periodic()),                InvWarpedView(img, tfm, axes(img); fillvalue=Periodic()))
    end
end
