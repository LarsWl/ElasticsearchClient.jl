using Mocking

function delete(client::Client; kwargs...)
  arguments = Dict(kwargs)

  !haskey(arguments, :index) && throw(ArgumentError("Required argument 'index' missing"))

  headers = pop!(arguments, :headers, Dict())
  body = nothing

  index = pop!(arguments, :index)

  method = HTTP_DELETE
  path = "/$(_listify(index))"
  params = process_params(arguments)

  Response(
    @mock perform_request(client, method, path; params=params, headers=headers, body=body)
  )
end
