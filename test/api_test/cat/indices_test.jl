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
  [
    Dict(
      "name" => "test"
    )
  ]
)

test_index = "test"

@testset "Testing search method" begin
  client = Elasticsearch.Client()

  client_patch = @patch Elasticsearch.ElasticTransport.perform_request(::Elasticsearch.ElasticTransport.Client, args...; kwargs...) = client_response_mock

  apply(client_patch) do
    @test Elasticsearch.Cat.indices(client, index=test_index) isa Elasticsearch.API.Response
    @test Elasticsearch.Cat.indices(client) isa Elasticsearch.API.Response
  end
end
