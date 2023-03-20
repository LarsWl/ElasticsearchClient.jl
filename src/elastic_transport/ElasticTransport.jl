module ElasticTransport

export Client
export perform_request

include("transport/errors.jl")
include("transport/connections/Connections.jl")
include("transport/transport.jl")
include("client.jl")

end