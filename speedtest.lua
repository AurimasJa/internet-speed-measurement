local curl = require("cURL")
local cjson = require("cjson")
local socket = require "socket"
local ErrorHandling = require("error_handling")

local SpeedTest = {}
local success, result = nil, nil


local download_started = socket.gettime()
local function download_progress(dltotal, dlnow, _, _)
    local speed = dlnow / (socket.gettime() - download_started)
    local averageSpeed = speed / 1024 / 1024 * 8
    local data = {
        download = {
            dltotal = string.format("%.1f", dltotal / 1024 / 1024 * 8) .. "Mb",
            dlnow = string.format("%.1f", dlnow / 1024 / 1024 * 8) .. "Mbps",
            averageSpeed = string.format("%.4f", averageSpeed) .. " Mbps"
        }
    }
    if dltotal > 0 then print(cjson.encode(data)) end
end

USER_AGENT =
"Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/109.0.0.0 Safari/537.36"

function SpeedTest.download_speed(url)
    if not url then
        return ErrorHandling.custom_error("URL is not provided")
    end
    local easy = curl.easy {
        url = url .. "/download",
        useragent = USER_AGENT,
        connecttimeout = 3,
        writefunction = io.open("/dev/null", "wb"),
        noprogress = false,
        timeout = 10,
        progressfunction = download_progress
    }
    download_started = socket.gettime()
    success, result = pcall(easy.perform, easy)
    if not success then
        local errorMessage = ErrorHandling.handle_error_message(result)
        if not (string.match(errorMessage, "28")) or easy:getinfo_connect_time() == 0 then
            errorMessage = ErrorHandling.custom_error(errorMessage)
            return errorMessage
        end
    end
    print("Test completed successfully")
    local download_ended = socket.gettime()
    local download_time = download_ended - download_started
    local speed = easy:getinfo_speed_download() / 1024 / 1024 * 8
    easy:close()
    return nil, download_time, speed
end

local upload_started = socket.gettime()
local function upload_progress(_, _, _, upnow)
    local speed = upnow / (socket.gettime() - upload_started)
    local averageSpeed = speed / 1024 / 1024 * 8
    local data = {
        upload = {
            upnow = string.format("%.1f", upnow / 1024 / 1024 * 8) .. "Mb",
            averageSpeed = string.format("%.4f", averageSpeed) .. " Mbps"
        }
    }
    if upnow > 0 and averageSpeed > 0 then print(cjson.encode(data)) end
end

function SpeedTest.upload_speed(url)
    if not url then
        return ErrorHandling.custom_error("URL is not provided")
    end

    local easy = curl.easy({
        url = url .. "/upload",
        useragent = USER_AGENT,
        httppost = curl.form({
            file = { file = "/dev/zero", type = "text/plain", name = "zeros" }
        }),
        post = true,
        progressfunction = upload_progress,
        noprogress = false,
        writefunction = io.open("/dev/null", "r+"),
        timeout = 10,
    })

    upload_started = socket.gettime()

    success, result = pcall(easy.perform, easy)
    if not success then
        local errorMessage = ErrorHandling.handle_error_message(result)
        if not (string.match(errorMessage, "28")) or easy:getinfo_connect_time() == 0 then
            return ErrorHandling.custom_error(errorMessage)
        end
    end

    print("Test completed successfully")
    local upload_ended = socket.gettime()
    local upload_time = upload_ended - upload_started
    local speed = easy:getinfo_speed_upload() / 1024 / 1024 * 8

    easy:close()
    return nil, upload_time, speed
end

local response_data = {}
local function table_insert(data)
    table.insert(response_data, data)
end
function SpeedTest.get_geolocation()
    local easy = curl.easy {
        url = "https://api.myip.com/",
        writefunction = table_insert,
    }
    success, result = pcall(easy.perform, easy)
    if not success then
        easy:close()
        local errorMessage = ErrorHandling.handle_error_message(result)
        return ErrorHandling.custom_error(errorMessage)
    end

    easy:close()
    local temp = table.concat(response_data)
    local data_json = cjson.decode(temp)
    local country = nil
    for key, value in pairs(data_json) do
        if key == "country" then
            country = value
            break
        end
    end
    local json = cjson.encode({ country = country })
    return nil, json
end

function SpeedTest.download_file()
    local file = assert(io.open("speedtest_server_list.json", "w"))
    local easy = curl.easy {
        url = "https://raw.githubusercontent.com/AurimasJa/server-list-speed-test/main/speedtest_server_list.json",
        writefunction = file
    }
    success, result = pcall(easy.perform, easy)
    if not success then
        file:close()
        local errorMessage = ErrorHandling.handle_error_message(result)
        return ErrorHandling.custom_error(errorMessage)
    end
    file:close()
end

function SpeedTest.get_server_list()
    response_data = {}
    local file = io.open("speedtest_server_list.json", "r")
    if file then
        local content = assert(file:read("*all"))
        file:close()
        table.insert(response_data, content)
    else
        SpeedTest.download_file()
        return SpeedTest.get_server_list()
    end
    return response_data
end

function SpeedTest.find_server_latency(serverList, country)
    if not country then
        return ErrorHandling.custom_error("Country is not provided")
    end
    local decodedCountry = cjson.decode(country)
    if not serverList then
        return ErrorHandling.custom_error("Server list is not provided")
    end
    local serverData = cjson.decode(serverList[1])
    for _, server in pairs(serverData) do
        if server.country == decodedCountry.country then
            local easy = curl.easy {
                url = server.host .. "/upload.php",
                connecttimeout = 3
            }
            local start_time = socket.gettime()

            success, result = pcall(easy.perform, easy)

            local end_time = socket.gettime()
            local latency = end_time - start_time

            if not success then
                print("There was an error connecting to the server" .. " - " .. server.host)
            else
                server.latency = latency
            end
        end
    end
    return serverData
end

function SpeedTest.find_best_location(servers)
    local best_server = nil
    local best_latency = math.huge
    for _, value in pairs(servers) do
        if value.latency ~= nil and value.latency < best_latency then
            best_latency = value.latency
            best_server = value.host
        end
    end
    if not best_server then
        return print("There were no servers to compare")
    end
    local results = {
        best_server = best_server,
        best_latency = string.format("%.6f", best_latency)
    }
    local json_results = cjson.encode(results)
    return json_results
end

return SpeedTest
