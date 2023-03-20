using HTTP
using Dates
using CodecZlib
using Retry
using Mocking
using JSON

const DEFAULT_PORT = 9200
const DEFAULT_PROTOCOL = "http"
const DEFAULT_RELOAD_AFTER = 10_000 # Requests
const DEFAULT_RESURRECT_AFTER = 60  # Seconds
const DEFAULT_MAX_RETRIES = 3 # Requests
const SANITIZED_PASSWORD = repeat("*", 14)

mutable struct Transport
  state_lock::ReentrantLock
  hosts::Vector
  options::Dict
  use_compression::Bool
  connections::Connections.Collection
  protocol::String
  counter::Integer
  counter_lock::ReentrantLock
  last_request_at::DateTime
  reload_connections::Bool
  reload_after::Integer
  resurrect_after::Integer
  retry_on_status::Vector{Integer}
end

function Transport(; hosts::Vector=[], options=Dict())
  !haskey(options, :http) && (options[:http] = Dict())
  !haskey(options, :retry_on_status) && (options[:retry_on_status] = Integer[])
  !haskey(options, :delay_on_retry) && (options[:delay_on_retry] = 0)

  Transport(
    ReentrantLock(),
    hosts,
    options,
    get(options, :compression, false),
    build_connections(hosts, options),
    get(options, :protocol, DEFAULT_PROTOCOL),
    0,
    ReentrantLock(),
    now(),
    get(options, :reload_connections, false),
    DEFAULT_RELOAD_AFTER,
    get(options, :resurrect_after, DEFAULT_RESURRECT_AFTER),
    options[:retry_on_status]
  )
end

function get_connection(transport::Transport, options=Dict())
  if now() > transport.last_request_at + Second(transport.resurrect_after)
    resurrect_dead_connections!(transport)
  end

  lock(transport.counter_lock) do
    transport.counter += 1
  end

  if transport.reload_connections && (transport.counter % transport.reload_after) == 0
    reload_connections!
  end

  Connections.get_connection(transport.connections)
end

function resurrect_dead_connections!(transport::Transport)
  foreach(Connections.resurrect!, Connections.dead(transport.connections))
end

@warn "Reload connections are not implemented"
function reload_connections!(transport::Transport)
  @warn "Reload connections are not implemented"
end

function build_connections(hosts::Vector, options::Dict)
  Connections.Collection(
    connections=connections_from_host(hosts, options),
    selector_type=get(options, :selector_type, Connections.DEFAULT_SELECTOR)
  )
end

function connections_from_host(hosts::Vector, options::Dict)
  map(hosts) do host
    host[:protocol] = get(host, :scheme) do
      get(options, :schema) do
        get(options[:http], :scheme, DEFAULT_PROTOCOL)
      end
    end

    if !haskey(host, :port)
      host[:port] = get(options, :port) do
        get(options[:http], :port, DEFAULT_PORT)
      end
    end

    if !haskey(host, :user) && (haskey(options, :user) || haskey(options[:http], :user))
      host[:user] = get(options, :user) do
        options[:http][:user]
      end
      host[:password] = get(options, :password) do
        options[:http][:password]
      end
    end

    Connections.Connection(; host=host, options=get(() -> Dict(), options, :transport_options))
  end
end

function perform_request(
  transport::Transport,
  method::String,
  path::String;
  params=Dict(),
  body::Union{Nothing,Dict}=nothing,
  headers::Union{Nothing,Dict}=nothing,
  opts=Dict()
)
  start = now()

  reload_on_failure = get(opts, :reload_on_failure, transport.reload_connections)
  delay_on_retry = get(opts, :delay_on_retry, transport.options[:delay_on_retry]) / 1000.0

  params = deepcopy(params)

  ignore = if haskey(params, :ignore)
    unique(Integer[pop!(params, :ignore)])
  else
    Integer[]
  end

  tries = 0
  response = nothing
  connection = nothing
  url = nothing

  @repeat DEFAULT_MAX_RETRIES try
    tries += 1
    connection = get_connection(transport)

    url = Connections.full_url(connection, path, params)

    headers = Connections.parse_headers(connection, headers)
    if !isnothing(body)
      body = JSON.json(body)
    end
    body, headers = compress_request(transport, body, headers)

    response = @mock HTTP.request(method, url; headers=headers, body=body, status_exception=false)
    connection.failures > 0 && healthy!(connection)

    if response.status >= 300 && in(response.status, transport.retry_on_status)
      raise_transport_error(response)
    end
  catch exception
    @retry if exception isa ServerException
      !isnothing(response) && !in(response.status, transport.retry_on_status) && throw(exception)

      @warn "[$(typeof(exception))] Attempt $(tries) to get response from $(url)"

      sleep(delay_on_retry)
    end

    if typeof(exception) in HOST_UNREACHABLE_EXCEPTIONS
      @error "[$(typeof(exception))] $(connection.host)"

      # Disable dead connections, before reload_connections implementation
      # Connections.dead!(connection)
    end

    @retry if reload_on_failure && tries < length(transport.connections) && in(typeof(exception), HOST_UNREACHABLE_EXCEPTIONS)
      @warn "[$(typeof(exception))] Reloading connections (attempt $(tries) of $(length(transport.connections)))"

      reload_connections!(transport)

      sleep(delay_on_retry)
    end

    host = !isnothing(connection) ? connection.host : ""
    @error "[$(typeof(exception))] $(exception) $host"
    throw(exception)
  finally
    transport.last_request_at = now()
  end

  duration = now() - start

  if response.status >= 300
    log_response(method, body, url, response, "N/A", duration)

    if !in(response.status, ignore)
      @error "[$(response.status)] $(response.body)"
      raise_transport_error(response)
    end
  end

  json = nothing
  took = "n/a"
  response_headers = Dict(response.headers)
  response_body = String(response.body)
  if !isempty(response_body) && !isnothing(match(r"json"i, get(response_headers, "content-type", "")))
    json = JSON.parse(response_body)
    took = get(json, "took", "n/a")
  end

  log_response(method, body, url, response.status, response_body, took, duration)
  haskey(response_headers, "Warning") && @warn response_headers["Warning"]

  if isnothing(json)
    HTTP.Response(response.status, response_headers, response_body)
  else
    HTTP.Response(response.status, response_headers, json)
  end
end

function compress_request(transport::Transport, body::String, headers::Dict)
  if transport.use_compression
    headers[Connections.CONTENT_ENCODING] = Connections.GZIP
    body = transcode(GzipCompressor, body) |> String
  elseif haskey(headers, Connections.CONTENT_ENCODING)
    delete!(headers, Connections.CONTENT_ENCODING)
  end

  (body, headers)
end

function compress_request(::Transport, body::Nothing, headers::Dict)
  if haskey(headers, Connections.CONTENT_ENCODING)
    delete!(headers, Connections.CONTENT_ENCODING)
  end

  ("", headers)
end

function raise_transport_error(response::HTTP.Response)
  error_type = if haskey(HTTP_STATUSES, response.status)
    eval(HTTP_STATUSES[response.status])
  else
    ServerError
  end

  throw(error_type(response.status, String(response.body)))
end

function log_response(method, body, url, response_status, response_body, took, duration)
  sanitized_url = replace(url, r"//(.+):(.+)@" => s"//\1:$SANITIZED_PASSWORD@")
  @info "$(uppercase(method)) $sanitized_url [status:$(response_status), request:$(duration), query:$(took)]"
  !isnothing(body) && @debug "> $(JSON.json(body))"
  @debug "< $(String(response_body))"
end