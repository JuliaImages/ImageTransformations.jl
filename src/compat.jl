# This file includes two kinds of codes
#   - Codes for backward compatibility
#   - Glue codes that might no longer be necessary in the future

@static if !isdefined(Base, :IdentityUnitRange)
    const IdentityUnitRange = Base.Slice
else
    using Base: IdentityUnitRange
end

@static if VERSION < v"1.1"
    @inline isnothing(x) = x === nothing
end

# FIXME: upstream https://github.com/JuliaGraphics/ColorVectorSpace.jl/issues/75
@inline _nan(::Type{HSV{Float16}}) = HSV{Float16}(NaN16,NaN16,NaN16)
@inline _nan(::Type{HSV{Float32}}) = HSV{Float32}(NaN32,NaN32,NaN32)
@inline _nan(::Type{HSV{Float64}}) = HSV{Float64}(NaN,NaN,NaN)
@inline _nan(::Type{T}) where {T} = nan(T)
