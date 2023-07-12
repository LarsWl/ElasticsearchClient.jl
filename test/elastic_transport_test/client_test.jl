using ElasticsearchClient
using Test
using URIs
using Mocking
using HTTP

Mocking.activate()

module CustomHTTP

using HTTP

function custom_layer(handler)
  return function(req; kw...)
    return handler(req, kw...)
  end
end

HTTP.@client [custom_layer]

end

transport_response_mock = HTTP.Response(
  200,
  Dict("Content-Type" => "application/json"),
  Dict("status" => 200)
)

validation_response_mock = HTTP.Response(
  200,
  Dict("Content-Type" => "application/json"),
  Dict(
    "name" => "Some name",
    "version" => Dict(
      "number" => "8.0.0",
      "build_type" => "tar"
    )
  )
)


@testset "Testing ElasticTransport Client" begin
  @testset "Testing default initailization" begin
    client = ElasticsearchClient.ElasticTransport.Client()

    @test length(client.hosts) == 1
    @test client.hosts[begin][:host] == "localhost"
    @test client.hosts[begin][:port] == 9200
    @test client.hosts[begin][:scheme] == "http"
  end

  @testset "Testing initalization with array hosts and custom args" begin
    hosts = [
      Dict{Symbol, Any}(:host => "localhost", :schema => "https"),
      Dict{Symbol, Any}(:host => "localhost", :schema => "https", :port => 9201),
      Dict{Symbol, Any}(:host => "aws_host", :port => 9200),
    ]

    client = ElasticsearchClient.ElasticTransport.Client(hosts=hosts, delay_on_retry=10, retry_on_status=[400, 404])

    @test length(client.hosts) == 3
    @test client.transport.options[:delay_on_retry] == 10
    @test client.transport.retry_on_status == [400, 404]
  end

  @testset "Testing initialization with URI and custom args" begin
    host = URI("https://127.0.0.1:8080")

    client = ElasticsearchClient.ElasticTransport.Client(host=host, compression=true, transport_options=Dict(:resurrect_timeout => 10))

    @test length(client.hosts) == 1
    @test client.transport.use_compression
  end

  @testset "Testing initialization with strings urls" begin
    hosts = "https://127.0.0.1:8080,https://usr:pwd@127.0.0.1,http://aws_host.com"

    client = ElasticsearchClient.ElasticTransport.Client(urls=hosts)

    @test length(client.hosts) == 3
  end

  @testset "Testing initialization with NamedTuple and custom http client" begin
    host = (host="localhost", schema="http", port=9200)

    client = ElasticsearchClient.ElasticTransport.Client(url=host, http_client=CustomHTTP)

    @test length(client.hosts) == 1
    @test client.transport.http_client == CustomHTTP
  end

  @testset "Testing verify elasticsearch" begin
    @testset "When validation request successful" begin
      client = ElasticsearchClient.ElasticTransport.Client()

      transport_patch = @patch(
        ElasticsearchClient.ElasticTransport.perform_request(
          ::ElasticsearchClient.ElasticTransport.Transport, args...;kwargs...
        ) = validation_response_mock
      )

      apply(transport_patch) do
        ElasticsearchClient.ElasticTransport.verify_elasticsearch(client)

        @test client.verified
      end
    end

    @testset "When validation request Forbidden" begin
      client = ElasticsearchClient.ElasticTransport.Client()

      transport_patch = @patch(
        ElasticsearchClient.ElasticTransport.perform_request(
          ::ElasticsearchClient.ElasticTransport.Transport, args...;kwargs...
        ) = throw(ElasticsearchClient.ElasticTransport.Forbidden(403, "Forbidden"))
      )

      apply(transport_patch) do
        ElasticsearchClient.ElasticTransport.verify_elasticsearch(client)

        @test client.verified
      end
    end

    @testset "When validation request return error" begin
      client = ElasticsearchClient.ElasticTransport.Client()

      transport_patch = @patch(
        ElasticsearchClient.ElasticTransport.perform_request(
          ::ElasticsearchClient.ElasticTransport.Transport, args...;kwargs...
        ) = throw(ElasticsearchClient.ElasticTransport.ServerError(500, "Server Error"))
      )

      apply(transport_patch) do
        ElasticsearchClient.ElasticTransport.verify_elasticsearch(client)

        @test !client.verified
      end
    end
  end

  @testset "Testing performing request" begin
    client = ElasticsearchClient.ElasticTransport.Client()

    transport_patch = @patch(
      ElasticsearchClient.ElasticTransport.perform_request(
        ::ElasticsearchClient.ElasticTransport.Transport, args...;kwargs...
      ) = transport_response_mock
    )

    apply(transport_patch) do
      response = ElasticsearchClient.ElasticTransport.perform_request(client, "GET", "/_cluster/health")

      @test client.verified
      @test response == transport_response_mock
    end

    @testset "Testing request with NamedTuple body" begin
      body = (
        query=(
          match_all=Dict(),
        ),
      )

      apply(transport_patch) do
        response = ElasticsearchClient.ElasticTransport.perform_request(client, "POST", "/_search", body=body)

        @test client.verified
        @test response == transport_response_mock
      end
    end
  end
end
