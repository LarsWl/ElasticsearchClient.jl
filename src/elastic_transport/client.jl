using HTTP
using URIs
using Mocking

const DEFAULT_PORT = 9200
const DEFAULT_PROTOCOL = "http"
const DEFAULT_HOST = "localhost"
const DEFAULT_URL = "$DEFAULT_PROTOCOL://$DEFAULT_HOST:$DEFAULT_PORT"
const SECURITY_PRIVILEGES_VALIDATION_WARNING = "The client is unable to verify that the server is Elasticsearch due to security privileges on the server side. Some functionality may not be compatible if the server is running an unsupported product."
const VALIDATION_WARNING = "The client is unable to verify that the server is Elasticsearch. Some functionality may not be compatible if the server is running an unsupported product."


"""
ElasticSearch client. Handling hosts configuration, verify elasticsearch and delegate requests to Transport

  function Client(;http_client::Module, kwargs...)

Create a client connected to an Elastic cluster.

# Possible arguments

- `http_client::Module`: A module that implement request method. Maybe useful if you need custom http layers. HTTP.jl used bu default. 
- `hosts`: Single host passed as a String, Dict or NamedTuple, or multiple hosts passed as an Array; `host`, `url`, `urls` keys are also valid
- `resurrect_after::Integer`: After how many seconds a dead connection should be tried again
- `reload_connection::Bool`: Reload connections after X requests (false by default)
- `randomize_hosts::Bool`: Shuffle connections on initialization and reload (false by default)
- `sniffer_timeout::Integer`: Timeout for reloading connections in seconds (1 by default)
- `retry_on_failure::Bool`: Retry X times when request fails before raising and exception (false by default)
- `delay_on_retry::Integer`: Delay in milliseconds between each retry (0 by default)
- `retry_on_status::Vector{Integer}`: Retry when specific status codes are returned
- `reload_on_failure::Bool`: Reload connections after failure (false by default)
- `request_timeout::Integer`: The request timeout to be passed to transport in options
- `transport_options`: Options to be passed to Connection. Now work only `headers` option
- `selector::Connections.AbstractSelector` A struct type of selector strategy. 
- `send_get_body_as`: Specify the HTTP method to use for GET requests with a body. (Default: GET)
- `compression` Whether to compress requests. Gzip compression will be used. The default is false.
  Responses will automatically be inflated if they are compressed.
"""
mutable struct Client
  arguments::Dict
  options::Dict
  hosts::Vector
  send_get_body_as::String
  verified::Bool
  transport::Transport
end

function Client(;http_client::Module=HTTP, kwargs...)
  options = deepcopy(Dict{Symbol, Any}(kwargs))
  arguments = options

  get!(options, :reload_connections, false)
  get!(options, :retry_on_failure, false)
  get!(options, :delay_on_retry, 0)
  get!(options, :reload_on_failure, false)
  get!(options, :randomize_hosts, false)
  get!(() -> Dict(), options, :transport_options)
  get!(() -> Dict(), options, :http)

  host_keys = [:hosts, :host, :url, :urls]
  host_key_index = findfirst(key -> haskey(arguments, key), host_keys)
  hosts_config = if !isnothing(host_key_index)
    arguments[host_keys[host_key_index]]
  else
    get(ENV, "ELASTICSEARCH_URL", DEFAULT_URL)
  end
  hosts = extract_hosts(hosts_config, options)

  if haskey(arguments, :request_timeout)
    arguments[:transport_options][:request] = Dict(:timeout => arguments[:request_timeout])
  end

  transport = Transport(; hosts=hosts, options=arguments, http_client=http_client)

  Client(
    arguments,
    options,
    hosts,
    get(arguments, :send_get_body_as, "GET"),
    false,
    transport
  )
end

function verify_elasticsearch(client::Client)
  response = nothing
  try
    response = elastisearch_validation_request(client)
  catch exc
    if typeof(exc) in [Forbidden, Unauthorized, RequestEntityTooLarge]
      client.verified = true
      @warn SECURITY_PRIVILEGES_VALIDATION_WARNING
      return
    else
      @warn VALIDATION_WARNING
      return
    end
  end

  body = response.body
  version = get(() -> Dict(), body, "version") |> version -> get(version, "number", nothing)

  verify_with_version_and_headers(client, version, response.headers)
end

@warn "Version verification isn't implemented"
function verify_with_version_and_headers(client::Client, _headers, _version)
  @warn "Version verification isn't implemented"
  client.verified = true
end

function elastisearch_validation_request(client::Client)
  @mock perform_request(client.transport, "GET", "/")
end

"""
Low-level request to Elastic cluster.

# Arguments

- `client::ElasticTransport.Client`
- `method::String`
- `path::String`: elastic endpoint. Must start with /

# Keyword arguments
- `params::Dict`: Query params
- `body::Union{Nothing, Dict}`: HTTP body, default Nothing
- `headers::Union{Nothing, Dict}`: HTTP headers. They are merged with default headers. Default Nothing
"""
function perform_request(
  client::Client,
  method::String,
  path::String;
  params=Dict(),
  auth_params=nothing,
  body::Union{Nothing,Dict,NamedTuple,String}=nothing,
  headers::Union{Nothing,Dict}=nothing
)
  if method == "GET" && !isnothing(body)
    method = client.send_get_body_as
  end

  if !client.verified
    verify_elasticsearch(client)
  end

  @mock perform_request(
    client.transport,
    method,
    path;
    params=params,
    auth_params=auth_params,
    body=body,
    headers=headers
  )
end

function extract_hosts(hosts_config, options)
  hosts = if hosts_config isa String
    split(hosts_config, ",") .|> strip .|> String
  elseif hosts_config isa Vector
    hosts_config
  elseif hosts_config isa Dict || hosts_config isa URI
    [hosts_config]
  elseif hosts_config isa NamedTuple
    [Dict(zip(keys(hosts_config), values(hosts_config)))]
  else
    error("Can't extract hosts")
  end

  map(host -> parse_host(host, options), hosts)
end

function parse_host(host, options)
  host_parts = parse_host_parts(host)

  get!(options[:http], :user) do
    get(host_parts, :user, "")
  end

  get!(options[:http], :password) do
    get(host_parts, :password, "")
  end

  if haskey(host_parts, :port) && host_parts[:port] isa String
    host_parts[:port] = parse(Int32, host_parts[:port])
  end

  if haskey(host_parts, :path)
    host_parts[:path] = chopsuffix(host_parts[:path], "/")
  end

  host_parts
end

function parse_host_parts(host::String)
  host_parts = if !isnothing(match(r"^[a-z]+\:\/\/", host))
    parts = URI(host) |> parse_host_parts

    get!(parts, :port) do
      parts[:scheme] == "https" ? 443 : DEFAULT_PORT
    end

    parts
  else
    host_info = split(host, ":")

    Dict(
      :host => get(host_info, 0, DEFAULT_HOST),
      :port => parse(Int16, get(host_info, 1, string(DEFAULT_PORT)))
    )
  end

  host_parts
end

function parse_host_parts(host::URI)
  userinfo = split(host.userinfo, ":") .|> string
  port = if isempty(host.port)
    DEFAULT_PORT
  else
    parse(Int16, host.port)
  end

  Dict(
    :scheme => host.scheme,
    :user => get(userinfo, 0, ""),
    :password => get(userinfo, 1, ""),
    :host => host.host,
    :path => host.path,
    :port => port
  )
end

function parse_host_parts(host::Union{Dict{Symbol,Any}, NamedTuple})
  host
end
