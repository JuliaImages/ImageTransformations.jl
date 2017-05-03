# FIXME: upstream https://github.com/JuliaGraphics/ColorVectorSpace.jl/issues/75
@inline _nan(::Type{HSV{Float16}}) = HSV{Float16}(NaN16,NaN16,NaN16)
@inline _nan(::Type{HSV{Float32}}) = HSV{Float32}(NaN32,NaN32,NaN32)
@inline _nan(::Type{HSV{Float64}}) = HSV{Float64}(NaN,NaN,NaN)
@inline _nan{T}(::Type{T}) = nan(T)

# The default values used by extrapolation for off-domain points
@compat const FillType = Union{Number,Colorant,Flat,Periodic,Reflect}
@compat const FloatLike{T<:AbstractFloat} = Union{T,AbstractGray{T}}
@compat const FloatColorant{T<:AbstractFloat} = Colorant{T}
@inline _default_fill{T<:FloatLike}(::Type{T}) = convert(T, NaN)
@inline _default_fill{T<:FloatColorant}(::Type{T}) = _nan(T)
@inline _default_fill{T}(::Type{T}) = zero(T)

box_extrapolation(etp::AbstractExtrapolation) = etp

function box_extrapolation{T}(itp::AbstractInterpolation{T}, fill::FillType = _default_fill(T))
    etp = extrapolate(itp, fill)
    box_extrapolation(etp)
end

function box_extrapolation{T,N,D<:Union{Linear,Constant}}(parent::AbstractArray{T,N}, degree::D = Linear(), args...)
    itp = Interpolations.BSplineInterpolation{T,N,typeof(parent),BSpline{D},OnGrid,0}(parent)
    box_extrapolation(itp, args...)
end

function box_extrapolation{T,N}(parent::AbstractArray{T,N}, degree::Interpolations.Degree, args...)
    itp = interpolate(parent, BSpline(degree), OnGrid())
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
    indsdim = indices(parent(src), dim)
    indsF = indices(F)[2]
    if indsF == indsdim
        AxisAlgorithms.A_ldiv_B_md!(parent(dest), F, parent(src), dim, b)
        return dest
    end
    throw(DimensionMismatch("indices $(indices(parent(src))) do not match $(indices(F))"))
end
