const USER_AGENT_STR = "User-Agent"
const USER_AGENT_REGEX = r"user-?_?agent"i
const ACCEPT_ENCODING = "Accept-Encoding"
const CONTENT_ENCODING = "Content-Encoding"
const CONTENT_TYPE_STR = "Content-Type"
const CONTENT_TYPE_REGEX = r"content-?_?type"i
const DEFAULT_CONTENT_TYPE = "application/json"
const GZIP = "gzip"
const GZIP_FIRST_TWO_BYTES = "1f8b"
const HEX_STRING_DIRECTIVE = "H*"

using URIs
using Dates

const DEFAULT_RESURRECT_TIMEOUT = 60

mutable struct Connection
  host::Dict
  options::Dict
  headers::Dict
  verified::Bool
  state_lock::ReentrantLock
  dead::Bool
  failures::Integer
  dead_since::Union{Nothing,DateTime}
end

function Connection(; host::Dict=Dict(), options::Dict=Dict(), use_compression::Bool=false)
  !haskey(options, :resurrect_timeout) && (options[:resurrect_timeout] = DEFAULT_RESURRECT_TIMEOUT)

  headers = get(() -> Dict(), options, :headers) |>
            headers_opts -> configure_headers(headers_opts, use_compression)

  Connection(
    host,
    options,
    headers,
    false,
    ReentrantLock(),
    false,
    0,
    nothing
  )
end

function configure_headers(headers::Dict, use_compression::Bool)
  headers[CONTENT_TYPE_STR] = find_header_value(() -> DEFAULT_CONTENT_TYPE, headers, CONTENT_TYPE_REGEX)
  headers[USER_AGENT_STR] = find_header_value(() -> user_agent_header(), headers, USER_AGENT_REGEX)
  use_compression && (headers[ACCEPT_ENCODING] = GZIP)

  headers
end

function find_header_value(default_func::Function, headers, regex)
  headers_keys = collect(keys(headers))
  key_index = findfirst(headers_keys) do k
    string(k) |>
    lowercase |>
    lower_k -> match(regex, lower_k) |>
               regex_match -> !isnothing(regex_match)
  end

  isnothing(key_index) && return default_func()

  pop!(headers, headers_keys[key_index])
end

function user_agent_header()
  "elasticsearch-julia/$(VERSION)"
end

function full_url(connection::Connection, path::String, params::Dict=Dict())
  userinfo = nothing
  if haskey(connection.host, :user)
    userinfo = "$(escape_string(connection.host[:user])):$(escape_string(connection.host[:password]))"
  end

  uri = if isnothing(userinfo)
    URI(;
      scheme=connection.host[:protocol],
      host=connection.host[:host],
      port=connection.host[:port],
      query=params,
      path=get(connection.host, :path, "") * path
    )
  else
    URI(;
      scheme=connection.host[:protocol],
      host=connection.host[:host],
      port=connection.host[:port],
      userinfo=userinfo,
      query=params,
      path=get(connection.host, :path, "") * path
    )
  end

  string(uri)
end

function resurrect!(conn::Connection)
  is_resurrectable(conn) || return

  lock(() -> conn.dead = false, conn.state_lock)
end

function is_resurrectable(conn::Connection)
  conn.dead || return false

  lock(conn.state_lock) do
    now() > conn.dead_since + Second(conn.options[:resurrect_timeout] * 2^(conn.failures - 1))
  end
end

function healthy!(conn::Connection)
  lock(conn.state_lock) do
    conn.dead = false
    conn.failures = 0
    conn.dead_since = nothing
  end
end

function dead!(conn::Connection)
  lock(conn.state_lock) do
    conn.dead = true
    conn.failures += 1
    conn.dead_since = now()
  end
end

function parse_headers(conn::Connection, headers::Union{Nothing,Dict})
  if !isnothing(headers)
    merge(conn.headers, headers)
  else
    copy(conn.headers)
  end
end

function Base.:(==)(src::Connection, other::Connection)
  src.host[:protocol] == other.host[:protocol] &&
    src.host[:host] == other.host[:host] &&
    src.host[:port] == other.host[:port]
end
