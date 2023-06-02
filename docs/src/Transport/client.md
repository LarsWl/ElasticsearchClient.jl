
# Client documentation

```@meta
CurrentModule = ElasticsearchClient.ElasticTransport
```

Client is a base struct, that parse hosts and create connections to Elastic cluster.
 After initialization it can be passed to api methods to perform requests.

### Example

```julia
using ElasticsearchClient

client = ElasticsearchClient.Client(host=(host="localhost", port=9200, scheme="http"))

perform_request(client, "GET", "/_search")
```

```@docs
Client
perform_request
```