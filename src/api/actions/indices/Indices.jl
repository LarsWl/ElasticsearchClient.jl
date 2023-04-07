module Indices

using ..API: HTTP_GET, HTTP_DELETE, HTTP_PUT, HTTP_HEAD
using ..API: _listify, process_params
using ..API: Response
using ..ElasticTransport

include("delete.jl")
include("create.jl")
include("exists_alias.jl")
include("get.jl")
include("put_alias.jl")

end
