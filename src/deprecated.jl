# BEGIN 0.9 deprecations

@deprecate warp(img::AbstractArray, tform::Transformation,       method::MethodType,                      ) warp(img, tform; method=method)
@deprecate warp(img::AbstractArray, tform::Transformation,                             fillvalue::FillType) warp(img, tform; fillvalue=fillvalue)
@deprecate warp(img::AbstractArray, tform::Transformation,       method::MethodType,   fillvalue::FillType) warp(img, tform; method=method, fillvalue=fillvalue)
@deprecate warp(img::AbstractArray, tform::Transformation,       fillvalue::FillType,   method::MethodType) warp(img, tform; method=method, fillvalue=fillvalue)
@deprecate warp(img::AbstractArray, tform::Transformation, inds, method::MethodType,                      ) warp(img, tform, inds; method=method)
@deprecate warp(img::AbstractArray, tform::Transformation, inds,                       fillvalue::FillType) warp(img, tform, inds; fillvalue=fillvalue)
@deprecate warp(img::AbstractArray, tform::Transformation, inds, method::MethodType,   fillvalue::FillType) warp(img, tform, inds; method=method, fillvalue=fillvalue)
@deprecate warp(img::AbstractArray, tform::Transformation, inds, fillvalue::FillType,   method::MethodType) warp(img, tform, inds; method=method, fillvalue=fillvalue)

@deprecate imrotate(img::AbstractArray, θ::Real,       method::MethodType                     )  imrotate(img, θ;       method=method)
@deprecate imrotate(img::AbstractArray, θ::Real,                           fillvalue::FillType)  imrotate(img, θ;       fillvalue=fillvalue)
@deprecate imrotate(img::AbstractArray, θ::Real,       method::MethodType, fillvalue::FillType)  imrotate(img, θ; method=method, fillvalue=fillvalue)
@deprecate imrotate(img::AbstractArray, θ::Real,       fillvalue::FillType, method::MethodType)  imrotate(img, θ; method=method, fillvalue=fillvalue)
@deprecate imrotate(img::AbstractArray, θ::Real, inds, method::MethodType                     )  imrotate(img, θ, inds; method=method)
@deprecate imrotate(img::AbstractArray, θ::Real, inds,                     fillvalue::FillType)  imrotate(img, θ, inds; fillvalue=fillvalue)
@deprecate imrotate(img::AbstractArray, θ::Real, inds, method::MethodType, fillvalue::FillType)  imrotate(img, θ, inds; method=method, fillvalue=fillvalue)
@deprecate imrotate(img::AbstractArray, θ::Real, inds, fillvalue::FillType, method::MethodType)  imrotate(img, θ, inds; method=method, fillvalue=fillvalue)

@deprecate WarpedView(img::AbstractArray, tform::Transformation,       method::MethodType,                      ) WarpedView(img, tform; method=method)
@deprecate WarpedView(img::AbstractArray, tform::Transformation,                             fillvalue::FillType) WarpedView(img, tform; fillvalue=fillvalue)
@deprecate WarpedView(img::AbstractArray, tform::Transformation,       method::MethodType,   fillvalue::FillType) WarpedView(img, tform; method=method, fillvalue=fillvalue)
@deprecate WarpedView(img::AbstractArray, tform::Transformation,       fillvalue::FillType,   method::MethodType) WarpedView(img, tform; method=method, fillvalue=fillvalue)
@deprecate WarpedView(img::AbstractArray, tform::Transformation, inds, method::MethodType,                      ) WarpedView(img, tform, inds; method=method)
@deprecate WarpedView(img::AbstractArray, tform::Transformation, inds,                       fillvalue::FillType) WarpedView(img, tform, inds; fillvalue=fillvalue)
@deprecate WarpedView(img::AbstractArray, tform::Transformation, inds, method::MethodType,   fillvalue::FillType) WarpedView(img, tform, inds; method=method, fillvalue=fillvalue)
@deprecate WarpedView(img::AbstractArray, tform::Transformation, inds, fillvalue::FillType,   method::MethodType) WarpedView(img, tform, inds; method=method, fillvalue=fillvalue)

@deprecate warpedview(args...; kwargs...) WarpedView(args...; kwargs...)

@deprecate invwarpedview(img::AbstractArray, tinv::Transformation,       method::MethodType,                      ) invwarpedview(img, tinv; method=method)
@deprecate invwarpedview(img::AbstractArray, tinv::Transformation,                             fillvalue::FillType) invwarpedview(img, tinv; fillvalue=fillvalue)
@deprecate invwarpedview(img::AbstractArray, tinv::Transformation,       method::MethodType,   fillvalue::FillType) invwarpedview(img, tinv; method=method, fillvalue=fillvalue)
@deprecate invwarpedview(img::AbstractArray, tinv::Transformation,       fillvalue::FillType,   method::MethodType) invwarpedview(img, tinv; method=method, fillvalue=fillvalue)
@deprecate invwarpedview(img::AbstractArray, tinv::Transformation, inds, method::MethodType,                      ) invwarpedview(img, tinv, inds; method=method)
@deprecate invwarpedview(img::AbstractArray, tinv::Transformation, inds,                       fillvalue::FillType) invwarpedview(img, tinv, inds; fillvalue=fillvalue)
@deprecate invwarpedview(img::AbstractArray, tinv::Transformation, inds, method::MethodType,   fillvalue::FillType) invwarpedview(img, tinv, inds; method=method, fillvalue=fillvalue)
@deprecate invwarpedview(img::AbstractArray, tinv::Transformation, inds, fillvalue::FillType,   method::MethodType) invwarpedview(img, tinv, inds; method=method, fillvalue=fillvalue)

# END 0.9 deprecations
