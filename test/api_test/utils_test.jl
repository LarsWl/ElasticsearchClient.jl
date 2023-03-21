using Test
using Elasticsearch

@testset "Testing api utils" begin
  @testset "Testing _listify" begin
    @test Elasticsearch.API._listify("index") == "index"
    @test Elasticsearch.API._listify("index1", "index2") == "index1,index2"
    @test Elasticsearch.API._listify(["index1", "index2"]) == "index1,index2"
    @test Elasticsearch.API._listify(["index1", "index2"], "index3") == "index1,index2,index3"
  end

  @testset "Testing process_params" begin
    args = Dict(:a => 1, :b => 2, :c => ["index1", "index2"])

    params = Elasticsearch.API.process_params(args)

    @test get(params, :a, nothing) == args[:a]
    @test get(params, :b, nothing) == args[:b]
    @test get(params, :c, nothing) == "index1,index2"
  end
end
