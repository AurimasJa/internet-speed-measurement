local curl = require("cURL")
local cjson = require("cjson")
local socket = require "socket"
local ErrorsHandling = require("modules.errors_handling")

local SpeedTest = {}
local json
local success, result = nil, nil
local download_started = socket.gettime()
local upload_started = socket.gettime()
local server_file = "speedtest_server_list.json"
local download_server_file =
"https://raw.githubusercontent.com/AurimasJa/server-list-speed-test/main/speedtest_server_list.json"
local location_url = "https://api.myip.com/"
local file_null = "/dev/null"
local file_zero = "/dev/zero"
local USER_AGENT =
"Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/109.0.0.0 Safari/537.36"

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

function SpeedTest.download_speed(url)
    if not url then
        return ErrorsHandling.custom_error_by_key("no_url")
    end
    local easy = curl.easy {
        url = url .. "/download",
        useragent = USER_AGENT,
        connecttimeout = 3,
        writefunction = io.open(file_null, "wb"),
        noprogress = false,
        timeout = 10,
        progressfunction = download_progress
    }
    download_started = socket.gettime()
    success, result = pcall(easy.perform, easy)
    if not success then
        local errorCode = ErrorsHandling.handle_error_message_by_curl_code(result)
        if not (string.match(result, "28")) or easy:getinfo_connect_time() == 0 then
            return ErrorsHandling.custom_error_by_key(errorCode)
        end
    end
    print("Test completed successfully")
    local download_ended = socket.gettime()
    local download_time = download_ended - download_started
    local speed = easy:getinfo_speed_download() / 1024 / 1024 * 8
    easy:close()
    json = cjson.encode({ download_time = string.format("%.4f", download_time) .. " s",
        download_speed = string.format("%.4f", speed) .. "Mbps" })
    return nil, json
end

function SpeedTest.upload_speed(url)
    if not url then
        return ErrorsHandling.custom_error_by_key("no_url")
    end

    local easy = curl.easy({
        url = url .. "/upload",
        useragent = USER_AGENT,
        httppost = curl.form({
            file = { file = file_zero, type = "text/plain", name = "zeros" }
        }),
        post = true,
        progressfunction = upload_progress,
        noprogress = false,
        writefunction = io.open(file_null, "r+"),
        timeout = 10,
    })

    upload_started = socket.gettime()

    success, result = pcall(easy.perform, easy)
    if not success then
        local errorCode = ErrorsHandling.handle_error_message_by_curl_code(result)
        if not (string.match(result, "28")) or easy:getinfo_connect_time() == 0 then
            return ErrorsHandling.custom_error_by_key(errorCode)
        end
    end

    print("Test completed successfully")
    local upload_ended = socket.gettime()
    local upload_time = upload_ended - upload_started
    local speed = easy:getinfo_speed_upload() / 1024 / 1024 * 8

    easy:close()
    json = cjson.encode({ upload_time = string.format("%.4f", upload_time) .. " s",
        upload_speed = string.format("%.4f", speed) .. "Mbps" })
    return nil, json
end

function SpeedTest.get_geolocation()
    local response_data = {}
    local easy = curl.easy {
        url = location_url,
        writefunction = function(data)
            table.insert(response_data, data)
        end,
    }
    success, result = pcall(easy.perform, easy)
    if not success then
        easy:close()
        local errorCode = ErrorsHandling.handle_error_message_by_curl_code(result)
        if not (string.match(result, "28")) or easy:getinfo_connect_time() == 0 then
            return ErrorsHandling.custom_error_by_key(errorCode)
        end
    end

    easy:close()
    local data = table.concat(response_data)
    local data_json = cjson.decode(data)
    local country = nil
    for key, value in pairs(data_json) do
        if key == "country" then
            country = value
            break
        end
    end
    json = cjson.encode({ country = country })
    return nil, json
end

function SpeedTest.download_file()
    local file = assert(io.open(server_file, "w"))
    local easy = curl.easy {
        url = download_server_file,
        writefunction = file
    }
    success, result = pcall(easy.perform, easy)
    file:close()
    if not success then
        local errorCode = ErrorsHandling.handle_error_message_by_curl_code(result)
        if not (string.match(result, "28")) or easy:getinfo_connect_time() == 0 then
            return ErrorsHandling.custom_error_by_key(errorCode)
        end
    end
end

function SpeedTest.get_server_list()
    local response_data = {}
    local file = io.open(server_file, "r")
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
        return ErrorsHandling.custom_error_by_key("no_country")
    end
    local decodedCountry = cjson.decode(country)
    if not serverList then
        return ErrorsHandling.custom_error_by_key("no_server_list")
    end
    local serverData
    success, result = pcall(function()
        serverData = cjson.decode(serverList[1])
    end)

    if not success then
        return ErrorsHandling.custom_error_by_key("decode_fail")
    end
    for _, server in pairs(serverData) do
        if server.country == decodedCountry.country then
            local easy = curl.easy {
                url = server.host,
                connecttimeout = 3
            }
            local start_time = socket.gettime()

            success, result = pcall(easy.perform, easy)

            local end_time = socket.gettime()
            local latency = end_time - start_time

            if not success then
                print(ErrorsHandling.custom_error_by_key("server_error") .. " - " .. server.host)
            else
                server.latency = latency
            end
        end
    end
    return serverData
end

function SpeedTest.find_best_location(servers)
    if not servers or type(servers) == "string" then
        return ErrorsHandling.custom_error_by_key("no_server_list")
    end
    local best_server = nil
    local best_latency = math.huge
    for _, value in pairs(servers) do
        if value.latency ~= nil and value.latency < best_latency then
            best_latency = value.latency
            best_server = value.host
        end
    end
    if not best_server then
        return ErrorsHandling.custom_error_by_key("no_servers_compare")
    end
    local results = {
        best_server = best_server,
        best_latency = string.format("%.6f", best_latency)
    }
    local json_results = cjson.encode(results)
    return json_results
end

return SpeedTest
