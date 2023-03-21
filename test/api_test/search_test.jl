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
  "query" => Dict(
    "match_all" => Dict()
  )
)
test_sort = ["price:desc", "title:asc"]

@testset "Testing search method" begin
  @test Elasticsearch.API.search(client, index=index, body=test_body, sort=test_sort) isa Elasticsearch.API.Response
  @test Elasticsearch.API.search(client, index=index, body=test_body) isa Elasticsearch.API.Response
  @test Elasticsearch.API.search(client, index=index) isa Elasticsearch.API.Response
  @test Elasticsearch.API.search(client) isa Elasticsearch.API.Response
end