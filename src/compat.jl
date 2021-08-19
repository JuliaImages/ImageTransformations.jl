# This file includes two kinds of codes
#   - Codes for backward compatibility
#   - Glue codes that might no longer be necessary in the future

@static if VERSION < v"1.1"
    @inline isnothing(x) = x === nothing
end

if hasmethod(nan, Tuple{Type{HSV{Float32},}})
    # requires ColorTypes v0.11 and ColorVectorSpace v0.9.4
    # https://github.com/JuliaGraphics/ColorVectorSpace.jl/issues/75
    @inline _nan(::Type{T}) where T = nan(T)
else
    @inline _nan(::Type{HSV{Float16}}) = HSV{Float16}(NaN16,NaN16,NaN16)
    @inline _nan(::Type{HSV{Float32}}) = HSV{Float32}(NaN32,NaN32,NaN32)
    @inline _nan(::Type{HSV{Float64}}) = HSV{Float64}(NaN,NaN,NaN)
    @inline _nan(::Type{T}) where {T} = nan(T)
end
