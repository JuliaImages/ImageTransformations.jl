"""
    restrict(img[, region]) -> imgr

Reduce the size of `img` by two-fold along the dimensions listed in
`region`, or all spatial coordinates if `region` is not specified.  It
anti-aliases the image as it goes, so is better than a naive summation
over 2x2 blocks.

See also [`imresize`](@ref).
"""
restrict(img::AbstractArray, ::Tuple{}) = img

restrict(A::AbstractArray, region::Vector{Int}) = restrict(A, (region...,))
restrict(A::AbstractArray) = restrict(A, coords_spatial(A))
function restrict(A::AbstractArray, region::Dims)
    restrict(restrict(A, region[1]), Base.tail(region))
end

function restrict(A::AbstractArray{T,N}, dim::Integer) where {T,N}
    indsA = axes(A)
    newinds = ntuple(i->i==dim ? restrict_indices(indsA[dim]) : indsA[i], Val(N))
    out = similar(Array{restrict_eltype(first(A)),N}, newinds)
    restrict!(out, A, dim)
    out
end

restrict_eltype_default(x)          = typeof(x/4 + x/2)
restrict_eltype(x)                  = restrict_eltype_default(x)
restrict_eltype(x::AbstractGray)    = restrict_eltype_default(x)
restrict_eltype(x::AbstractRGB)     = restrict_eltype_default(x)
restrict_eltype(x::Color)           = restrict_eltype_default(convert(RGB, x))
restrict_eltype(x::TransparentGray) = restrict_eltype_default(x)
restrict_eltype(x::TransparentRGB)  = restrict_eltype_default(x)
restrict_eltype(x::Colorant)        = restrict_eltype_default(convert(ARGB, x))

function restrict!(out::AbstractArray{T,N}, A::AbstractArray, dim) where {T,N}
    if dim > N
        return copyto!(out, A)
    end
    indsout, indsA = axes(out), axes(A)
    ndims(out) == ndims(A) || throw(DimensionMismatch("input and output must have the same number of dimensions"))
    for d = 1:length(indsA)
        target = d==dim ? restrict_indices(indsA[d]) : indsA[d]
        indsout[d] == target || error("input and output must have corresponding indices; to be consistent with the input indices,\ndimension $d should be $target, got $(indsout[d])")
    end
    indspre, indspost = indsA[1:dim-1], indsA[dim+1:end]
    _restrict!(out, indsout[dim], A, indspre, indsA[dim], indspost)
end

@generated function _restrict!(out, indout, A,
                               indspre::NTuple{Npre,AbstractUnitRange},
                               indA,
                               indspost::NTuple{Npost,AbstractUnitRange}) where {Npre,Npost}
    Ipre = [Symbol(:ipre_, d) for d = 1:Npre]
    Ipost = [Symbol(:ipost_, d) for d = 1:Npost]
    quote
        $(Expr(:meta, :noinline))
        T = eltype(out)
        if isodd(length(indA))
            half = convert(eltype(T), 0.5)
            quarter = convert(eltype(T), 0.25)
            @nloops $Npost ipost d->indspost[d] begin
                iout = first(indout)
                @nloops $Npre ipre d->indspre[d] begin
                    out[$(Ipre...), iout, $(Ipost...)] = zero(T)
                end
                ispeak = true
                for iA in indA
                    if ispeak
                        @inbounds @nloops $Npre ipre d->indspre[d] begin
                            out[$(Ipre...), iout, $(Ipost...)] +=
                                half*convert(T, A[$(Ipre...), iA, $(Ipost...)])
                        end
                    else
                        @inbounds @nloops $Npre ipre d->indspre[d] begin
                            tmp = quarter*convert(T, A[$(Ipre...), iA, $(Ipost...)])
                            out[$(Ipre...), iout, $(Ipost...)]   += tmp
                            out[$(Ipre...), iout+1, $(Ipost...)] = tmp
                        end
                    end
                    ispeak = !ispeak
                    iout += ispeak
                end
            end
        else
            threeeighths = convert(eltype(T), 0.375)
            oneeighth = convert(eltype(T), 0.125)
            z = zero(T)
            fill!(out, zero(T))
            @nloops $Npost ipost d->indspost[d] begin
                peakfirst = true
                iout = first(indout)
                for iA in indA
                    if peakfirst
                        @inbounds @nloops $Npre ipre d->indspre[d] begin
                            tmp = convert(T, A[$(Ipre...), iA, $(Ipost...)])
                            out[$(Ipre...), iout, $(Ipost...)] += threeeighths*tmp
                            out[$(Ipre...), iout+1, $(Ipost...)] += oneeighth*tmp
                        end
                    else
                        @inbounds @nloops $Npre ipre d->indspre[d] begin
                            tmp = convert(T, A[$(Ipre...), iA, $(Ipost...)])
                            out[$(Ipre...), iout, $(Ipost...)]   += oneeighth*tmp
                            out[$(Ipre...), iout+1, $(Ipost...)] += threeeighths*tmp
                        end
                    end
                    peakfirst = !peakfirst
                    iout += peakfirst
                end
            end
        end
        out
    end
