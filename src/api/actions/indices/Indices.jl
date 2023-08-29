module Indices

using ..API: HTTP_GET, HTTP_DELETE, HTTP_PUT, HTTP_HEAD, HTTP_POST
using ..API: _listify, process_params, extract_options, set_ignore_on_not_found!
using ..API: Response
using ..ElasticTransport

include("delete.jl")
include("create.jl")
include("exists_alias.jl")
include("get.jl")
include("put_alias.jl")
include("exists.jl")
include("refresh.jl")
include("update_aliases.jl")

end
