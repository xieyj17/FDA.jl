using FDA
using Documenter

makedocs(;
    modules=[FDA],
    authors="Yijun Xie",
    repo="https://github.com/xieyj17/FDA.jl/blob/{commit}{path}#L{line}",
    sitename="FDA.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://xieyj17.github.io/FDA.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/xieyj17/FDA.jl",
)
