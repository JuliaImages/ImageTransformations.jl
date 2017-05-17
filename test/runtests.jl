using CoordinateTransformations, TestImages, ImageCore, Colors, FixedPointNumbers, StaticArrays, OffsetArrays, Interpolations
using Base.Test, ImageInTerminal

refambs = detect_ambiguities(CoordinateTransformations, Base, Core)
using ImageTransformations
ambs = detect_ambiguities(ImageTransformations, CoordinateTransformations, Base, Core)
@test isempty(setdiff(ambs, refambs))

reference_path(filename) = joinpath(dirname(@__FILE__), "reference", "$(filename).txt")

function test_reference_impl{T<:Colorant}(filename, img::AbstractArray{T})
    old_color = Base.have_color
    res = try
        eval(Base, :(have_color = true))
        ImageInTerminal.encodeimg(ImageInTerminal.SmallBlocks(), ImageInTerminal.TermColor256(), img, 20, 40)[1]
    finally
        eval(Base, :(have_color = $old_color))
    end
    test_reference_impl(filename, res)
end

function test_reference_impl{T<:String}(filename, actual::AbstractArray{T})
    try
        reference = replace.(readlines(reference_path(filename)), ["\n"], [""])
        try
            @assert reference == actual # to throw error
            @test true # to increase test counter if reached
        catch # test failed
            println("Test for \"$filename\" failed.")
            println("- REFERENCE -------------------")
            println.(reference)
            println("-------------------------------")
            println("- ACTUAL ----------------------")
            println.(actual)
            println("-------------------------------")
            if isinteractive()
                print("Replace reference with actual result? [y/n] ")
                answer = first(readline())
                if answer == 'y'
                    write(reference_path(filename), join(actual, "\n"))
                end
            else
                error("You need to run the tests interactively with 'include(\"test/runtests.jl\")' to update reference images")
            end
        end
    catch ex
        if isa(ex, SystemError) # File doesn't exist
            println("Reference file for \"$filename\" does not exist.")
            println("- NEW CONTENT -----------------")
            println.(actual)
            println("-------------------------------")
            if isinteractive()
                print("Create reference file with above content? [y/n] ")
                answer = first(readline())
                if answer == 'y'
                    write(reference_path(filename), join(actual, "\n"))
                end
            else
                error("You need to run the tests interactively with 'include(\"test/runtests.jl\")' to create new reference images")
            end
        else
            throw(ex)
        end
    end
end

# using a macro looks more consistent
macro test_reference(filename, expr)
    esc(:(test_reference_impl($filename, $expr)))
end

tests = [
    "autorange.jl",
    "resizing.jl",
    "interpolations.jl",
    "warp.jl",
    "deprecations.jl",
]

for t in tests
    @testset "$t" begin
        include(t)
    end
end

nothing
