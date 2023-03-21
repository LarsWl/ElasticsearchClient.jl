using Mocking

function search(client::Client; kwargs...)
  arguments = Dict(kwargs)

  headers = pop!(arguments, :headers, Dict())
  body = pop!(arguments, :body, nothing)

  index = pop!(arguments, :index, nothing)

  method = if isnothing(body)
    HTTP_GET
  else
    HTTP_POST
  end

  path = if !isnothing(index)
    "/$(_listify(index))/$(UNDERSCORE_SEARCH)"
  else
    "/$(UNDERSCORE_SEARCH)"
  end

  params = process_params(arguments)

  Response(
    perform_request(client, method, path; params=params, headers=headers, body=body)
  )
end