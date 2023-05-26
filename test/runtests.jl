using Elasticsearch
using Test
using Dates

function log(str)
    "$(Dates.format(Dates.now(), "dd.mm.yyyy HH:MM:SS")) - $(str)\n"
end

tests = [
  "elastic_transport_test/connections_test.jl",
  "elastic_transport_test/transport_test.jl",
  "elastic_transport_test/client_test.jl",
  "api_test/utils_test.jl",
  "api_test/search_test.jl",
  "api_test/search_template_test.jl",
  "api_test/put_script_test.jl",
  "api_test/index_test.jl",
  "api_test/bulk_test.jl",
  "api_test/cat/indices_test.jl",
  "api_test/indices/delete_test.jl",
  "api_test/indices/create_test.jl",
  "api_test/indices/exists_alias_test.jl",
  "api_test/indices/get_test.jl",
  "api_test/indices/put_alias_test.jl",
  "api_test/indices/exists_test.jl",
  "api_test/indices/refresh_test.jl"
]

@info log("Running tests....")
Test.@testset verbose = true showtiming = true "All tests" begin
    for test in tests
        @info log("Test: " * test)
        Test.@testset "$test" begin
            include(test)
        end
    end
end
@info log("done.")
