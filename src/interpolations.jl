# FIXME: upstream https://github.com/JuliaGraphics/ColorVectorSpace.jl/issues/75
@inline _nan(::Type{HSV{Float16}}) = HSV{Float16}(NaN16,NaN16,NaN16)
@inline _nan(::Type{HSV{Float32}}) = HSV{Float32}(NaN32,NaN32,NaN32)
@inline _nan(::Type{HSV{Float64}}) = HSV{Float64}(NaN,NaN,NaN)
@inline _nan(::Type{T}) where {T} = nan(T)

# The default values used by extrapolation for off-domain points
const FillType = Union{Number,Colorant,Flat,Periodic,Reflect}
const FloatLike{T<:AbstractFloat} = Union{T,AbstractGray{T}}
const FloatColorant{T<:AbstractFloat} = Colorant{T}
@inline _default_fill(::Type{T}) where {T<:FloatLike} = convert(T, NaN)
@inline _default_fill(::Type{T}) where {T<:FloatColorant} = _nan(T)
@inline _default_fill(::Type{T}) where {T} = zero(T)

@inline _make_compatible(T, fill) = fill
@inline _make_compatible(::Type{T}, fill::Number) where {T} = T(fill)

box_extrapolation(etp::AbstractExtrapolation) = etp

function box_extrapolation(itp::AbstractInterpolation{T}, fill::FillType = _default_fill(T)) where T
    etp = extrapolate(itp, _make_compatible(T, fill))
    box_extrapolation(etp)
end

function box_extrapolation(parent::AbstractArray{T,N}, degree::D = Linear(), args...) where {T,N,D<:Union{Linear,Constant}}
    axs = axes(parent)
    itp = Interpolations.BSplineInterpolation{T,N,typeof(parent),BSpline{D},typeof(axs)}(parent, axs, BSpline(degree))
    box_extrapolation(itp, args...)
end

function box_extrapolation(parent::AbstractArray{T,N}, degree::Interpolations.Degree, args...) where {T,N}
    itp = interpolate(parent, BSpline(degree))
    box_extrapolation(itp, args...)
end

function box_extrapolation(parent::AbstractArray, fill::FillType)
    box_extrapolation(parent, Linear(), fill)
end

function box_extrapolation(itp::AbstractInterpolation, degree::Union{Linear,Constant}, args...)
    throw(ArgumentError("Boxing an interpolation in another interpolation is discouraged. Did you specify the parameter \"$degree\" on purpose?"))
end

function box_extrapolation(itp::AbstractInterpolation, degree::Interpolations.Degree, args...)
    throw(ArgumentError("Boxing an interpolation in another interpolation is discouraged. Did you specify the parameter \"$degree\" on purpose?"))
end

function box_extrapolation(itp::AbstractExtrapolation, fill::FillType)
    throw(ArgumentError("Boxing an extrapolation in another extrapolation is discouraged. Did you specify the parameter \"$fill\" on purpose?"))
end

# This is type-piracy, but necessary if we want Interpolations to be
# independent of OffsetArrays.
function AxisAlgorithms.A_ldiv_B_md!(dest::OffsetArray, F, src::OffsetArray, dim::Integer, b::AbstractVector)
    indsdim = axes(parent(src), dim)
    indsF = axes(F)[2]
    if indsF == indsdim
        AxisAlgorithms.A_ldiv_B_md!(parent(dest), F, parent(src), dim, b)
        return dest
    end
    throw(DimensionMismatch("indices $(axes(parent(src))) do not match $(axes(F))"))
end
