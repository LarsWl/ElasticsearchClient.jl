using HTTP

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
