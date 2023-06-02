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

test_index = "test"
test_body = Dict(
  "id" => "test",
  "params" => Dict(
    "p1" => 1
  )
)

@testset "Testing search method" begin
  client = ElasticsearchClient.Client()

  client_patch = @patch ElasticsearchClient.ElasticTransport.perform_request(::ElasticsearchClient.ElasticTransport.Client, args...; kwargs...) = client_response_mock

  apply(client_patch) do
    @test ElasticsearchClient.search_template(client, index=test_index, body=test_body) isa ElasticsearchClient.API.Response
    @test ElasticsearchClient.search_template(client, body=test_body) isa ElasticsearchClient.API.Response
  end
end
