"""
    imrotate(img, angle; fill = NaN, method = "nearest", bbox = "loose") -> imgout

Rotate image `img` by `angle` degrees in a counterclockwise direction around its center point. To rotate the image clockwise, specify a negative value for angle.

# Arguments
- `img::AbstractArray`: image to be rotated
- `angle::Real`: amount of rotation in degrees. The rotation is in counterclockwise direction.
- `fill::Real`: filling value for pixel outside of original image. Defaults: `NaN` if the element type supports it, and `0` otherwise
- `method::String = "nearest"`: the interpolation method used in rotation. Options are "nearest" or "bilinear"
- `bbox::String = "loose"`: the bounding box defines the size of output image. If `bbox = "crop"`, then output image `imgout` are cropped to has the same size of input image `img`. If `bbox = "loose"`, then `imgout` is large enough to contain the entire rotated image; `imgout` is larger than `img`.

See also [`warp`](@ref).
"""
function imrotate(img::AbstractArray{T}, angle::Real; fill = NaN, method::String = "nearest", bbox::String = "loose")::AbstractArray{T} where T

    # FIXME: Bicubic method does not support N0f8 type.
    args = []
    push!(args,
        if method == "nearest"
            Constant()
        elseif method == "bilinear"
            Linear()
        else
            ArgumentError("method should be: nearest, bilinear")
        end)
    if !isnan(fill)
        push!(args, fill)
    end

    rotate_fun(img, tform, args...) =
    if bbox == "loose"
        warp(img, tform, args...)
    elseif bbox == "crop"
        warp(img, tform, axes(img), args...)
    else
        ArgumentError("bbox should be: loose, crop")
    end

    tfm = recenter(RotMatrix{2}(mod2pi(1*angle)), center(img))
    rotate_fun(img, tfm, args...)
end
