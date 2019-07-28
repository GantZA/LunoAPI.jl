const API_URL = "https://api.mybitx.com/api/1/"


function set_auth_token(token="")
    if token == ""
        auth_token = readline("src/auth_token.txt")
        ENV["luno_auth_token"] = base64encode(auth_token)
    else
        ENV["luno_auth_token"] = base64encode(token)
    end
end

function get_auth_token(token="")
    if get(ENV, "luno_auth_token", false) == false
        set_auth_token(token)
        return Dict("Authorization" => "Basic " * ENV["luno_auth_token"])
    else
        return Dict("Authorization" => "Basic " * ENV["luno_auth_token"])
    end
end


function get_price(pair="XBTZAR")
    query_dict = Dict("pair" => pair)
    resp = JSON.parse(
        String(
            HTTP.get(API_URL * "ticker";
                query=query_dict).body))

    return Dict(
    "timestamp" => resp["timestamp"],
    "bid" => parse(Float64, resp["bid"]),
    "ask" => parse(Float64, resp["ask"]),
    "last_trade" => parse(Float64, resp["last_trade"]),
    "rolling_24h_vol" => parse(Float64, resp["rolling_24_hour_volume"]))
end


function get_balance(token="")
    price_dict = get_price()
    auth_dict = get_auth_token(token)

    resp = JSON.parse(
        String(
            HTTP.get(API_URL * "balance";
                headers=auth_dict).body))

    BTC_bal = resp["balance"][2]
    ZAR_bal = resp["balance"][3]

    ZAR = Dict()
    BTC = Dict()
    BTC["amount"] = parse(Float64,BTC_bal["balance"])
    BTC["rand_value"] = BTC["amount"] * price_dict["last_trade"]
    ZAR["amount"] = parse(Float64,ZAR_bal["balance"])
    ZAR["btc_value"] = ZAR["amount"]/price_dict["last_trade"]
    return BTC, ZAR, price_dict
end

function post_limit_order(token="", pair="XBTZAR", type="ASK", price=300000,
    volume=0.0005, post_only=true)

    auth_dict = get_auth_token(token)
    query_dict = Dict(
        "pair" => pair,
        "type" => type,
        "volume" => string(volume),
        "price" => string(price),
        "post_only" => post_only)

    resp = HTTP.post(API_URL * "postorder";
        headers = auth_dict,
        query = query_dict)
    if resp.status == 200
        println("Order sent successfully")
    end
end

function stop_all_orders(token="")
    auth_dict = get_auth_token(token)
    query_dict = Dict("pair" => "XBTZAR", "state" => "PENDING")
    resp = JSON.parse(
        String(
            HTTP.get(API_URL * "listorders" ;
                headers = auth_dict, query = query_dict).body))
    if resp["orders"] != nothing
        for order in resp["orders"]
            orderID = Dict("order_id" => order["order_id"])
            HTTP.post(API_URL * "stoporder";
                headers = auth_dict, query = orderID)

            order_id = orderID["order_id"]
            pair = order["pair"]
            volume = order["limit_volume"]
            price = order["limit_price"]
            type = order["type"]

            println("$type limit order $order_id cancelled for pair $pair at price $price for volume $volume")
        end
    else
        println("No orders pending")
    end
end

stop_all_orders()
