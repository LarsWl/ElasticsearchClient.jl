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
    "aknowledgment" => true
  )
)

test_index = "test"
test_id = "some-id"

@testset "Testing delete method" begin
  client = ElasticsearchClient.Client()

  client_patch = @patch ElasticsearchClient.ElasticTransport.perform_request(::ElasticsearchClient.ElasticTransport.Client, args...; kwargs...) = client_response_mock

  apply(client_patch) do
    @test ElasticsearchClient.delete(client, index=test_index, id=test_id) isa ElasticsearchClient.API.Response
  end
end
