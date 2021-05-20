# This file includes two kinds of codes
#   - Codes for backward compatibility
#   - Glue codes that might nolonger be necessary in the future

# patch for issue #110
if isdefined(Base, :ComposedFunction) # Julia >= 1.6.0-DEV.85
    # https://github.com/JuliaLang/julia/pull/37517
    _round(tform::ComposedFunction; kwargs...) = _round(tform.outer; kwargs...) ∘ _round(tform.inner; kwargs...)
end

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

if !hasmethod(Constant{Nearest}, ())
    # `Constant{Nearest}()` is not defined for Interpolations <= v0.13.2
    # https://github.com/JuliaMath/Interpolations.jl/pull/426
    construct_interpolation_type(::Type{T}) where T<:Union{Linear, Constant} = T()
    construct_interpolation_type(::Type{Constant{Nearest}}) = Constant()
else
    construct_interpolation_type(::Type{T}) where T<:Union{Linear, Constant} = T()
end
