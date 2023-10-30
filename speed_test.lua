local Calculator = require("calculator")
local argparse = require("argparse")
local cjson = require "cjson"

local success, error, result, serverList, country = nil, nil, nil, nil, nil

local parser = argparse("lua_scr", "Internet speed calculator")
parser:command_target("command")
parser:flag("--get_geolocation"):description("Find your location")
parser:flag("--download_speed"):description("Measure download speed")
parser:flag("--upload_speed"):description("Measure upload speed")
parser:flag("--find_best_location"):description("Find best speed")
parser:flag("--perform_whole"):description("Find your location")
parser:argument("address"):args("*"):description("Address for your download and upload speed measurement")

local args = parser:parse()

if args["perform_whole"] then
    success, error = pcall(Calculator.download_speed, "speed-kaunas.telia.lt:8080/")
   
    if not success then
        print("There was an error connecting to the server " .. error)
    end

    success, error = pcall(Calculator.upload_speed, "https://speedtest.kis.lt.prod.hosts.ooklaserver.net:8080/")
   
    if not success then
        print("There was an error connecting to the server" .. error)
    end

    success, country = pcall(Calculator.get_geolocation)

    if not success then
        print("Ip address is incorrect or connection was terminated")
    else
        print(country)
    end

    success, serverList = pcall(Calculator.get_server_list)

    if not success then
        print("Ip address is incorrect or connection was terminated")
    end

    if serverList then
        local serverData = cjson.decode(serverList[1])
        for _, server in pairs(serverData) do
            if server.country == country then
                success, result = pcall(Calculator.find_server_latency, server.host, server)

                if success then
                    server.latency = result
                else
                    print("There was an error connecting to the server" .. " - " .. server.host)
                end
            end
        end
        success, result = pcall(Calculator.find_best_location, serverData)

        if success then
            print(result)
        else
            print("There was an error finding best server")
        end
    end
elseif args["get_geolocation"] then
    success, result = pcall(Calculator.get_geolocation)

    if not success then
        print("Ip address is incorrect or connection was terminated")
    else
        print(result)
    end

elseif args["download_speed"] then
    success, error = pcall(Calculator.download_speed, args.address[1])

    if not success then
        print("There was an error connecting to the server" .. error)
    end

elseif args["upload_speed"] then
    success, error = pcall(Calculator.upload_speed, args.address[1])

    if not success then
        print("There was an error connecting to the server" .. error)
    end

elseif args["find_best_location"] then
    success, country = pcall(Calculator.get_geolocation)

    if not success then
        print("Ip address is incorrect or connection was terminated")
    else
        print(country)
    end

    success, serverList = pcall(Calculator.get_server_list)

    if not success then
        print("Ip address is incorrect or connection was terminated")
    end

    if serverList then
        local serverData = cjson.decode(serverList[1])

        for _, server in pairs(serverData) do
            if server.country == country then
                success, result = pcall(Calculator.find_server_latency, server.host, server)

                if success then
                    server.latency = result
                else
                    print("There was an error connecting to the server" .. " - " .. server.host)
                end
            end
        end
        success, result = pcall(Calculator.find_best_location, serverData)

        if success then
            print(result)
        else
            print("There was an error finding best server")
        end
    end
end