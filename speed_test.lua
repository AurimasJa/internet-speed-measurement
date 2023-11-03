local SpeedTest = require("modules.SpeedTest")
local argparse = require("argparse")
local cjson = require("cjson")
local ErrorsHandling = require("modules.errors_handling")
local errorMessage, serverList, country, download, upload, serverData, bestServer = nil, nil, nil, nil, nil, nil, nil
local parser = argparse("lua_scr", "Internet speed measurement")
parser:command_target("command")
parser:flag("-g --get_geolocation"):description("Find your location")
parser:flag("-d --download_speed"):description("Measure download speed")
parser:flag("-u --upload_speed"):description("Measure upload speed")
parser:flag("-f --find_best_location"):description("Find best server latency")
parser:flag("-p --perform_whole"):description("Find your location")
parser:argument("address"):args("*"):description("Address for your download and upload speed measurement")

local args = parser:parse()

if args["perform_whole"] then
    errorMessage, country = SpeedTest.get_geolocation()
    if errorMessage then
        print(errorMessage)
    end

    serverList = SpeedTest.get_server_list()
    serverData = SpeedTest.find_server_latency(serverList, country)
    bestServer = SpeedTest.find_best_location(serverData)
    if not bestServer then
        return print(ErrorsHandling.custom_error_by_key("best_server_not_valid"))
    else
        local decodedBestServer, success
        success, errorMessage = pcall(function()
            decodedBestServer = cjson.decode(bestServer)
        end)

        if not success then
            return print(ErrorsHandling.custom_error_by_key("decode_fail"))
        end
        errorMessage, download = SpeedTest.download_speed(decodedBestServer.best_server)
        if errorMessage then
            print(errorMessage)
        end
        errorMessage, upload = SpeedTest.upload_speed(decodedBestServer.best_server)
        if errorMessage then
            print(errorMessage)
        end
        if country then
            print(country)
        end
        if bestServer then
            print(bestServer)
        end
        if download then
            print(download)
        end
        if upload then
            print(upload)
        end
    end
elseif args["get_geolocation"] then
    errorMessage, country = SpeedTest.get_geolocation()
    if errorMessage then
        print(errorMessage)
    else
        print(country)
    end
elseif args["download_speed"] then
    errorMessage, download = SpeedTest.download_speed(args.address[1])
    if errorMessage then
        print(errorMessage)
    else
        print(download)
    end
elseif args["upload_speed"] then
    errorMessage, upload = SpeedTest.upload_speed(args.address[1])

    if errorMessage then
        print(errorMessage)
    else
        print(upload)
    end
elseif args["find_best_location"] then
    errorMessage, country = SpeedTest.get_geolocation()
    if errorMessage then
        print(errorMessage)
    else
        print(country)
    end
    serverList = SpeedTest.get_server_list()
    serverData = SpeedTest.find_server_latency(serverList, country)
    bestServer = SpeedTest.find_best_location(serverData)
    if bestServer then
        print(bestServer)
    end
else
    print(parser:get_help())
end
