module Elasticsearch

include("version.jl")

include("elastic_transport/ElasticTransport.jl")
include("api/API.jl")

using .ElasticTransport
using .API

end # module Elasticsearch