end

# If we're restricting along dimension 1, there are some additional efficiencies possible
@generated function _restrict!(out, indout, A, ::NTuple{0,AbstractUnitRange},
                               indA, indspost::NTuple{Npost,AbstractUnitRange}) where Npost
    Ipost = [Symbol(:ipost_, d) for d = 1:Npost]
    quote
        $(Expr(:meta, :noinline))
        T = eltype(out)
        if isodd(length(indA))
            half = convert(eltype(T), 0.5)
            quarter = convert(eltype(T), 0.25)
            @inbounds @nloops $Npost ipost d->indspost[d] begin
                iout, iA = first(indout), first(indA)
                nxt = convert(T, A[iA+1, $(Ipost...)])
                out[iout, $(Ipost...)] = half*convert(T, A[iA, $(Ipost...)]) + quarter*nxt
                for iA in first(indA)+2:2:last(indA)-2
                    prv = nxt
                    nxt = convert(T, A[iA+1, $(Ipost...)])
                    out[iout+=1, $(Ipost...)] = quarter*(prv+nxt) + half*convert(T, A[iA, $(Ipost...)])
                end
                out[iout+1, $(Ipost...)] = quarter*nxt + half*convert(T, A[last(indA), $(Ipost...)])
            end
        else
            threeeighths = convert(eltype(T), 0.375)
            oneeighth = convert(eltype(T), 0.125)
            z = zero(T)
            @inbounds @nloops $Npost ipost d->indspost[d] begin
                c = d = z
                iA = first(indA)
                for iout = first(indout):last(indout)-1
                    a, b = c, d
                    c, d = convert(T, A[iA, $(Ipost...)]), convert(T, A[iA+1, $(Ipost...)])
                    iA += 2
                    out[iout, $(Ipost...)] = oneeighth*(a+d) + threeeighths*(b+c)
                end
                out[last(indout), $(Ipost...)] = oneeighth*c + threeeighths*d
            end
        end
        out
    end
end

restrict_size(len::Integer) = isodd(len) ? (len+1)>>1 : (len>>1)+1
function restrict_indices(r::OffsetArrays.IdentityUnitRange)
    f, l = first(r), last(r)
    isodd(f) && return (f+1)>>1:restrict_size(l)
    f>>1 : (isodd(l) ? (l+1)>>1 : l>>1)
end
restrict_indices(r::Base.OneTo) = Base.OneTo(restrict_size(length(r)))
function restrict_indices(r::UnitRange)
    f, l = first(r), last(r)
    isodd(f) && return (f+1)>>1:restrict_size(l)
    f>>1 : (isodd(l) ? (l+1)>>1 : l>>1)
end

# imresize
imresize(original::AbstractArray, dim1::T, dimN::T...) where T<:Union{Integer,AbstractUnitRange} = imresize(original, (dim1,dimN...))
function imresize(original::AbstractArray; ratio::Real)
    ratio > 0 || throw(ArgumentError("ratio $ratio should be positive"))
    new_size = ceil.(Int, size(original) .* ratio) # use ceil to avoid 0
    imresize(original, new_size)
end

function imresize(original::AbstractArray, short_size::Union{Indices{M},Dims{M}}) where M
    len_short = length(short_size)
    len_short > ndims(original) && throw(DimensionMismatch("$short_size has too many dimensions for a $(ndims(original))-dimensional array"))
    new_size = ntuple(i -> (i > len_short ? odims(original, i, short_size) : short_size[i]), ndims(original))
    imresize(original, new_size)
end
odims(original, i, short_size::Tuple{Integer,Vararg{Integer}}) = size(original, i)
odims(original, i, short_size::Tuple{}) = axes(original, i)
odims(original, i, short_size) = oftype(first(short_size), axes(original, i))

