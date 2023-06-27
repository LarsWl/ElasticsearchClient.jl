# API Reference

```@meta
CurrentModule = ElasticsearchClient.API
```

High-level API to ElasticsearchClient. Each method receive ElasticsearchClient.Client and params as keyword arguments.
 Reponse similarto HTTP.Response, but it coverts body to String instead of CodeUnits or store body as Dict, if content type is application/json.

### Example

```julia
using ElasticsearchClient

client = ElasticsearchClient.Client()

body = (
  query=(
    match_all=Dict(),
  ),
)

response = ElasticsearchClient.search(client, body=body)

@show response.body["took"]
```

```@docs
Response
search
search_template
put_script
index
bulk
delete
delete_by_query
```
