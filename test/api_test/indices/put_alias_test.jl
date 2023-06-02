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
    "acknowledge" => true
  )
)

test_index = "test"
test_name = "tst"

@testset "Testing put_alias method" begin
  client = ElasticsearchClient.Client()

  client_patch = @patch ElasticsearchClient.ElasticTransport.perform_request(::ElasticsearchClient.ElasticTransport.Client, args...; kwargs...) = client_response_mock

  apply(client_patch) do
    @test ElasticsearchClient.Indices.put_alias(client, name=test_name,index=test_index) isa ElasticsearchClient.API.Response
  end
end
