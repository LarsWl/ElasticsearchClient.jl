using Mocking

"""
Updates index aliases.

- `timeout::DateTime`: Request timeout
- `master_timeout::DateTime`: Specify timeout for connection to master
- `headers::Dict`: Custom HTTP headers
- `body::Union{NamedTuple,Dict}`: The definition of `actions` to perform (*Required*)

See https://www.elastic.co/guide/en/elasticsearch/reference/current/indices-aliases.html
"""
function update_aliases(client::Client; kwargs...)
  arguments = Dict(kwargs)

  !haskey(arguments, :body) && throw(ArgumentError("Required argument `body` missing"))

  headers = pop!(arguments, :headers, Dict())
  body = pop!(arguments, :body)

  method = HTTP_POST
  path = "/_aliases"
  params = process_params(arguments)

  Response(
    @mock perform_request(client, method, path; params=params, headers=headers, body=body)
  )
end