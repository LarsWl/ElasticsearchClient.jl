using HTTP

abstract type ServerException <: Exception end

struct ServerError <: ServerException
  status
  message::String
end

const HTTP_STATUSES = Dict(
  300 => :MultipleChoices,
  301 => :MovedPermanently,
  302 => :Found,
  303 => :SeeOther,
  304 => :NotModified,
  305 => :UseProxy,
  307 => :TemporaryRedirect,
  308 => :PermanentRedirect,
  400 => :BadRequest,
  401 => :Unauthorized,
  402 => :PaymentRequired,
  403 => :Forbidden,
  404 => :NotFound,
  405 => :MethodNotAllowed,
  406 => :NotAcceptable,
  407 => :ProxyAuthenticationRequired,
  408 => :RequestTimeout,
  409 => :Conflict,
  410 => :Gone,
  411 => :LengthRequired,
  412 => :PreconditionFailed,
  413 => :RequestEntityTooLarge,
  414 => :RequestURITooLong,
  415 => :UnsupportedMediaType,
  416 => :RequestedRangeNotSatisfiable,
  417 => :ExpectationFailed,
  418 => :ImATeapot,
  421 => :TooManyConnectionsFromThisIP,
  426 => :UpgradeRequired,
  429 => :TooManyRequests,
  450 => :BlockedByWindowsParentalControls,
  494 => :RequestHeaderTooLarge,
  497 => :HTTPToHTTPS,
  499 => :ClientClosedRequest,
  500 => :InternalServerError,
  501 => :NotImplemented,
  502 => :BadGateway,
  503 => :ServiceUnavailable,
  504 => :GatewayTimeout,
  505 => :HTTPVersionNotSupported,
  506 => :VariantAlsoNegotiates,
  510 => :NotExtended
)

macro generate_exception_structures(http_statuses_dict)
  dict = eval(http_statuses_dict)
  # dict = HTTP_STATUSES
  return Expr(:block, map(values(dict)) do exception_name
    quote
      struct $exception_name <: ServerException
        status
        message::String
      end
    end
  end...)
end

@generate_exception_structures(HTTP_STATUSES)

macro transform_exceptions_to_types(http_statuses_dict)
  dict = eval(http_statuses_dict)
  Dict(k => eval(v) for (k, v) in dict)
end

const CODE_TO_EXCEPTION = @transform_exceptions_to_types(HTTP_STATUSES)

const HOST_UNREACHABLE_EXCEPTIONS = [HTTP.TimeoutError, HTTP.ConnectError]
