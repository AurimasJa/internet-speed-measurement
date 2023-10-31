local SpeedTest = require("speedtest")
local argparse = require("argparse")
local cjson = require("cjson")
local errorMessage, serverList, country, download_time, upload_time, download_speed, serverData, bestServer, upload_speed = nil, nil, nil,nil, nil, nil, nil, nil, nil
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
        print("Error: ", errorMessage)
    else
        print(country)
    end

    serverList = SpeedTest.get_server_list()
    serverData = SpeedTest.find_server_latency(serverList, country)
    bestServer = SpeedTest.find_best_location(serverData)
    if not bestServer then
        print("Error: getting best server")
    else
        local decodedBestServer = cjson.decode(bestServer)
        errorMessage, download_time, download_speed = SpeedTest.download_speed()
        if errorMessage then
            print("Error: ", errorMessage)
        end
        errorMessage, upload_time, upload_speed = SpeedTest.upload_speed(decodedBestServer.best_server)
        if errorMessage then
            print("Error: ", errorMessage)
        end
        if country then
            print(country)
        end
        if bestServer then
            print(bestServer)
        end
        if download_time and download_speed then
            print("Download time (in seconds): " .. string.format("%.4f", download_time),
                "Speed: " .. string.format("%.4f", download_speed) .. " Mbps")
        end
        if upload_time and upload_speed then
            print("Upload: " .. string.format("%.4f", upload_time) .. " total time passed (seconds)",
                string.format("%.4f", upload_speed) .. " Mbps")
        end
    end
elseif args["get_geolocation"] then
    errorMessage, country = SpeedTest.get_geolocation()
    if errorMessage then
        print("Error: ", errorMessage)
    else
        print(country)
    end
elseif args["download_speed"] then
    errorMessage, download_time, download_speed = SpeedTest.download_speed(args.address[1])
    if errorMessage then
        print("Error: ", errorMessage)
    else
        print("Download time (in seconds): " ..
            string.format("%.4f", download_time),
            "Speed: " .. string.format("%.4f", download_speed) .. " Mbps")
    end
elseif args["upload_speed"] then
    errorMessage, upload_time, upload_speed = SpeedTest.upload_speed(args.address[1])

    if errorMessage then
        print("Error: ", errorMessage)
    else
        print("Upload: " .. string.format("%.4f", upload_time) .. " total time passed (seconds)",
            string.format("%.4f", upload_speed) .. " Mbps")
    end
elseif args["find_best_location"] then
    errorMessage, country = SpeedTest.get_geolocation()
    if errorMessage then
        print("Error: ", errorMessage)
    else
        print(country)
    end

    serverList = SpeedTest.get_server_list()
    SpeedTest.find_server_latency(serverList, country)
else
    print(parser:get_help())
end
