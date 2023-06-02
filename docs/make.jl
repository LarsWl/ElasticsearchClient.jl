using Documenter
using ElasticsearchClient

makedocs(
    sitename = "ElasticsearchClient",
    format = Documenter.HTML(),
    modules = [ElasticsearchClient],
    pages = [
        "Home" => "index.md",
        "Transport" => [
            "Client" => "Transport/client.md"
        ], 
        "Api" => [
           "Base Actions" => "Api/index.md",
           "Cat Actions" => "Api/cat.md",
           "Indices Actions" => "Api/indices.md"
        ]
    ]
)

deploydocs(repo = "github.com/OpenSesame/ElasticsearchClient.jl.git")