
function set_auth_token(token)
    if token == ""
        auth_token = readline("auth_token.txt")
        ENV["luno_auth_token"] = base64encode(auth_token)
    else
        ENV["luno_auth_token"] = base64encode(token)
    end
end

function get_auth_token(auth=true)
    if auth
        return Dict("Authorization" => "Basic " * ENV["luno_auth_token"])
    else
        set_auth_token()
        return Dict("Authorization" => "Basic " * ENV["luno_auth_token"])
    end
end


function get_price(pair="XBTZAR")
    query_dict = Dict("pair" => pair)
    resp = JSON.parse(
        String(
            HTTP.get("https://api.mybitx.com/api/1/ticker";
                query=query_dict).body))

    return Dict(
    "timestamp" => resp["timestamp"],
    "bid" => parse(Float64, resp["bid"]),
    "ask" => parse(Float64, resp["ask"]),
    "last_trade" => parse(Float64, resp["last_trade"]),
    "rolling_24h_vol" => parse(Float64, resp["rolling_24_hour_volume"]))
end

function get_balance(auth=true)
    price_dict = get_price()
    auth_dict = get_auth_token(auth)

    resp = JSON.parse(
        String(
            HTTP.get("https://api.mybitx.com/api/1/balance";
                headers=auth_dict).body))

    BTC_bal = resp["balance"][2]
    ZAR_bal = resp["balance"][3]
    BTC_Bal["amount"] = parse(Float64,BTC_Bal["balance"])
    BTC_Bal["rand_value"] = BTC_Bal["btc_am"] * price["Last Trade"]
    Zar_Bal["amount"] = parse(Float64,Zar_Bal["balance"])
    Zar_Bal["btc_value"] = Zar_Bal["rand_val"]/price["Last Trade"]
    return BTC_Bal, ZAR_bal, price
end

function stop_all_orders(auth=true)
    auth_dict = get_auth_token(auth)
    query_dict = Dict("pair" => "XBTZAR", "state" => "PENDING")
    resp = JSON.parse(
        String(
            HTTP.get("https://api.mybitx.com/api/1/listorders" ;
                headers = header, query = query_dict).body))

    for order in resp["orders"]
        orderID = Dict("order_id" => order["order_id"])
        HTTP.post("https://api.mybitx.com/api/1/stoporder";
            headers = auth_dict, query = orderID)
    end
end
