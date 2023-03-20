using Elasticsearch
using Test

host = Dict(
  :protocol => "http",
  :port => 80,
  :host => "127.0.0.1",
  :user => "user",
  :password => "pwd"
)

options = Dict{Symbol, Any}(
  :headers => Dict(
    "test-api-key" => "key",
    :content_type => "application/json"
  ),
  :resurrect_timeout => 0
)

@testset "Testinc ElasticTransport connection" begin
  @testset "Testing connection initailization" begin
    conn = Elasticsearch.ElasticTransport.Connections.Connection(;host=host, options=options)

    @test !conn.dead
    @test haskey(conn.headers, Elasticsearch.ElasticTransport.Connections.CONTENT_TYPE_STR)
    @test !haskey(conn.headers, :content_type)
    @test haskey(conn.headers, Elasticsearch.ElasticTransport.Connections.USER_AGENT_STR)
  end

  @testset "Testing building full_url" begin
    conn = Elasticsearch.ElasticTransport.Connections.Connection(;host=host, options=options)

    url = Elasticsearch.ElasticTransport.Connections.full_url(conn, "/endpoint", Dict("p" => 1))

    @test url == "http://user:pwd@127.0.0.1:80/endpoint?p=1"
  end

  @testset "Testing state functions" begin
    conn = Elasticsearch.ElasticTransport.Connections.Connection(;host=host, options=options)

    Elasticsearch.ElasticTransport.Connections.dead!(conn)

    @test conn.dead
    @test !isnothing(conn.dead_since)
    @test conn.failures > 0

    @test Elasticsearch.ElasticTransport.Connections.is_resurrectable(conn)
    
    Elasticsearch.ElasticTransport.Connections.resurrect!(conn)

    @test !conn.dead
    @test conn.failures > 0

    Elasticsearch.ElasticTransport.Connections.dead!(conn)
    Elasticsearch.ElasticTransport.Connections.healthy!(conn)

    @test !conn.dead
    @test isnothing(conn.dead_since)
    @test conn.failures == 0
  end
end
