function _listify(args...)
  join(map(_listify, args), ",")
end

function _listify(args::Vector)
  join(map(_listify, args), ",")
end

function _listify(arg::String)
  arg
end

function process_params(arguments::Dict)
  params = Dict()

  for (key, value) in collect(arguments)
    if value isa Vector || value isa Tuple
      params[key] = _listify(value)
    else
      params[key] = value
    end
  end

  params
end
