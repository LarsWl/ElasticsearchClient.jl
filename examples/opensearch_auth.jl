module OpenSearchAuth

using HTTP
using AWS
using Dates
using TimeZones

const AWS_REQUEST_HEADERS = ["Host", "Content-Type", "User-Agent"]
const AWS_AUTH_HEADERS = ["Authorization", "Content-MD5", "x-amz-date", "x-amz-security-token"]
const ES_SERVICE_NAME = "es"
const ES_REGION = "us-west-1"
const ACCEPT_HEADER_KEY = "Accept"

function auth_layer(handler)
    return function (req; auth_params::AWSCredentials, kw...)
        config = AWSConfig(;creds=auth_params, region=ES_REGION)

        headers = Dict{String,String}(req.headers)
        # With accept header AWS return error about mismatch signature
        accept_header = pop!(headers, ACCEPT_HEADER_KEY, nothing)

        aws_request = AWS.Request(
            content=req.body.s,
            url=string(req.url),
            headers=headers,
            api_version="none",
            request_method=req.method,
            service=ES_SERVICE_NAME
        )
        AWS.sign_aws4!(config, aws_request, now(UTC))

        if !isnothing(accept_header)
            aws_request.headers[ACCEPT_HEADER_KEY] = accept_header
        end

        req.headers = collect(aws_request.headers)

        return handler(req; kw...)
    end
end

HTTP.@client [auth_layer]

end

using ElasticsearchClient
using AWS

client = ElasticsearchClient.Client(
  host=Dict(:host => "search-search-dev-zp3ihjtqii7ngqpdq4k52a33c4.us-west-1.es.amazonaws.com", :port => 443, :scheme => "https"),
  http_client=OpenSearchAuth
)

creds = AWSCredentials()

ElasticsearchClient.search(client, auth_params=creds)
