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
test_body = Dict(
  :query => Dict(
    :match_all => Dict()
  )
)

@testset "Testing delete_by_query method" begin
  client = ElasticsearchClient.Client()

  client_patch = @patch ElasticsearchClient.ElasticTransport.perform_request(::ElasticsearchClient.ElasticTransport.Client, args...; kwargs...) = client_response_mock

  apply(client_patch) do
    @test ElasticsearchClient.delete_by_query(client, index=test_index, body=test_body) isa ElasticsearchClient.API.Response
  end
end
