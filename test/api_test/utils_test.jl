using Test
using ElasticsearchClient
using JSON

@testset "Testing api utils" begin
  @testset "Testing _listify" begin
    @test ElasticsearchClient.API._listify("index") == "index"
    @test ElasticsearchClient.API._listify("index1", "index2") == "index1,index2"
    @test ElasticsearchClient.API._listify(["index1", "index2"]) == "index1,index2"
    @test ElasticsearchClient.API._listify(["index1", "index2"], "index3") == "index1,index2,index3"
  end

  @testset "Testing process_params" begin
    args = Dict(:a => 1, :b => 2, :c => ["index1", "index2"])

    params = ElasticsearchClient.API.process_params(args)

    @test get(params, :a, nothing) == args[:a]
    @test get(params, :b, nothing) == args[:b]
    @test get(params, :c, nothing) == "index1,index2"
  end

  @testset "Testing _bulkify" begin
    operation_meta = Dict(:_index => "test", :_id => 1)
    dict_operation = Dict(:index => operation_meta)
    dict_data = Dict(:field1 => 1, :field2 => 2)
    dict_operation_with_data = Dict(:index => merge(operation_meta, Dict(:data => dict_data)))
    
    string_operation = JSON.json(dict_operation)
    string_data = JSON.json(dict_data)

    @test ElasticsearchClient.API._bulkify(String[string_operation]) == "$string_operation\n"
    @test ElasticsearchClient.API._bulkify(String[string_operation, string_data]) == "$string_operation\n$string_data\n"
    @test ElasticsearchClient.API._bulkify(Dict[dict_operation, dict_data]) == "$string_operation\n$string_data\n"
    @test ElasticsearchClient.API._bulkify(Dict[dict_operation_with_data]) == "$string_operation\n$string_data\n"
  end
end
