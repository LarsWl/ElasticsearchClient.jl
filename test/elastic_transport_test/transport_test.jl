using Elasticsearch
using Test
using Mocking
using HTTP
using JSON

Mocking.activate()

hosts = [
  Dict{Symbol, Any}(:host => "localhost", :schema => "https"),
  Dict{Symbol, Any}(:host => "127.0.0.1", :schema => "http", :port => 9250),
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

nodes_response_mock = HTTP.Response(
  200,
  Dict("content-type" => "application/json"),
  Dict(
    "nodes" => Dict(
      "node_id_1" => Dict(
        "roles" => ["master"],
        "name" => "Name Node 1",
        "http" => Dict("publish_address" => "127.0.0.1:9250")
      ),
      "node_id_2" => Dict(
        "roles" => ["master"],
        "name" => "Name Node 2",
        "http" => Dict("publish_address" => "testhost1.com:9250")
      ),
      "node_id_3" => Dict(
        "roles" => ["master"],
        "name" => "Name Node 3",
        "http" => Dict("publish_address" => "inet[/127.0.0.2:9250]")
      ),
      "node_id_4" => Dict(
        "roles" => ["master"],
        "name" => "Name Node 4",
        "http" => Dict("publish_address" => "example.com/127.0.0.1:9250")
      ),
      "node_id_5" => Dict(
        "roles" => ["master"],
        "name" => "Name Node 5",
        "http" => Dict("publish_address" => "[::1]:9250")
      ), 
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

      @testset "Testing with connect error" begin
        http_patch = @patch HTTP.request(args...;kwargs...) = throw(HTTP.ConnectError("Error", "Error"))

        apply(http_patch) do
          @test_throws HTTP.ConnectError Elasticsearch.ElasticTransport.perform_request(
            transport,
            "POST",
            "/_search"; 
            body = Dict("query" => Dict("match_all" => Dict()))
          )

          @test length(Elasticsearch.ElasticTransport.Connections.dead(transport.connections)) == 1
        end
      end
    end
  end

  @testset "Testing sniffing" begin
    @testset "Testing successful sniffing" begin
      perform_request_patch = @patch Elasticsearch.ElasticTransport.perform_request(
        ::Elasticsearch.ElasticTransport.Transport, args...; kwargs...
      ) = nodes_response_mock

      transport = Elasticsearch.ElasticTransport.Transport(;hosts, options=options)

      apply(perform_request_patch) do
        hosts = Elasticsearch.ElasticTransport.sniff_hosts(transport) |>
          hosts -> sort(hosts, by = host -> host[:id])

        @test hosts[begin][:host] == "127.0.0.1"
        @test hosts[begin][:port] == 9250

        @test hosts[begin + 1][:host] == "testhost1.com"
        @test hosts[begin + 1][:port] == 9250

        @test hosts[begin + 2][:host] == "127.0.0.2"
        @test hosts[begin + 2][:port] == 9250

        @test hosts[begin + 3][:host] == "example.com"
        @test hosts[begin + 3][:port] == 9250

        @test hosts[begin + 4][:host] == "::1"
        @test hosts[begin + 4][:port] == 9250
      end
    end

    @testset "Testing sniffing timeout" begin
      perform_request_patch = @patch Elasticsearch.ElasticTransport.perform_request(
        ::Elasticsearch.ElasticTransport.Transport, args...; kwargs...
      ) = sleep(Elasticsearch.ElasticTransport.DEFAULT_SNIFFING_TIMEOUT + 0.5)

      transport = Elasticsearch.ElasticTransport.Transport(;hosts, options=options)

      apply(perform_request_patch) do
        @test_throws Elasticsearch.ElasticTransport.SniffingTimetoutError Elasticsearch.ElasticTransport.sniff_hosts(transport)
      end
    end
  end

  @testset "Testing reload connections" begin
    nodes_request_patch = @patch Elasticsearch.ElasticTransport.perform_request(
      ::Elasticsearch.ElasticTransport.Transport, args...; kwargs...
    ) = nodes_response_mock

    transport = Elasticsearch.ElasticTransport.Transport(;hosts, options=options)

    apply(nodes_request_patch) do
      Elasticsearch.ElasticTransport.reload_connections!(transport)

      @test length(transport.connections) == length(nodes_response_mock.body["nodes"])
    end
  end
end