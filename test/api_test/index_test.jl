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
    "shards" => Dict(),
    "result" => "updated"
  )
)

test_index = "test"
test_body = (
  propertyOne="123",
  propertyTwo="111"
)
id="some-id"

@testset "Testing index method" begin
  client = Elasticsearch.Client()

  client_patch = @patch Elasticsearch.ElasticTransport.perform_request(::Elasticsearch.ElasticTransport.Client, args...; kwargs...) = client_response_mock

  apply(client_patch) do
    @test Elasticsearch.index(client, index=test_index, body=test_body) isa Elasticsearch.API.Response
    @test Elasticsearch.index(client, index=test_index, body=test_body,id=id) isa Elasticsearch.API.Response
  end
end
