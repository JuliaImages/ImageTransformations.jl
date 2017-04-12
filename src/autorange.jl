function autorange(img, tform)
    R = CartesianRange(indices(img))
    mn = mx = tform(SVector(first(R)))
    for I in CornerIterator(R)
        x = tform(SVector(I))
        # we map min and max to prevent type-inference issues
        # (because min(::SVector,::SVector) -> Vector)
        mn = map(min, x, mn)
        mx = map(max, x, mx)
    end
    _autorange(convert(Tuple, mn), convert(Tuple, mx))
end

@noinline _autorange(mn,mx) = map((a,b)->floor(Int,a):ceil(Int,b), mn, mx)

## Iterate over the corner-indices of a rectangular region
immutable CornerIterator{I<:CartesianIndex}
    start::I
    stop::I
end
CornerIterator{I<:CartesianIndex}(R::CartesianRange{I}) = CornerIterator{I}(first(R), last(R))

eltype{I}(::Type{CornerIterator{I}}) = I
iteratorsize{I}(::Type{CornerIterator{I}}) = Base.HasShape()

# in 0.6 we could write: 1 .+ (iter.stop.I .- iter.start.I .!= 0)
size{N}(iter::CornerIterator{CartesianIndex{N}}) = ntuple(d->iter.stop.I[d]-iter.start.I[d]==0 ? 1 : 2, Val{N})::NTuple{N,Int}
length(iter::CornerIterator) = prod(size(iter))

@inline function start{I<:CartesianIndex}(iter::CornerIterator{I})
    if any(map(>, iter.start.I, iter.stop.I))
        return iter.stop+1
    end
    iter.start
end
@inline function next{I<:CartesianIndex}(iter::CornerIterator{I}, state)
    state, I(inc(state.I, iter.start.I, iter.stop.I))
end
@inline done{I<:CartesianIndex}(iter::CornerIterator{I}, state) = state.I[end] > iter.stop.I[end]

# increment & carry
@inline inc(::Tuple{}, ::Tuple{}, ::Tuple{}) = ()
# the max(1, ...) makes sure that the code doesn't break
# for corner cases where if stop == start
# (e.g. CornerIterator(CartesianRange((1,1))))
@inline inc(state::Tuple{Int}, start::Tuple{Int}, stop::Tuple{Int}) = (state[1]+(max(1,stop[1]-start[1])),)
@inline function inc(state, start, stop)
    if state[1] < stop[1]
        return (stop[1],tail(state)...)
    end
    newtail = inc(tail(state), tail(start), tail(stop))
    (start[1], newtail...)
end

# 0-d is special-cased to iterate once and only once
start{I<:CartesianIndex{0}}(iter::CornerIterator{I}) = false
next{I<:CartesianIndex{0}}(iter::CornerIterator{I}, state) = (iter.start, true)
done{I<:CartesianIndex{0}}(iter::CornerIterator{I}, state) = state
