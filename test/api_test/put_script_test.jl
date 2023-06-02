using Test
using ElasticsearchClient
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
  client = ElasticsearchClient.Client()

  client_patch = @patch ElasticsearchClient.ElasticTransport.perform_request(::ElasticsearchClient.ElasticTransport.Client, args...; kwargs...) = client_response_mock

  apply(client_patch) do
    @test ElasticsearchClient.put_script(client, id=test_id, body=test_body) isa ElasticsearchClient.API.Response
    @test ElasticsearchClient.put_script(client, id=test_id, body=test_body, context=test_context) isa ElasticsearchClient.API.Response
  end
end