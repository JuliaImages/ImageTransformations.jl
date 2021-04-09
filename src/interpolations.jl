# FIXME: upstream https://github.com/JuliaGraphics/ColorVectorSpace.jl/issues/75
@inline _nan(::Type{HSV{Float16}}) = HSV{Float16}(NaN16,NaN16,NaN16)
@inline _nan(::Type{HSV{Float32}}) = HSV{Float32}(NaN32,NaN32,NaN32)
@inline _nan(::Type{HSV{Float64}}) = HSV{Float64}(NaN,NaN,NaN)
@inline _nan(::Type{T}) where {T} = nan(T)

#wraper to deal with degree or interpolation types
@inline wrap_BSpline(itp::Interpolations.InterpolationType) = itp
@inline wrap_BSpline(degree::Interpolations.Degree) = BSpline(degree)

# The default values used by extrapolation for off-domain points
const FillType = Union{Number,Colorant,Flat,Periodic,Reflect}
const FloatLike{T<:AbstractFloat} = Union{T,AbstractGray{T}}
const FloatColorant{T<:AbstractFloat} = Colorant{T}
@inline _default_fill(::Type{T}) where {T<:FloatLike} = convert(T, NaN)
@inline _default_fill(::Type{T}) where {T<:FloatColorant} = _nan(T)
@inline _default_fill(::Type{T}) where {T} = zero(T)

@inline _make_compatible(T, fill) = fill
@inline _make_compatible(::Type{T}, fill::Number) where {T} = T(fill)

Interpolations.tweight(A::AbstractArray{C}) where C<:Colorant{T} where T = T

box_extrapolation(etp::AbstractExtrapolation) = etp

function box_extrapolation(itp::AbstractInterpolation{T}, fill::FillType = _default_fill(T); kwargs...) where T
    etp = extrapolate(itp, _make_compatible(T, fill))
    box_extrapolation(etp)
end

function box_extrapolation(parent::AbstractArray, args...; method::Union{Interpolations.Degree,Interpolations.InterpolationType}=Linear(), kwargs...)
    if typeof(method)<:Interpolations.Degree
        box_extrapolation(parent, method, args...)
    else
        itp = interpolate(parent, method)
        box_extrapolation(itp, args...)
    end
end

function box_extrapolation(parent::AbstractArray{T,N}, degree::Interpolations.Degree, args...; method::Union{Interpolations.Degree,Interpolations.InterpolationType}=Linear(), kwargs...) where {T,N}
    itp = interpolate(parent, BSpline(degree))
    box_extrapolation(itp, args...)
end

function box_extrapolation(parent::AbstractArray, degree::D, args...; method::Union{Interpolations.Degree,Interpolations.InterpolationType}=Linear(), kwargs...) where D<:Union{Linear,Constant}
    axs = axes(parent)
    T = typeof(zero(Interpolations.tweight(parent))*zero(eltype(parent)))
    itp = Interpolations.BSplineInterpolation{T,ndims(parent),typeof(parent),BSpline{D},typeof(axs)}(parent, axs, BSpline(degree))
    box_extrapolation(itp, args...)
end

function box_extrapolation(parent::AbstractArray, fill::FillType; kwargs...)
    box_extrapolation(parent, Linear(), fill)
end

function box_extrapolation(itp::AbstractInterpolation, degree::Union{Linear,Constant}, args...; kwargs...)
    throw(ArgumentError("Boxing an interpolation in another interpolation is discouraged. Did you specify the parameter \"$degree\" on purpose?"))
end

function box_extrapolation(itp::AbstractInterpolation, degree::Interpolations.Degree, args...; kwargs...)
    throw(ArgumentError("Boxing an interpolation in another interpolation is discouraged. Did you specify the parameter \"$degree\" on purpose?"))
end

function box_extrapolation(itp::AbstractExtrapolation, fill::FillType; kwargs...)
    throw(ArgumentError("Boxing an extrapolation in another extrapolation is discouraged. Did you specify the parameter \"$fill\" on purpose?"))
end

function box_extrapolation(parent::AbstractArray, itp::Interpolations.InterpolationType; kwargs...)
    throw(ArgumentError("Argument support for interpolation is not supported. Are you looking for the method keyword to pass an interpolation method?"))
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
