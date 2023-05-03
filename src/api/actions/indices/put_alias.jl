using Mocking

"""
Creates or updates an alias.

- `index::Union{String,Vector{String}}`: A comma-separated list of index names the alias should point to (supports wildcards); use `_all` to perform the operation on all indices.
- `name::String`: The name of the alias to be created or updated
- `timeout::DateTime`: Explicit timestamp for the document
- `master_timeout::DateTime`: Specify timeout for connection to master
- `headers::Dict`: Custom HTTP headers
- `body::Union{NamedTuple,Dict}`: The settings for the alias, such as `routing` or `filter`

See https://www.elastic.co/guide/en/elasticsearch/reference/current/indices-aliases.html
"""
function put_alias(client::Client; kwargs...)
  arguments = Dict(kwargs)

  !haskey(arguments, :index) && throw(ArgumentError("Required argument 'index' missing"))
  !haskey(arguments, :name) && throw(ArgumentError("Required argument 'name' missing"))

  headers = pop!(arguments, :headers, Dict())
  body = pop!(arguments, :body, nothing)

  index = pop!(arguments, :index)
  name = pop!(arguments, :name)

  method = HTTP_PUT
  path = "/$(_listify(index))/_aliases/$(_listify(name))"
  params = process_params(arguments)

  Response(
    @mock perform_request(client, method, path; params=params, headers=headers, body=body)
  )
end