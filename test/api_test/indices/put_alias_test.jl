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
    "acknowledge" => true
  )
)

test_index = "test"
test_name = "tst"

@testset "Testing put_alias method" begin
  client = Elasticsearch.Client()

  client_patch = @patch Elasticsearch.ElasticTransport.perform_request(::Elasticsearch.ElasticTransport.Client, args...; kwargs...) = client_response_mock

  apply(client_patch) do
    @test Elasticsearch.Indices.put_alias(client, name=test_name,index=test_index) isa Elasticsearch.API.Response
  end
end
