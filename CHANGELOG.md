# ImageTransformations

## Version `v0.9.3`

- ![Bugfix][badge-bugfix] Do not modify original image when resizing. ([#151][github-151])

## Version `v0.9.2`

- ![Enhancement][badge-enhancement] The in-place version of resize function `imresize!` is optimized and exported. ([#150][github-150])

## Version `v0.9.1`

- ![Enhancement][badge-enhancement] angles in `imrotate` are processed with high precision, restoring it to the same behavior you'd get from a manually-constructed
  `tform` supplied to `warp`. This can change the presence/absence of padding on the edges. ([#148][github-148], [#149][github-149])

## Version `v0.9.0`

This release contains numerous enhancements as well as quite a few deprecations. There are also
internal changes that may cause small numerical differences from previous versions; these may be
most obvious at the borders of the image, where decisions about inbounds/out-of-bounds can determine
whether a "fill-value" is used instead of interpolation.

- ![BREAKING][badge-breaking] Previously, `SubArray` passed to `invwarpedview` will use out-of-domain values to build a better result on the border. This violated the array abstraction and has therefore been removed. ([#138][github-138])
- ![BREAKING][badge-breaking] Rounding for numerical stability in `warp` is now applied to the corner points instead of to the transformation coefficients. ([#143][github-143])
- ![Deprecation][badge-deprecation] `degree` and `fill` arguments are deprecated in favor of their keyword versions `method` and `fillvalue`. ([#116][github-116])
- ![Deprecation][badge-deprecation] `invwarpedview` is deprecated in favor of `InvWarpedView`. ([#116][github-116], [#138][github-138])
- ![Deprecation][badge-deprecation] `warpedview` is deprecated in favor of `WarpedView`. ([#116][github-116])
- ![Enhancement][badge-enhancement] `restrict`/`restrict!` are moved to more lightweight package [ImageBase.jl]. ([#127][github-127])
- ![Enhancement][badge-enhancement] `imresize` now works on transparent colorant types(e.g., `ARGB`). ([#126][github-126])
- ![Enhancement][badge-enhancement] `restrict` now works on 0-argument colorant types(e.g., `ARGB32`). ([ImageBase#3][github-base-3])
- ![Bugfix][badge-bugfix] Interpolations v0.13.3 compatibility (though 0.13.4 is now required). ([#132][github-132])
- ![Bugfix][badge-bugfix] `restrict` on singleton dimension is now a no-op. ([ImageBase#8][github-base-8])
- ![Bugfix][badge-bugfix] `restrict` on `OffsetArray` always returns an `OffsetArray` result. ([ImageBase#4][github-base-4])


[github-151]: https://github.com/JuliaImages/ImageTransformations.jl/pull/151
[github-150]: https://github.com/JuliaImages/ImageTransformations.jl/pull/150
[github-149]: https://github.com/JuliaImages/ImageTransformations.jl/pull/149
[github-148]: https://github.com/JuliaImages/ImageTransformations.jl/pull/148
[github-143]: https://github.com/JuliaImages/ImageTransformations.jl/pull/143
[github-138]: https://github.com/JuliaImages/ImageTransformations.jl/pull/138
[github-132]: https://github.com/JuliaImages/ImageTransformations.jl/pull/132
[github-127]: https://github.com/JuliaImages/ImageTransformations.jl/pull/127
[github-126]: https://github.com/JuliaImages/ImageTransformations.jl/pull/126
[github-116]: https://github.com/JuliaImages/ImageTransformations.jl/pull/116
[github-base-8]: https://github.com/JuliaImages/ImageBase.jl/pull/8
[github-base-4]: https://github.com/JuliaImages/ImageBase.jl/pull/4
[github-base-3]: https://github.com/JuliaImages/ImageBase.jl/pull/3


[ImageBase.jl]: https://github.com/JuliaImages/ImageBase.jl


[badge-breaking]: https://img.shields.io/badge/BREAKING-red.svg
[badge-deprecation]: https://img.shields.io/badge/deprecation-orange.svg
[badge-feature]: https://img.shields.io/badge/feature-green.svg
[badge-enhancement]: https://img.shields.io/badge/enhancement-blue.svg
[badge-bugfix]: https://img.shields.io/badge/bugfix-purple.svg
[badge-security]: https://img.shields.io/badge/security-black.svg
[badge-experimental]: https://img.shields.io/badge/experimental-lightgrey.svg
[badge-maintenance]: https://img.shields.io/badge/maintenance-gray.svg

<!--
# Badges

![BREAKING][badge-breaking]
![Deprecation][badge-deprecation]
![Feature][badge-feature]
![Enhancement][badge-enhancement]
![Bugfix][badge-bugfix]
![Security][badge-security]
![Experimental][badge-experimental]
![Maintenance][badge-maintenance]
-->
