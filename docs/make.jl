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

# Documenter can also automatically deploy documentation to gh-pages.
# See "Hosting Documentation" and deploydocs() in the Documenter manual
# for more information.
#=deploydocs(
    repo = "<repository url>"
)=#
