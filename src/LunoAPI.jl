module LunoAPI

using HTTP, Base64, JSON

include("api.jl")

export set_auth_token, get_auth_token, get_price, get_balance, stop_all_orders



end # module
