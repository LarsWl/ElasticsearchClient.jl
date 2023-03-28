using HTTP
using Mocking

const DEFAULT_SNIFFING_TIMEOUT = 1
const SNIFFING_PROTOCOL = "http"

struct SniffingTimetoutError <: Exception end

function sniff_hosts(transport::Transport)
  nodes = perform_sniff_request_with_timeout(transport).body
  
  map(collect(nodes["nodes"])) do (id, info)
    if haskey(info, SNIFFING_PROTOCOL)
      host, port = parse_publish_address(info[SNIFFING_PROTOCOL]["publish_address"])

      Dict(
        :id => id,
        :name => get(info, "name", nothing),
        :version => get(info, "version", nothing),
        :host => host,
        :port => parse(Int16, port),
        :roles => get(info, "roles", nothing),
        :attributes => get(info, "attributes", nothing)
      )
    else
      missing
    end
  end |> skipmissing |> collect
end

function parse_publish_address(publish_address::String)
  if !isnothing(match(r"^inet\[.*\]$", publish_address))
    parse_address_port(publish_address[begin + 6:end - 1])
  elseif !isnothing(match(r"/", publish_address))
    parts = split(publish_address, "/") .|> String

    [parts[begin], parse_address_port(parts[end])[end]]
  else
    parse_address_port(publish_address)
  end

end

function parse_address_port(publish_address::String)
  # If publish address is ipv6
  if !isnothing(match(r"[\[\]]", publish_address))
    parts = match(r"\A\[(.+)\](?::(\d+))?\z", publish_address)

    [parts[1], parts[2]]
  else
    split(publish_address, ":")
  end
end

function perform_sniff_request_with_timeout(transport::Transport)
  task = @task(
    @mock perform_request(
      transport,
      "GET",
      "_nodes/$SNIFFING_PROTOCOL",
      opts = Dict(:reload_on_failure => false)
    )
  )
  schedule(task)
  Timer(DEFAULT_SNIFFING_TIMEOUT) do _timer
    istaskdone(task) || Base.throwto(task, SniffingTimetoutError())
  end

  try
    fetch(task)
  catch
    throw(task.exception)
  end
end

function sniffing_timeout(transport::Transport)
  get(transport.options, :sniffing_timeout, DEFAULT_SNIFFING_TIMEOUT)
end
