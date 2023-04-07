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
test_body = (
  query=(
    match_all=Dict(),
  ),
)

test_sort = ["price:desc", "title:asc"]

@testset "Testing search method" begin
  client = Elasticsearch.Client()

  client_patch = @patch Elasticsearch.ElasticTransport.perform_request(::Elasticsearch.ElasticTransport.Client, args...; kwargs...) = client_response_mock

  apply(client_patch) do 
    @test Elasticsearch.search(client, index=test_index, body=test_body, sort=test_sort) isa Elasticsearch.API.Response
    @test Elasticsearch.search(client, index=test_index, body=test_body) isa Elasticsearch.API.Response
    @test Elasticsearch.search(client, index=test_index) isa Elasticsearch.API.Response
    @test Elasticsearch.search(client) isa Elasticsearch.API.Response
  end
end
