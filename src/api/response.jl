using HTTP

struct Response
  status
  body
  headers
end

function Response(http_response::HTTP.Response)
  Response(
    http_response.status,
    http_response.body,
    http_response.headers
  )
end