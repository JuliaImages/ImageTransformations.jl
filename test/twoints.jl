struct TwoInts
    dim1::Int
    dim2::Int
end

Base.length(::TwoInts) = 2
Base.iterate(ti::TwoInts) = ti.dim1, false
function Base.iterate(ti::TwoInts, isdone::Bool)
    isdone && return nothing
    return ti.dim2, true
end

Base.:(-)(ti::TwoInts) = TwoInts(-ti.dim1, -ti.dim2)
Base.:(+)(v::SVector{2}, ti::TwoInts) = TwoInts(v[1] + ti.dim1, v[2] + ti.dim2)
