using Test
using Elasticsearch
using Mocking
using HTTP

Mocking.activate()

client_response_mock = HTTP.Response(
  200,
  Dict(
    "content-type" => "application/json",
    "content-length" => 100
  ),
  Dict(
    "took" => 10,
    "timed_out" => false,
    "hits" => Dict("hits" => [])
  )
)

test_id = "test"
test_body = Dict(
  "query" => Dict()
)
test_context = ["test_context1", "test_context2"]

@testset "Testing search method" begin
  client = Elasticsearch.Client()

  client_patch = @patch Elasticsearch.ElasticTransport.perform_request(::Elasticsearch.ElasticTransport.Client, args...; kwargs...) = client_response_mock

  apply(client_patch) do
    @test Elasticsearch.search_template(client, id=test_id, body=test_body) isa Elasticsearch.API.Response
    @test Elasticsearch.search_template(client, id=test_id, body=test_body, context=test_context) isa Elasticsearch.API.Response
  end
end