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
    "result" => "success"
  )
)

test_index = "test"
test_body_string = "
{ \"index\" : { \"_index\" : \"test\", \"_id\" : \"1\" } }
{ \"field1\" : 1, \"field2\": 2}
"
test_body_string_vector = [
  "{ \"index\" : { \"_index\" : \"test\", \"_id\" : \"1\" } }",
  "{ \"field1\" : 1, \"field2\": 2}"
]
test_body_dict_vector = [
  Dict(:index => Dict(:_index => test_index, :_id => 1, :data => Dict(:field1 => 1)))
  Dict(:index => Dict(:_index => test_index, :_id => 2))
  Dict("field1" => 2, "field2" => 3)
]

test_body_dict_vector_2 = [
  Dict(:index => Dict(:_index => test_index, :_id => 1, :data => Dict(:field1 => 1)))
  Dict(:index => Dict(:_index => test_index, :_id => 2))
]


@testset "Testing index method" begin
  client = Elasticsearch.Client()

  client_patch = @patch Elasticsearch.ElasticTransport.perform_request(::Elasticsearch.ElasticTransport.Client, args...; kwargs...) = client_response_mock

  apply(client_patch) do
    @test Elasticsearch.bulk(client, body=test_body_string) isa Elasticsearch.API.Response
    @test Elasticsearch.bulk(client, index=test_index, body=test_body_string_vector) isa Elasticsearch.API.Response
    @test Elasticsearch.bulk(client, body=test_body_dict_vector) isa Elasticsearch.API.Response
    @test Elasticsearch.bulk(client, body=test_body_dict_vector_2) isa Elasticsearch.API.Response
  end
end
