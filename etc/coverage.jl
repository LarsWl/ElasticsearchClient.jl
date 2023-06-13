using Pkg

Pkg.add("Coverage")

using Coverage

coverage = process_folder()

LCOV.writefile(joinpath(@__DIR__, "..", "coverage", "lcov.info"), coverage)