using Documenter, ImageCore, ImageTransformations, ImageShow
using TestImages
using CoordinateTransformations, Interpolations, Rotations

testimage("cameraman") # this is used to trigger artifact download

format = Documenter.HTML(edit_link = "master",
                         prettyurls = get(ENV, "CI", nothing) == "true")

makedocs(modules  = [ImageTransformations],
         format   = format,
         sitename = "ImageTransformations",
         pages    = ["index.md", "reference.md"])

deploydocs(repo   = "github.com/JuliaImages/ImageTransformations.jl.git")
