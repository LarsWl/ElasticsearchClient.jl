using Documenter
using Elasticsearch

makedocs(
    sitename = "Elasticsearch",
    format = Documenter.HTML(),
    modules = [Elasticsearch],
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

deploydocs(repo = "github.com/OpenSesame/Elasticsearch.jl.git")