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
  [
    Dict(
      "name" => "test"
    )
  ]
)

test_index = "test"

@testset "Testing search method" begin
  client = ElasticsearchClient.Client()

  client_patch = @patch ElasticsearchClient.ElasticTransport.perform_request(::ElasticsearchClient.ElasticTransport.Client, args...; kwargs...) = client_response_mock

  apply(client_patch) do
    @test ElasticsearchClient.Cat.indices(client, index=test_index) isa ElasticsearchClient.API.Response
    @test ElasticsearchClient.Cat.indices(client) isa ElasticsearchClient.API.Response
  end
end
