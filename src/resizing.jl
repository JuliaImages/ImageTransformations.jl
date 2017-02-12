"""
`imgr = restrict(img[, region])` performs two-fold reduction in size
along the dimensions listed in `region`, or all spatial coordinates if
`region` is not specified.  It anti-aliases the image as it goes, so
is better than a naive summation over 2x2 blocks.
"""
restrict(img::AbstractArray, ::Tuple{}) = img

typealias RegionType Union{Dims,Vector{Int}}

function restrict(A::AbstractArray, region::RegionType=coords_spatial(A))
    for dim in region
        A = _restrict(A, dim)
    end
    A
end

function _restrict{T,N}(A::AbstractArray{T,N}, dim::Integer)
    if size(A, dim) <= 2
        return A
    end
    newsz = ntuple(i->i==dim?restrict_size(size(A,dim)):size(A,i), Val{N})
    out = Array{typeof(A[1]/4+A[2]/2),N}(newsz)
    restrict!(out, A, dim)
    out
end

# out should have efficient linear indexing
for N = 1:5
    @eval begin
        function restrict!{T}(out::AbstractArray{T,$N}, A::AbstractArray, dim)
            if isodd(size(A, dim))
                half = convert(eltype(T), 0.5)
                quarter = convert(eltype(T), 0.25)
                indx = 0
                if dim == 1
                    @inbounds @nloops $N i d->(d==1 ? (1:1) : (1:size(A,d))) d->(j_d = d==1 ? i_d+1 : i_d) begin
                        nxt = convert(T, @nref $N A j)
                        out[indx+=1] = half*(@nref $N A i) + quarter*nxt
                        for k = 3:2:size(A,1)-2
                            prv = nxt
                            i_1 = k
                            j_1 = k+1
                            nxt = convert(T, @nref $N A j)
                            out[indx+=1] = quarter*(prv+nxt) + half*(@nref $N A i)
                        end
                        i_1 = size(A,1)
                        out[indx+=1] = quarter*nxt + half*(@nref $N A i)
                    end
                else
                    strd = stride(out, dim)
                    # Must initialize the i_dim==1 entries with zero
                    @nexprs $N d->sz_d=d==dim?1:size(out,d)
                    @nloops $N i d->(1:sz_d) begin
                        (@nref $N out i) = zero(T)
                    end
                    stride_1 = 1
                    @nexprs $N d->(stride_{d+1} = stride_d*size(out,d))
                    @nexprs $N d->offset_d = 0
                    ispeak = true
                    @inbounds @nloops $N i d->(d==1?(1:1):(1:size(A,d))) d->(if d==dim; ispeak=isodd(i_d); offset_{d-1} = offset_d+(div(i_d+1,2)-1)*stride_d; else; offset_{d-1} = offset_d+(i_d-1)*stride_d; end) begin
                        indx = offset_0
                        if ispeak
                            for k = 1:size(A,1)
                                i_1 = k
                                out[indx+=1] += half*(@nref $N A i)
                            end
                        else
                            for k = 1:size(A,1)
                                i_1 = k
                                tmp = quarter*(@nref $N A i)
                                out[indx+=1] += tmp
                                out[indx+strd] = tmp
                            end
                        end
                    end
                end
            else
                threeeighths = convert(eltype(T), 0.375)
                oneeighth = convert(eltype(T), 0.125)
                indx = 0
                if dim == 1
                    z = convert(T, zero(A[1]))
                    @inbounds @nloops $N i d->(d==1 ? (1:1) : (1:size(A,d))) d->(j_d = i_d) begin
                        c = d = z
                        for k = 1:size(out,1)-1
                            a = c
                            b = d
                            j_1 = 2*k
                            i_1 = j_1-1
                            c = convert(T, @nref $N A i)
                            d = convert(T, @nref $N A j)
                            out[indx+=1] = oneeighth*(a+d) + threeeighths*(b+c)
                        end
                        out[indx+=1] = oneeighth*c+threeeighths*d
                    end
                else
                    fill!(out, zero(T))
                    strd = stride(out, dim)
                    stride_1 = 1
                    @nexprs $N d->(stride_{d+1} = stride_d*size(out,d))
                    @nexprs $N d->offset_d = 0
                    peakfirst = true
                    @inbounds @nloops $N i d->(d==1?(1:1):(1:size(A,d))) d->(if d==dim; peakfirst=isodd(i_d); offset_{d-1} = offset_d+(div(i_d+1,2)-1)*stride_d; else; offset_{d-1} = offset_d+(i_d-1)*stride_d; end) begin
                        indx = offset_0
                        if peakfirst
                            for k = 1:size(A,1)
                                i_1 = k
                                tmp = @nref $N A i
                                out[indx+=1] += threeeighths*tmp
                                out[indx+strd] += oneeighth*tmp
                            end
                        else
                            for k = 1:size(A,1)
                                i_1 = k
                                tmp = @nref $N A i
                                out[indx+=1] += oneeighth*tmp
                                out[indx+strd] += threeeighths*tmp
                            end
                        end
                    end
                end
            end
        end
    end
end

restrict_size(len::Integer) = isodd(len) ? (len+1)>>1 : (len>>1)+1

