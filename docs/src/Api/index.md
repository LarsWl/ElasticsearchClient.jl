# API Reference

```@meta
CurrentModule = Elasticsearch.API
```

High-level API to Elasticsearch. Each method receive Elasticsearch.Client and params as keyword arguments.
 Reponse similarto HTTP.Response, but it coverts body to String instead of CodeUnits or store body as Dict, if content type is application/json.

### Example

```julia
using Elasticsearch

client = Elasticsearch.Client()

body = (
  query=(
    match_all=Dict(),
  ),
)

response = Elasticsearch.search(client, body=body)

@show response.body["took"]
```

```@docs
Response
search
search_template
put_script
index
```
