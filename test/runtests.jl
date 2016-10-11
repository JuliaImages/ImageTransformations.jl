using ImageTransformations, CoordinateTransformations, TestImages, ImageCore, Colors
using Base.Test

img = testimage("camera")
tfm = recenter(RotMatrix(-pi/8), center(img))
imgr = warp(img, tfm)
@test indices(imgr) == (-78:591, -78:591)
# imgr2 = warp(imgr, inv(tfm))   # this will need fixes in Interpolations
# @test imgr2[indices(img)...] ≈ img
