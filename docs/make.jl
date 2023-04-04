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
           "Base Actions" => "Api/index.md" 
        ]
    ]
)

deploydocs(repo = "github.com/OpenSesame/Elasticsearch.jl.git")