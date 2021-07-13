# A helper function to let our `method` keyword correctly understands `Degree` inputs.
@inline wrap_BSpline(itp::Interpolations.InterpolationType) = itp
@inline wrap_BSpline(degree::Interpolations.Degree) = BSpline(degree)

# The default values used by extrapolation for off-domain points
const FillType = Union{Number,Colorant,Flat,Periodic,Reflect}
const FloatLike{T<:AbstractFloat} = Union{T,AbstractGray{T}}
const FloatColorant{T<:AbstractFloat} = Colorant{T}
@inline _default_fillvalue(::Type{T}) where {T<:FloatLike} = convert(T, NaN)
@inline _default_fillvalue(::Type{T}) where {T<:FloatColorant} = _nan(T)
@inline _default_fillvalue(::Type{T}) where {T} = zero(T)

@inline _make_compatible(T, fill) = fill
@inline _make_compatible(::Type{T}, fill::Number) where {T} = T(fill)

Interpolations.tweight(A::AbstractArray{C}) where C<:Colorant{T} where T = T

const MethodType = Union{Interpolations.Degree, Interpolations.InterpolationType}

function box_extrapolation(
        parent::AbstractArray;
        fillvalue::FillType = _default_fillvalue(eltype(parent)),
        method=Linear(),
        kwargs...)
    T = typeof(zero(Interpolations.tweight(parent)) * zero(eltype(parent)))
    itp = maybe_skip_prefilter(T, parent, method)
    extrapolate(itp, _make_compatible(T, fillvalue))
end
box_extrapolation(etp::AbstractExtrapolation) = etp
box_extrapolation(itp::AbstractInterpolation{T}; fillvalue=_default_fillvalue(T)) where T =
    extrapolate(itp, _make_compatible(T, fillvalue))

@inline function maybe_skip_prefilter(::Type{T}, A::AbstractArray, degree::D) where {T, D<:Union{Linear, Constant}}
    axs = axes(A)
    return Interpolations.BSplineInterpolation{T,ndims(A),typeof(A),BSpline{D},typeof(axs)}(A, axs, BSpline(degree))
end
@inline function maybe_skip_prefilter(::Type{T}, A::AbstractArray, method::BSpline{D}) where {T, D<:Union{Linear, Constant}}
    maybe_skip_prefilter(T, A, method.degree)
end

@inline function maybe_skip_prefilter(::Type{T}, A::AbstractArray, method::MethodType) where T
    return interpolate(A, wrap_BSpline(method))
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
