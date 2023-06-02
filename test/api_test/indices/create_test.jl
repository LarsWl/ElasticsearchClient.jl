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
      "acknowledge" => true
    )
  ]
)

test_index = "test"
test_body = (
  settings=(
    number_of_shards=1,
    number_of_replicas=1,
  ),
  mappings=(
    dynamic="strict",
    properties=(
      propertyOne=(
        type="keyword",
      ),
      propertyTwo=(
        type="keyword",
      ),
    )
  )
)

@testset "Testing create method" begin
  client = ElasticsearchClient.Client()

  client_patch = @patch ElasticsearchClient.ElasticTransport.perform_request(::ElasticsearchClient.ElasticTransport.Client, args...; kwargs...) = client_response_mock

  apply(client_patch) do
    @test ElasticsearchClient.Indices.create(client, index=test_index) isa ElasticsearchClient.API.Response
    @test ElasticsearchClient.Indices.create(client, index=test_index, body=test_body) isa ElasticsearchClient.API.Response
  end
end
