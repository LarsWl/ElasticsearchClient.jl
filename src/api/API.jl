module API

export Cat, Indices
export search, search_template, put_script

using ..ElasticTransport

const HTTP_GET = "GET"
const HTTP_HEAD = "HEAD"
const HTTP_POST = "POST"
const HTTP_PUT  = "PUT"
const HTTP_DELETE = "DELETE"
const UNDERSCORE_SEARCH = "_search"
const UNDERSCORE_ALL = "_all"
const DEFAULT_DOC = "_doc"


include("response.jl")
include("utils.jl")
include("actions/cat/Cat.jl")
include("actions/indices/Indices.jl")
include("actions/search.jl")
include("actions/search_template.jl")
include("actions/put_script.jl")

end
