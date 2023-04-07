using Test
using Elasticsearch
using Mocking
using HTTP

Mocking.activate()

found_client_response_mock = HTTP.Response(
  200,
  Dict(
    "content-type" => "application/json",
    "content-length" => 100
  ),
  nothing
)

not_found_exception = Elasticsearch.ElasticTransport.CODE_TO_EXCEPTION[404](404, "Not Found")
test_name = "test"

@testset "Testing exists_alias method" begin
  client = Elasticsearch.Client()

  @testset "When alias found" begin
    client_patch = @patch Elasticsearch.ElasticTransport.perform_request(::Elasticsearch.ElasticTransport.Client, args...; kwargs...) = client_response_mock

    apply(client_patch) do
      @test Elasticsearch.Indices.exists_alias(client, name=test_name)
    end
  end

  @testset "When alias not found" begin
    client_patch = @patch(
      Elasticsearch.ElasticTransport.perform_request(::Elasticsearch.ElasticTransport.Client, args...; kwargs...) =
        throw(not_found_exception)
    )

    apply(client_patch) do
      @test !Elasticsearch.Indices.exists_alias(client, name=test_name)
    end
  end
end
