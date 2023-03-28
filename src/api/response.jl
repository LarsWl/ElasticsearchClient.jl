using HTTP

"""
Store Elastic response with body, headers and status

    function Response(http_response::HTTP.Response)

Create response structure and convert body to String if it's CodeUnits
"""
struct Response
  status
  body
  headers
end

function Response(http_response::HTTP.Response)
  body = if http_response.body isa Base.CodeUnits
    String(http_response.body)
  else
    http_response.body
  end

  Response(
    http_response.status,
    body,
    http_response.headers
  )
end
