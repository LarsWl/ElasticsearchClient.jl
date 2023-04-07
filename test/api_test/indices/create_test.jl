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
  client = Elasticsearch.Client()

  client_patch = @patch Elasticsearch.ElasticTransport.perform_request(::Elasticsearch.ElasticTransport.Client, args...; kwargs...) = client_response_mock

  apply(client_patch) do
    @test Elasticsearch.Indices.create(client, index=test_index) isa Elasticsearch.API.Response
    @test Elasticsearch.Indices.create(client, index=test_index, body=test_body) isa Elasticsearch.API.Response
  end
end
