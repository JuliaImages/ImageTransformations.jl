import ImageTransformations: warp

# TODO design more tests, esp with color. 

@testset "Conditional tests for warping on GPU" begin #should break this into 2D, 3D, etc.
    #Float32 2D
    x = zeros(Float32, 5,5)
    x[2,2] = 1.0
    x[2,3] = 2.0
    y = convert(CuArray, x)

    tform = AffineMap(RotMatrix(pi/2), [6,0])

    z = warp(y, tform); 
    @test isa(z, OffsetArray{Float32, 2, <:CuArray})
    @test nearlysame(OffsetArray(Array(z.parent), z.offsets),warp(x, tform))

    #Float32 3D
    a = zeros(3,3,3)
    a[1,2,3] = 1.0
    b = CuArray(a)

    tform3DNull = AffineMap(RotXYZ(0,0,0), [0.0,0.0,0.0]);
    c = warp(b, tform3DNull) #3D is broken now. 

    @test nearlysame(warp(a, tform3DNull), OffsetArray(Array(c.parent), c.offsets))

    #introduce offsets
    d = zeros(6,6)
    d[1,2] = 1.0
    e = CuArray(d)

    tform_trans = AffineMap(RotMatrix(0), [1, 2]) #just translation
    f = warp(e, tform_trans); 

    @test nearlysame(warp(d, tform_trans), OffsetArray(Array(f.parent), f.offsets)) #OffsetArrays doesn't work with CuArray

    #Basic rotation
    tform_lin = AffineMap([0 -1; 1 0], [0,0])
    g = warp(e, tform_lin);

    @test nearlysame(warp(d, tform_lin), OffsetArray(Array(g.parent), g.offsets))#OffsetArrays doesn't work with CuArray

    h = OffsetArray(d, -1, 0)
    i = OffsetArray(e, -1, 0);

    #Basic translation
    j = warp(i, tform_trans);
    @test nearlysame(warp(h, tform_trans), OffsetArray(Array(j.parent), j.offsets)) #OffsetArrays doesn't work with CuArray

    #With BSpline Interpolation
    tform_trans_float = AffineMap(RotMatrix(0), [0.1, 0.2])
    k = warp(e, tform_trans_float)

    @test nearlysame(warp(d, tform_trans_float), OffsetArray(Array(k.parent), k.offsets))
    
    tform_lin_float = AffineMap(RotMatrix(pi/4), [0,0])
    l = warp(e, tform_lin_float);

    @test nearlysame(warp(d, tform_lin_float), OffsetArray(Array(l.parent), l.offsets))

    m = rand(3,3,3)
    n = CuArray(m)

    tform3D_complex = AffineMap(RotXYZ(0.1, 0.1, 0.1), [0.3,0.2,0.1])

    o = warp(n, tform3D_complex);

    @test nearlysame(warp(m, tform3D_complex), OffsetArray(Array(o.parent), o.offsets))

end

