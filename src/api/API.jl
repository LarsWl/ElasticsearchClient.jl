module API

export search

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
include("actions/search.jl")

end