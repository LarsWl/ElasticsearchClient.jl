using Mocking


"""
Returns results matching a query.

- `index::Union{String, Vector{String}}`: A comma-separated list of index names to search; use `_all` or empty string to perform the operation on all indices
- `analyzer::String`: The analyzer to use for the query string
- `analyze_wildcard::Bool`: specify whether wildcard and prefix queries should be analyzed (default: false)
- `ccs_minimize_roundtrips::Bool`: Indicates whether network round-trips should be minimized as part of cross-cluster search requests execution
- `default_operator::String`: The default operator for query string query (AND or OR) (options: AND, OR)
- `df::String`: The field to use as default where no field prefix is given in the query string
- `explain::Bool`: Specify whether to return detailed information about score computation as part of a hit
- `stored_fields::{String, Vector{String}}`: A comma-separated list of stored fields to return as part of a hit
- `docvalue_fields::{String, Vector{String}}` A comma-separated list of fields to return as the docvalue representation of a field for each hit
- `from::Integer`: Starting offset (default: 0)
- `force_synthetic_source::Bool`: Should this request force synthetic _source? Use this to test if the mapping supports synthetic _source and to get a sense of the worst case performance. Fetches with this enabled will be slower the enabling synthetic source natively in the index.
- `ignore_unavailable::Bool`: Whether specified concrete indices should be ignored when unavailable (missing or closed)
- `ignore_throttled::Bool`: Whether specified concrete, expanded or aliased indices should be ignored when throttled
- `allow_no_indices::Bool`: Whether to ignore if a wildcard indices expression resolves into no concrete indices. (This includes `_all` string or when no indices have been specified)
- `expand_wildcards::String`: Whether to expand wildcard expression to concrete indices that are open, closed or both. (options: open, closed, hidden, none, all)
- `lenient::Bool`: Specify whether format-based query failures (such as providing text to a numeric field) should be ignored
- `preference::String`: Specify the node or shard the operation should be performed on (default: random)
- `q::String`: Query in the Lucene query string syntax
- `routing::Union{String, Vector{String}}`: A comma-separated list of specific routing values
- `scroll::DateTime`: Specify how long a consistent view of the index should be maintained for scrolled search
- `search_type::String`: Search operation type (options: query_then_fetch, dfs_query_then_fetch)
- `size::Integer`: Number of hits to return (default: 10)
- `sort::Union{String, Vector{String}}`: A comma-separated list of <field>:<direction> pairs
- `_source::Union{String, Vector{String}}`: True or false to return the _source field or not, or a list of fields to return
- `_source_excludes::Union{String, Vector{String}}`: A list of fields to exclude from the returned _source field
- `_source_includes::Union{String, Vector{String}}`: A list of fields to extract and return from the _source field
- `terminate_after::Integer`: The maximum number of documents to collect for each shard, upon reaching which the query execution will terminate early.
- `stats::Union{String, Vector{String}}`: Specific 'tag' of the request for logging and statistical purposes
- `suggest_field::String`: Specify which field to use for suggestions
- `suggest_mode::String`: Specify suggest mode (options: missing, popular, always)
- `suggest_size::Integer`: How many suggestions to return in response
- `suggest_text::String`: The source text for which the suggestions should be returned
- `timeout::DateTime`: Explicit operation timeout
- `track_scores::Bool`: Whether to calculate and return scores even if they are not used for sorting
- `[Boolean|long] :track_total_hits Indicate if the number of documents that match the query should be tracked. A number can also be specified, to accurately track the total hit count up to the number.
- `allow_partial_search_results::Bool`: Indicate if an error should be returned if there is a partial search failure or timeout
- `typed_keys::Bool`: Specify whether aggregation and suggester names should be prefixed by their respective types in the response
- `version::Bool`: Specify whether to return document version as part of a hit
- `seq_no_primary_term::Bool`: Specify whether to return sequence number and primary term of the last modification of each hit
- `request_cache::Bool`: Specify if request cache should be used for this request or not, defaults to index level setting
- `batched_reduce_size::Integer`: The number of shard results that should be reduced at once on the coordinating node. This value should be used as a protection mechanism to reduce the memory overhead per search request if the potential number of shards in the request can be large.
- `max_concurrent_shard_requests::Integer`: The number of concurrent shard requests per node this search executes concurrently. This value should be used to limit the impact of the search on the cluster in order to limit the number of concurrent shard requests
- `pre_filter_shard_size::Integer`: A threshold that enforces a pre-filter roundtrip to prefilter search shards based on query rewriting if the number of shards the search request expands to exceeds the threshold. This filter roundtrip can limit the number of shards significantly if for instance a shard can not match any documents based on its rewrite method ie. if date filters are mandatory to match but the shard bounds and the query are disjoint.
- `rest_total_hits_as_int::Bool`: Indicates whether hits.total should be rendered as an integer or an object in the rest search response
- `min_compatible_shard_node::String`: The minimum compatible version that all shards involved in search should have for this request to be successful
- `headers::Dict`: Custom HTTP headers
- `body::Union{Dict,NamedTuple}`: The search definition using the Query DSL

See https://www.elastic.co/guide/en/elasticsearch/reference/current/search-search.html
"""
function search(client::Client; body=nothing, index=nothing, headers=Dict(), auth_params=nothing, kwargs...)
  arguments = Dict(kwargs)

  method = if isnothing(body)
    HTTP_GET
  else
    HTTP_POST
  end

  path = if !isnothing(index)
    "/$(_listify(index))/$(UNDERSCORE_SEARCH)"
  else
    "/$(UNDERSCORE_SEARCH)"
  end

  params = process_params(arguments)

  Response(
    @mock perform_request(client, method, path; params=params, auth_params=auth_params, headers=headers, body=body)
  )
end
