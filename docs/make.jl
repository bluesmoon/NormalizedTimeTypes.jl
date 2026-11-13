using NormalizedTimeTypes
using Documenter

DocMeta.setdocmeta!(NormalizedTimeTypes, :DocTestSetup, :(using NormalizedTimeTypes); recursive=true)

makedocs(;
    modules=[NormalizedTimeTypes],
    authors="Philip Tellis <philip.tellis@gmail.com>",
    sitename="NormalizedTimeTypes.jl",
    format=Documenter.HTML(;
        canonical="https://bluesmoon.github.io/NormalizedTimeTypes.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/bluesmoon/NormalizedTimeTypes.jl",
    devbranch="main",
)
