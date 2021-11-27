using Documenter, GameOne
using Literate
using LibGit2

docspath=@__DIR__
out_path = joinpath(docspath, "src", "examples")
rm(joinpath(docspath, "goexamples"); force=true, recursive=true)
rm(out_path; force=true, recursive=true )

cd(docspath) do 
    LibGit2.clone("https://github.com/dustyirwin/GOExamples", "goexamples")
end

config = Dict{Any, Any}("documenter"=>false, "execute"=>false, "credit"=>false)
config["repo_root_url"] = "https://github.com/SquidSinker/GOExamples"
config["repo_root_path"] = "goexamples"

Literate.markdown(joinpath(docspath, "..", "example", "BasicGame", "basic.jl"), out_path; config=config)

makedocs(;
    modules=[GameOne],
    format=Documenter.HTML(),
    pages=[
        "Home" => "index.md",
        "Examples" => Any[
            "Basic Game 1" => "examples/basic.md",
        ],
        "API" => "api.md"
    ],
    sitename="GameOne.jl",
    authors="Dustin Irwin"
)

