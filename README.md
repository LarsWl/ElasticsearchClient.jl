# ElasticsearchClient.jl
[![](https://img.shields.io/badge/docs-stable-blue.svg)](https://opensesame.github.io/ElasticsearchClient.jl)
[![Coverage Status](https://coveralls.io/repos/github/OpenSesame/ElasticsearchClient.jl/badge.svg?branch=main&t=vPHtC7)](https://coveralls.io/github/OpenSesame/ElasticsearchClient.jl?branch=main)

This library was inspired by [elasticsearch-ruby](https://github.com/elastic/elasticsearch-ruby) and most of the implementation was taken from there.

There are two main modules: ElasticTransfort and API.

- ElasticTransport is responsible for low-level interactions with Elasticsearch and it allows requests to be performed using HTTP parameters.
- API suggests a high level API that corresponds with Elasticsearch API. Currently not all API methods are implemented, so help is needed.

### Example of using ElasticTransort

```julia
using ElasticsearchClient

# Client is exported from ElasticTransport
client = ElasticsearchClient.Client(host=(host="localhost", port=9200, scheme="http"))

perform_request(client, "GET", "/_search")
```

### Example of using API

```julia
using ElasticsearchClient

client = ElasticsearchClient.Client()

body = (
  query=(
    match_all=Dict(),
  ),
)

# Methods are exported from API module
response = ElasticsearchClient.search(client, body=body)

@show response.body["took"]
```

## What's next?

More information about usage can be found in the [documentation](https://opensesame.github.io/ElasticsearchClient.jl).
