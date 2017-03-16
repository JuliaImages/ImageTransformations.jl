"""
    restrict(img[, region]) -> imgr

Reduce the size of `img` by two-fold along the dimensions listed in
`region`, or all spatial coordinates if `region` is not specified.  It
anti-aliases the image as it goes, so is better than a naive summation
over 2x2 blocks.

See also [`imresize`](@ref).
"""
restrict(img::AbstractArray, ::Tuple{}) = img

function restrict(A::AbstractArray, region::Union{Dims,Vector{Int}} = coords_spatial(A))
    for dim in region
        A = restrict(A, dim)
    end
    A
end

function restrict{T,N}(A::AbstractArray{T,N}, dim::Integer)
    if size(A, dim) <= 2
        return A
    end
    newsz = ntuple(i->i==dim?restrict_size(size(A,dim)):size(A,i), Val{N})
    # FIXME: The following line fails for interpolations because
    # interpolations can not be accessed linearily A[i].
    #    out = Array{typeof(A[1]/4+A[2]/2),N}(newsz)
    out = Array{typeof(first(A)/4+first(A)/2),N}(newsz)
    restrict!(out, A, dim)
    out
end

function restrict!{T,S,N}(out::AbstractArray{T,N}, A::AbstractArray{S}, dim)
    # one_d is a tuple in which all elements are 0 expect for "dim"
    #   e.g. for N=4 and dim=3: one_d=CartesianIndex((0,0,1,0))
    one_d = CartesianIndex{N}(ntuple(d->d==dim?1:0, Val{N})::NTuple{N,Int})
    # mlp is a tuple of multiplier in which all elements are 1 expect for "dim"
    #   e.g. for N=4 and dim=3: mlp=(1,1,2,1)
    mlp = ntuple(d->d==dim?2:1, Val{N})::NTuple{N,Int}
    inds = indices(out)
    min_d, max_d = extrema(inds[dim])
    if isodd(length(indices(A,dim)))
        half    = convert(eltype(T), 0.5)
        quarter = convert(eltype(T), 0.25)
        @inbounds for O in CartesianRange(inds)
            # compute corresponding index in A
            I = CartesianIndex{N}(map(*, O.I, mlp)) - one_d
            if O[dim] == min_d
                # edge case: beginning
                out[O] = half    * convert(T, A[I]) +
                         quarter * convert(T, A[I+one_d])
            elseif O[dim] == max_d
                # edge case: end
                out[O] = quarter * convert(T, A[I-one_d]) +
                         half    * convert(T, A[I])
            else
                # 1/4 prev_pixel + 1/2 center_pixel + 1/4 next_pixel
                out[O] = quarter * convert(T, A[I-one_d]) +
                         half    * convert(T, A[I]) +
                         quarter * convert(T, A[I+one_d])
            end
        end
    else
        threeeighths = convert(eltype(T), 0.375)
        oneeighth    = convert(eltype(T), 0.125)
        @inbounds for O in CartesianRange(inds)
            # compute corresponding index in A
            I = CartesianIndex{N}(map(*, O.I, mlp)) - one_d
            if O[dim] == min_d
                # edge case: beginning
                out[O] = threeeighths * convert(T, A[I]) +
                         oneeighth    * convert(T, A[I+one_d])
            elseif O[dim] == max_d
                # edge case: end
                out[O] = threeeighths * convert(T, A[I-one_d]) +
                         oneeighth    * convert(T, A[I-2one_d])
            else
                #
                out[O] = oneeighth    * convert(T, A[I-2one_d]) +
                         threeeighths * convert(T, A[I-one_d]) +
                         threeeighths * convert(T, A[I]) +
                         oneeighth    * convert(T, A[I+one_d])
            end
        end
    end
    out
end

restrict_size(len::Integer) = isodd(len) ? (len+1)>>1 : (len>>1)+1

# imresize
imresize(original::AbstractArray, dim1, dimN...) = imresize(original, (dim1,dimN...))

function imresize{T,N}(original::AbstractArray{T,N}, short_size::NTuple)
    len_short = length(short_size)
    new_size = ntuple(i -> (i > len_short ? size(original,i) : short_size[i]), N)
    imresize(original, new_size)
end

"""
    imresize(img, sz) -> imgr

Change `img` to be of size `sz`. This interpolates the values at
sub-pixel locations. If you are shrinking the image, you risk aliasing
unless you low-pass filter `img` first. For example:

    σ = map((o,n)->0.75*o/n, size(img), sz)
    kern = KernelFactors.gaussian(σ)   # from ImageFiltering
    imgr = imresize(imfilter(img, kern, NA()), sz)

See also [`restrict`](@ref).
"""
function imresize{T,N}(original::AbstractArray{T,N}, new_size::NTuple{N})
    Tnew = imresize_type(first(original))
    if size(original) == new_size
        copy!(similar(original, Tnew), original)
    else
        imresize!(similar(original, Tnew, new_size), original)
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

function imresize!{T,S,N}(resized::AbstractArray{T,N}, original::AbstractArray{S,N})
    itp = interpolate(original, BSpline(Linear()), OnGrid())
    imresize!(resized, itp)
end

function imresize!{T,S,N}(resized::AbstractArray{T,N}, original::AbstractInterpolation{S,N})
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
    Ro, Rr = CartesianRange(indices(original)), CartesianRange(indices(resized))
    sf = map(/, (last(Ro)-first(Ro)+1).I, (last(Rr)-first(Rr)+1).I) # +1 for outer corners
    offset = map((io,ir,s)->io - 0.5 - s*(ir-0.5), first(Ro).I, first(Rr).I, sf)
    if all(x->x >= 1, sf)
        @inbounds for I in Rr
            I_o = map3((i,s,off)->s*i+off, I.I, sf, offset)
            resized[I] = original[I_o...]
        end
    else
        @inbounds for I in Rr
            I_o = clampR(map3((i,s,off)->s*i+off, I.I, sf, offset), Ro)
            resized[I] = original[I_o...]
        end
    end
    resized
end

# map isn't optimized for 3 tuple-arguments, so do it here
@inline map3(f, a, b, c) = (f(a[1], b[1], c[1]), map3(f, tail(a), tail(b), tail(c))...)
@inline map3(f, ::Tuple{}, ::Tuple{}, ::Tuple{}) = ()

function clampR{N}(I::NTuple{N}, R::CartesianRange{CartesianIndex{N}})
    map3(clamp, I, first(R).I, last(R).I)
end
