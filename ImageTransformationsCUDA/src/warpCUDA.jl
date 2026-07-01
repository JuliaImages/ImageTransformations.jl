using LinearAlgebra

using ImageTransformations: warp, warp!
# @Tim should I import warp and warp! instead, or continue using the ImageTransformation.warp syntax for clarity
using ImageTransformations: autorange, try_static


function ImageTransformations.warp(img::Union{CuArray{T,N},OffsetArray{T,N,<:CuArray}}, tform, inds::Tuple = autorange(img, inv(tform))) where {T, N}
    out = OffsetArray(CuArray{T}(undef, map(length, inds)), inds); #Can't make CuArray of OffsetArray
    warp!(out, img, try_static(tform, img))
end 

function ImageTransformations.warp!(out, img::OffsetArray{T,N,<:CuArray}, tform) where {T,N}
    warp!(out, img.parent, tform, img.offsets)
end

function ImageTransformations.warp!(out, img::CuArray{T,N}, tform, in_offsets = ntuple(i->0, N)) where {T,N} #why is this now unstable?!
    img_inds = map(out->out.I, CartesianIndices(axes(out.parent))) 
    tform_offset = offset_calc(out, in_offsets, tform)

    tformindex = CuArray(tform_offset.(SVector.(img_inds))) 
    # TODO write an extra function here that converts tformindex to CartesianIndices if possible.
    # return tformindex, out.offsets, T #for checking

    return out = OffsetArray(access_value.(Ref(img), tformindex, T), out.offsets...)
end 

#calculates translation array with input and output offset stripped off. 
#tform(xi + Δxi) = xo + Δxo
#tform.linear(xi) + tform(Δxi) - Δxo = xo
#tform2(xi) = (tform.linear, (tform(Δxi) - Δxo))(xi) = xo
function offset_calc(out::OffsetArray{T,N,<:CuArray}, in_offsets, tform) where {T,N} # doesn't work for 3D!
    in_translation = AffineMap(I, -1 .*[in_offsets...]) #diagm(ones(T, N))
    out_translation = AffineMap(I, [out.offsets...])
    return in_translation∘tform∘out_translation
end 