"""
    imresize(img, sz) -> imgr
    imresize(img, inds) -> imgr
    imresize(img; ratio) -> imgr

Change `img` to be of size `sz` (or to have indices `inds`). If `ratio` is used, then
`sz = ceil(Int, size(img).*ratio)`. This interpolates the values at sub-pixel locations.
If you are shrinking the image, you risk aliasing unless you low-pass filter `img` first.

# Examples
```julia
julia> img = testimage("lena_gray_256") # 256*256
julia> imresize(img, 128, 128) # 128*128
julia> imresize(img, 1:128, 1:128) # 128*128
julia> imresize(img, (128, 128)) # 128*128
julia> imresize(img, (1:128, 1:128)) # 128*128
julia> imresize(img, (1:128, )) # 128*256
julia> imresize(img, 128) # 128*256
julia> imresize(img, ratio = 0.5) # 128*128

σ = map((o,n)->0.75*o/n, size(img), sz)
kern = KernelFactors.gaussian(σ)   # from ImageFiltering
imgr = imresize(imfilter(img, kern, NA()), sz)
```

See also [`restrict`](@ref).
"""
function imresize(original::AbstractArray{T,0}, new_inds::Tuple{}) where T
    Tnew = imresize_type(first(original))
    copyto!(similar(original, Tnew), original)
end

function imresize(original::AbstractArray{T,N}, new_size::Dims{N}) where {T,N}
    Tnew = imresize_type(first(original))
    inds = axes(original)
    if map(length, inds) == new_size
        dest = similar(original, Tnew, new_size)
        if axes(dest) == inds
            copyto!(dest, original)
        else
            copyto!(dest, CartesianIndices(axes(dest)), original, CartesianIndices(inds))
        end
    else
        imresize!(similar(original, Tnew, new_size), original)
    end
end

function imresize(original::AbstractArray{T,N}, new_inds::Indices{N}) where {T,N}
    Tnew = imresize_type(first(original))
    if axes(original) == new_inds
        copyto!(similar(original, Tnew), original)
    else
        imresize!(similar(original, Tnew, new_inds), original)
    end
end

# To choose the output type, rather than forcing everything to
# Float64 by multiplying by 1.0, we exploit the fact that the scale
# changes correspond to integer ratios.  We mimic ratio arithmetic
# without actually using Rational (which risks promoting to a
# Rational type, too slow for image processing).
imresize_type(c::Colorant) = base_colorant_type(c){eltype(imresize_type(Gray(c)))}
imresize_type(c::Gray) = Gray{imresize_type(gray(c))}
imresize_type(c::FixedPoint) = typeof(c)
imresize_type(c) = typeof((c*1)/1)

function imresize!(resized::AbstractArray{T,N}, original::AbstractArray{S,N}) where {T,S,N}
    # FIXME: avoid allocation for interpolation
    itp = interpolate(original, BSpline(Linear()))
    imresize!(resized, itp)
end

function imresize!(resized::AbstractArray{T,N}, original::AbstractInterpolation{S,N}) where {T,S,N}
    # Define the equivalent of an affine transformation for mapping
    # locations in `resized` to the corresponding position in
    # `original`. We take the viewpoint that a pixel at `i, j` is a
    # sensor that *integrates* the intensity over an area spanning
    # `i±0.5, j±0.5` (this is a good model of how a camera pixel
    # actually works). We then map the *outer corners* of the two
    # images to each other, i.e., in typical cases
    #     (0.5, 0.5) -> (0.5, 0.5)  (outer corner, top left)
    #     size(resized)+0.5 -> size(original)+0.5  (outer corner, lower right)
    # This ensures that both images cover exactly the same area.
    Ro, Rr = CartesianIndices(axes(original)), CartesianIndices(axes(resized))
    sf = map(/, (last(Ro)-first(Ro)).I .+ 1, (last(Rr)-first(Rr)).I .+ 1) # +1 for outer corners
    offset = map((io,ir,s)->io - 0.5 - s*(ir-0.5), first(Ro).I, first(Rr).I, sf)
    if all(x->x >= 1, sf)
        @inbounds for I in Rr
            I_o = map3((i,s,off)->s*i+off, I.I, sf, offset)
            resized[I] = original(I_o...)
        end
    else
        @inbounds for I in Rr
            I_o = clampR(map3((i,s,off)->s*i+off, I.I, sf, offset), Ro)
            resized[I] = original(I_o...)
        end
    end
    resized
end

# map isn't optimized for 3 tuple-arguments, so do it here
@inline map3(f, a, b, c) = (f(a[1], b[1], c[1]), map3(f, tail(a), tail(b), tail(c))...)
@inline map3(f, ::Tuple{}, ::Tuple{}, ::Tuple{}) = ()

function clampR(I::NTuple{N}, R::CartesianIndices{N}) where N
    map3(clamp, I, first(R).I, last(R).I)
end
