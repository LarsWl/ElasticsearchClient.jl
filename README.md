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

## Authentication

If you need to use authentication, you can use custom http client with additional middleware layers.

Example:

```julia
# Example from HTTP.jl docs: https://juliaweb.github.io/HTTP.jl/stable/client/#Quick-Examples
module Auth

using HTTP

function auth_layer(handler)
    # returns a `Handler` function; check for a custom keyword arg `authcreds` that
    # a user would pass like `HTTP.get(...; authcreds=creds)`.
    # We also accept trailing keyword args `kw...` and pass them along later.
    return function(req; authcreds=nothing, kw...)
        # only apply the auth layer if the user passed `authcreds`
        if authcreds !== nothing
            # we add a custom header with stringified auth creds
            HTTP.setheader(req, "X-Auth-Creds" => string(authcreds))
        end
        # pass the request along to the next layer by calling `auth_layer` arg `handler`
        # also pass along the trailing keyword args `kw...`
        return handler(req; kw...)
    end
end

# Create a new client with the auth layer added
HTTP.@client [auth_layer]

end

client = ElasticsearchClient.Client(http_client=Auth)
```

## How to install Elasticsearch locally?

The easiest way is to use a Docker container. If you have [Docker Desktop](https://www.docker.com/products/docker-desktop/), then just copy the the `docker-compose.yml`:
```yaml
version: '3.8'
services:
  es01:
    image: 'docker.elastic.co/elasticsearch/elasticsearch:8.8.2'
    ports:
      - '0.0.0.0:9200:9200'
    volumes:
      - esdata:/usr/share/elasticsearch/data
    restart: always
    environment:
      - node.name=es01
      - cluster.name=es_local_claster
      - cluster.initial_master_nodes=es01
      - bootstrap.memory_lock=true
      - xpack.security.enabled=false
    mem_limit: 1073741824
    ulimits:
      memlock:
        soft: -1
        hard: -1
volumes:
  esdata:
    driver: local

```

and run the `docker-compose up` command in the directory containing that file.

If you want to configure a cluster [see full instructions](https://www.elastic.co/guide/en/elasticsearch/reference/current/docker.html#docker)


## What's next?

More information about usage can be found in the [documentation](https://opensesame.github.io/ElasticsearchClient.jl).
