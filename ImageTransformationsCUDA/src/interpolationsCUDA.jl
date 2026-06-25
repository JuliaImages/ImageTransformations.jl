using ImageTransformations: _default_fillvalue

#Julia has heuristics for deciding on when it's no longer worth specializing. "I" forces julia to specialize in the full tuple type of inds. 
function access_value(img::C, inds::I, ::Type{T}) where {T,C, I<:Union{Tuple,SVector}} #Getting the wrong type for T because broadcasting over Ref(img) doesn't return a concrete type. 

    inds_upper = ceil.(Int, Tuple(inds))
    inds_lower = floor.(Int, Tuple(inds))

    return checkbounds(Bool, img, inds_upper...) && checkbounds(Bool, img, inds_lower...) ? recursive_bspline(SVector(inds...), img, T) : _default_fillvalue(T) #this line doesn't work because of potential type instability
end 

#No need to interpolate on CartesianIndices. Seems to be type unstable?
function access_value(img::C, inds::CartesianIndex, ::Type{T}) where {T,C} #Getting the wrong type for T because broadcasting over Ref(img) doesn't return a concrete type. 
    return checkbounds(Bool, img, inds) ? T(img[inds]) : _default_fillvalue(T) #this line doesn't work because of potential type instability
end 

_getweights(ind::T) where {T} = (1+floor(ind)-ind, ind -floor(ind)) #this returns 0,0 for whole numbers when it needs to return 1, 0 

_weightcalc(w::Tuple{T,T}, a::Tuple{S,S}) where{T,S} = sum(w.*a) 

_getinds(ind::T) where {T} = (floor(ind), ceil(ind))



"""
BSpline(Linear()) interpolation for CUDA

    recursive_bspline(inds::SVector, img, ::Type) = weighted interpolation value 

"""
function recursive_bspline(ind_list::SVector{N, S}, a::AbstractArray, ::Type{T}) where {N, S, T} #this only works if you cut down the array to the correct 2x2x2 window!

    ind = last(ind_list)
    a_1 = viewdim(a,floor(Int, ind))
    
    if ind == floor(ind)
        return T(recursive_bspline(pop(ind_list), a_1, T))
    else
        a_2 = viewdim(a,(floor(Int, ind)+1))
        weights = _getweights(ind)
        return T(weights[1]*recursive_bspline(pop(ind_list), a_1, T) + weights[2]*recursive_bspline(pop(ind_list), a_2, T))
    end
end

function recursive_bspline(weightlist::SVector{0, S}, a::AbstractArray, ::Type{T}) where {S, T}
    return a[1] #type
end

viewdim(a::AbstractArray{T,3}, ind) where{T} = view(a, :, :, ind)
viewdim(a::AbstractArray{T,2}, ind) where{T} = view(a, :, ind)
viewdim(a::AbstractArray{T,1}, ind) where{T} = view(a, ind)


#What if I adjusted this to do the BSpline Function without needing recursion?
# using Interpolations
# using Interpolations: padded_similar, copy_with_padding

# function Interpolations.copy_with_padding(::Type{TC}, A::CuArray, it::Interpolations.DimSpec{Interpolations.InterpolationType}) where {TC}
#     indsA = axes(A)
#     indspad = Interpolations.padded_axes(indsA, it)
#     coefs = padded_similar(TC, indspad, A)
#     if indspad == indsA
#         coefs = copyto!(coefs, A)
#     else
#         fill!(coefs, zero(TC))
#         Interpolations.ct!(coefs, indsA, A, indsA)
#     end
#     coefs
# end

# Interpolations.padded_similar(::Type{TC}, inds::Tuple{Vararg{Base.OneTo{Int}}}, A::CuArray) where TC = CuArray{TC}(undef, length.(inds))

#this is working out to be a lot more trouble than it's worth I have no idea why get_index doesn't work here

# I don't even know where to begin here. I guess GPU indexing doesn't work?
