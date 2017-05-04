info("Start of deprecation warnings")

img_camera = testimage("camera")
tfm = recenter(RotMatrix(-pi/8), center(img_camera))
imgr = @inferred(ImageTransformations.warp_old(img_camera, tfm))
@test eltype(imgr) == eltype(img_camera)
@test_reference "warp_cameraman_rotate_r22deg" imgr
