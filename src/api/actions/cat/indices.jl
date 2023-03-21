using Mocking

function indices(client::Client; kwargs...)
  arguments = Dict(kwargs)

  headers = pop!(arguments, :headers, Dict())
  body = nothing
  index = pop!(arguments, :index, nothing)
  method = HTTP_GET

  path = if !isnothing(index)
    "/_cat/indices/$(_listify(index))"
  else
    "/_cat/indices"
  end

  params = process_params(arguments)

  Response(
    @mock perform_request(client, method, path; params=params, headers=headers, body=body)
  )
end
