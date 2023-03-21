using HTTP
using URIs
using Mocking

const DEFAULT_HOST = "localhost:9200"

struct Client
  arguments::Dict
  options::Dict
  hosts::Vector
  send_get_body_as::String
  ca_fingerpring::Bool
  transport::Transport
end

function Client(arguments::Dict{Symbol, Any}=Dict{Symbol, Any}(); http_client::Module=HTTP)
  options = deepcopy(arguments)

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
    get(ENV, "ELASTICSEARCH_URL", DEFAULT_HOST)
  end
  hosts = extract_hosts(hosts_config, options)

  if haskey(arguments, :request_timeout)
    arguments[:transport_options][:request] = Dict(:timeout => arguments[:request_timeout])
  end

  transport = Transport(;hosts=hosts, options=arguments, http_client=http_client)

  Client(
    arguments,
    options,
    hosts,
    get(arguments, :send_get_body_as, "GET"),
    false,
    transport
  )
end

function perform_request(
  client::Client,
  method::String,
  path::String;
  params=Dict(),
  body::Union{Nothing,Dict}=nothing,
  headers::Union{Nothing,Dict}=nothing
)
  if method == "GET" && !isnothing(body)
    method = client.send_get_body_as
  end

  validate_ca_fingerprints(client)

  @mock perform_request(client.transport, method, path; params=params, body=body, headers=headers)
end

@warn "ca fingerprints validation is not implemented"
function validate_ca_fingerprints(::Client)
  @warn "ca fingerprints validation is not implemented"
end

function extract_hosts(hosts_config, options)
  hosts = if hosts_config isa String
    split(hosts_config, ",") .|> strip .|> String
  elseif hosts_config isa Vector
    hosts_config
  elseif hosts_config isa Dict || hosts_config isa URI
    [hosts_config]
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
      :host => get(host_info, 0, ""),
      :port => get(host_info, 1, "")
    )
  end

  host_parts
end

function parse_host_parts(host::URI)
  userinfo = split(host.userinfo, ":") .|> string

  Dict(
    :scheme => host.scheme,
    :user => get(userinfo, 0, ""),
    :password => get(userinfo, 1, ""),
    :host => host.host,
    :path => host.path,
    :port => host.port
  )
end

function parse_host_parts(host::Dict{Symbol, Any})
  host
end
