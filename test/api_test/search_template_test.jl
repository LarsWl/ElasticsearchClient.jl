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
    "took" => 10,
    "timed_out" => false,
    "hits" => Dict("hits" => [])
  )
)

test_index = "test"
test_body = Dict(
  "id" => "test",
  "params" => Dict(
    "p1" => 1
  )
)

@testset "Testing search method" begin
  client = Elasticsearch.Client()

  client_patch = @patch Elasticsearch.ElasticTransport.perform_request(::Elasticsearch.ElasticTransport.Client, args...; kwargs...) = client_response_mock

  apply(client_patch) do
    @test Elasticsearch.search_template(client, index=test_index, body=test_body) isa Elasticsearch.API.Response
    @test Elasticsearch.search_template(client, body=test_body) isa Elasticsearch.API.Response
  end
end
