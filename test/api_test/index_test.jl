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
  client = ElasticsearchClient.Client()

  client_patch = @patch ElasticsearchClient.ElasticTransport.perform_request(::ElasticsearchClient.ElasticTransport.Client, args...; kwargs...) = client_response_mock

  apply(client_patch) do
    @test ElasticsearchClient.index(client, index=test_index, body=test_body) isa ElasticsearchClient.API.Response
    @test ElasticsearchClient.index(client, index=test_index, body=test_body,id=id) isa ElasticsearchClient.API.Response
  end
end
