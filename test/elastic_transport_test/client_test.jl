using Elasticsearch
using Test
using URIs
using Mocking
using HTTP

Mocking.activate()

hosts1 = [
  Dict{Symbol, Any}(:host => "localhost", :schema => "https"),
  Dict{Symbol, Any}(:host => "localhost", :schema => "https", :port => 9201),
  Dict{Symbol, Any}(:host => "aws_host", :port => 9200),
]

hosts2 = [
  URI("https://127.0.0.1:8080"),
  URI("https://usr:pwd@127.0.0.1"),
  URI("http://aws_host.com"),
]

hosts3 = "https://127.0.0.1:8080,https://usr:pwd@127.0.0.1,http://aws_host.com"

arguments1 = Dict{Symbol, Any}(
  :hosts => hosts1,
  :delay_on_retry => 10,
  :retry_on_status => [400, 404]
)

arguments2 = Dict{Symbol, Any}(
  :urls => hosts2,
  :delay_on_retry => 10,
  :compression => true,
  :retry_on_status => [400, 404],
  :transport_options => Dict{Symbol, Any}(
    :headers => Dict(
      "test-api-key" => "key",
    ),
    :resurrect_timeout => 0
  )
)

arguments3 = Dict{Symbol, Any}(
  :host => hosts3
)

arguments4 = Dict{Symbol, Any}()

transport_response_mock = HTTP.Response(
  200,
  Dict("Content-Type" => "application/json"),
  Dict("status" => 200)
)

@testset "Testing ElasticTransport Client" begin
  @testset "Testing initalization" begin
    client1 = Elasticsearch.ElasticTransport.Client(arguments1)
    client2 = Elasticsearch.ElasticTransport.Client(arguments2)
    client3 = Elasticsearch.ElasticTransport.Client(arguments3)
    client4 = Elasticsearch.ElasticTransport.Client(arguments4)

    @test length(client1.hosts) == 3
    @test length(client2.hosts) == 3
    @test length(client3.hosts) == 3
    @test length(client4.hosts) == 1
  end

  @testset "Testing performing request" begin
    client = Elasticsearch.ElasticTransport.Client(arguments4)

    transport_patch = @patch(
      Elasticsearch.ElasticTransport.perform_request(
        ::Elasticsearch.ElasticTransport.Transport, args...;kwargs...
      ) = transport_response_mock
    )

    apply(transport_patch) do
      response = Elasticsearch.ElasticTransport.perform_request(client, "GET", "/_cluster/health")

      @test response == transport_response_mock
    end
  end
end
