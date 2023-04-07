using Mocking

"""
Creates or updates a script.

- `id::String`: Script ID
- `context::String`: Script context
- `timeout::DateTime`: Explicit operation timeout
- `master_timeout::DateTime`: Specify timeout for connection to master
- `headers::Dict`: Custom HTTP headers
- `body::Union{Dict,NamedTuple}`: The document (*Required*)

See https://www.elastic.co/guide/en/elasticsearch/reference/current/modules-scripting.html
"""

function put_script(client::Client; kwargs...)
  arguments = Dict(kwargs)

  !haskey(arguments, :body) && throw(ArgumentError("Required argument 'body' missing"))
  !haskey(arguments, :id) && throw(ArgumentError("Required argument 'id' missing"))

  headers = pop!(arguments, :headers, Dict())
  body = pop!(arguments, :body)
  id = pop!(arguments, :id)
  context = pop!(arguments, :context, nothing)

  method = HTTP_PUT

  path = if !isnothing(context)
    "/_scripts/$(_listify(id))/$(_listify(context))"
  else
    "/_scripts/$(_listify(id))"
  end
  params = process_params(arguments)

  Response(
    @mock perform_request(client, method, path; params=params, headers=headers, body=body)
  )
end
