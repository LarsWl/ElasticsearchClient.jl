using Mocking

function search_template(client::Client; kwargs...)
  arguments = Dict(kwargs)

  !haskey(arguments, :body) && throw(ArgumentError("Required argument 'body' missing"))

  headers = pop!(arguments, :headers, Dict())
  body = pop!(arguments, :body, nothing)

  index = pop!(arguments, :index, nothing)

  method = HTTP_POST

  path = if !isnothing(index)
    "/$(_listify(index))/$(UNDERSCORE_SEARCH)/template"
  else
    "/$(UNDERSCORE_SEARCH)/template"
  end

  params = process_params(arguments)

  Response(
    @mock perform_request(client, method, path; params=params, headers=headers, body=body)
  )
end
