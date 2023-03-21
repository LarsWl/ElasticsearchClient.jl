using Elasticsearch
using Test
using Mocking
using HTTP
using JSON

Mocking.activate()

hosts = [
  Dict{Symbol, Any}(:host => "localhost", :schema => "https"),
  Dict{Symbol, Any}(:host => "localhost", :schema => "https", :port => 9201),
  Dict{Symbol, Any}(:host => "aws_host", :port => 9200),
]

options = Dict(
  :compression => true,
  :retry_on_status => [400, 404],
  :transport_options => Dict{Symbol, Any}(
    :headers => Dict(
      "test-api-key" => "key",
      :content_type => "application/json"
    ),
    :resurrect_timeout => 0
  )
)

successful_health_response_mock = HTTP.Response(
  200,
  Dict("content-type" => "application/json"),
  JSON.json(
    Dict(
      "cluster_name" => "name",
      "timed_out" => false
    )
  )
)

successful_search_response_mock = HTTP.Response(
  200,
  Dict("content-type" => "application/json"),
  JSON.json(
    Dict(
      "took" => 12
    )
  )
)

not_found_response_mock = HTTP.Response(
  404,
  Dict("content-type" => "application/json"),
  JSON.json(
    Dict(
      "status" => "Not Found"
    )
  )
)

internal_error_response_mock = HTTP.Response(
  500,
  Dict("content-type" => "application/json"),
  JSON.json(
    Dict(
      "status" => "Error"
    )
  )
)

@testset "Transport test" begin
  @testset "Transport initialization" begin
    transport = Elasticsearch.ElasticTransport.Transport(;hosts, options)

    @test length(transport.connections.connections) == length(hosts)
    @test transport.use_compression == options[:compression]
    @test transport.retry_on_status == options[:retry_on_status]
  end

  @testset "Performing request" begin
    transport = Elasticsearch.ElasticTransport.Transport(;hosts, options=options)

    @testset "Testing with successful response" begin
      @testset "Testing GET request with params" begin
        http_patch = @patch HTTP.request(args...;kwargs...) = successful_health_response_mock

        apply(http_patch) do 
          response = Elasticsearch.ElasticTransport.perform_request(transport, "GET", "/_cluster/health"; params = Dict("pretty" => true))

          @test response isa HTTP.Response
          @test response.status == 200
          @test haskey(response.body, "cluster_name")
        end
      end

      @testset "Testing POST request with params" begin
        http_patch = @patch HTTP.request(args...;kwargs...) = successful_search_response_mock

        apply(http_patch) do
          response = Elasticsearch.ElasticTransport.perform_request(transport, "POST", "/_search"; body = Dict("query" => Dict("match_all" => Dict())))

          @test response isa HTTP.Response
          @test response.status == 200
          @test haskey(response.body, "took")
        end
      end

      @testset "Testing unsuccessful response with retry" begin
        count_tries = 0

        http_patch = @patch HTTP.request(args...;kwargs...) = begin
          count_tries += 1

          not_found_response_mock
        end

        apply(http_patch) do
          @test_throws Elasticsearch.ElasticTransport.NotFound Elasticsearch.ElasticTransport.perform_request(
            transport,
            "POST",
            "/_search"; 
            body = Dict("query" => Dict("match_all" => Dict()))
          )

          @test count_tries == Elasticsearch.ElasticTransport.DEFAULT_MAX_RETRIES
        end
      end

      @testset "Testing unsuccessful response without retries" begin
        count_tries = 0

        http_patch = @patch HTTP.request(args...;kwargs...) = begin
          count_tries += 1

          internal_error_response_mock
        end

        apply(http_patch) do
          @test_throws Elasticsearch.ElasticTransport.InternalServerError Elasticsearch.ElasticTransport.perform_request(
            transport,
            "POST",
            "/_search"; 
            body = Dict("query" => Dict("match_all" => Dict()))
          )

          @test count_tries == 1
        end
      end
    end
  end
end
