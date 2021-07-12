using Documenter, DemoCards
using ImageBase, ImageTransformations, ImageShow
using TestImages
using CoordinateTransformations, Interpolations, Rotations

# this is used to trigger artifact download and IO backend precompilation
testimage.(["cameraman", "lighthouse"])

examples, postprocess_cb, examples_assets = makedemos("examples")
format = Documenter.HTML(edit_link = "master",
                         prettyurls = get(ENV, "CI", nothing) == "true",
                         assets = [examples_assets,])

makedocs(modules  = [ImageTransformations, ImageBase],
         format   = format,
         sitename = "ImageTransformations",
         pages    = [
             "index.md",
             examples,
             "reference.md"])

postprocess_cb()

deploydocs(repo   = "github.com/JuliaImages/ImageTransformations.jl.git")
