local curl = require("cURL")
local cjson = require("cjson")
local socket = require "socket"

local Calculator = {}
local success, error = nil, nil
--========================================================================
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
    print(cjson.encode(data))
end

USER_AGENT = "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/109.0.0.0 Safari/537.36"

function Calculator.download_speed(url)
    local easy = curl.easy {
        url = url .. "/download",
        useragent = USER_AGENT,
        writefunction = io.open("/dev/null", "wb"),
        noprogress = false,
        timeout = 10,
        progressfunction = download_progress
    }
    download_started = socket.gettime()

    success, error = pcall(easy.perform, easy)
    if not success then
        print("Error: " .. error)
    end
    local download_ended = socket.gettime()
    local download_time = download_ended - download_started
    local speed = easy:getinfo_speed_download() / 1024 / 1024 * 8
    print("Download time (in seconds): " .. string.format("%.4f", download_time), "Speed: " .. string.format("%.4f", speed) .. " Mbps")
    easy:close()
end

local upload_started = socket.gettime()
local function upload_progress(_, _, uptotal, upnow)
    local speed = upnow / (socket.gettime() - upload_started)
    local averageSpeed = speed / 1024 / 1024 * 8
    local data = {
        upload = {
            uptotal = string.format("%.1f", uptotal / 1024 / 1024 * 8) .. "Mb",
            upnow = string.format("%.1f", upnow / 1024 / 1024 * 8) .. "Mb",
            averageSpeed = string.format("%.4f", averageSpeed) .. " Mbps"
        }
    }
    print(cjson.encode(data))
end
function Calculator.upload_speed(url)
    local file = io.open("/dev/zero", "rb")
    if file then
        local uploadData = file:read(1024 * 1024 * 1000)
        if uploadData then
            local easy = curl.easy {
                url = url .. "/upload",
                useragent = USER_AGENT,
                upload = 1,
                noprogress = false,
                [curl.OPT_POSTFIELDS] = uploadData,
                timeout = 10,
                progressfunction = upload_progress
            }
            upload_started = socket.gettime()
            success, error = pcall(easy.perform, easy)
            if not success then
                print("Error: " .. error)
            end

            local upload_ended = socket.gettime()
            local upload_time = upload_ended - upload_started
            local speed = easy:getinfo_speed_upload() / 1024 / 1024 * 8

            print("Upload: " .. string.format("%.4f", upload_time) .. " total time passed (seconds)", string.format("%.4f", speed) .. " Mbps")
            easy:close()
        else
            print("Error reading from the file: uploadData is nil")
        end
        file:close()
    else
        print("Error opening the file for reading data to upload")
    end
end

local response_data = {}
local function table_insert(data)
    table.insert(response_data, data)
end
function Calculator.get_geolocation()
    local easy = curl.easy {
        url = "https://api.myip.com/",
        writefunction = table_insert,
    }
    success, error = pcall(easy.perform, easy)
    if not success then
        print("Error getting your geolocation " .. error)
    end
    easy:close()

    local temp = table.concat(response_data)
    local data_json = cjson.decode(temp)
    local country = nil
    for key, value in pairs(data_json) do
        if key == "country" then
            country = value
        end
    end
    return country
end


function Calculator.download_file()
    local file = assert(io.open("/home/studentas/Desktop/lua-back-end/speedtest_server_list.json", "w"))
    local easy = curl.easy{
        url = "https://raw.githubusercontent.com/AurimasJa/server-list-speed-test/main/speedtest_server_list.json",
        writefunction = file
    }
    success, error = pcall(easy.perform, easy)
    if not success then
        print("Error: " .. error)
    end
    easy:perform()
    -- easy:close() -- ?
    file:close()
end

--========================================================================
function Calculator.get_server_list()
    response_data = {}
    local file = io.open("speedtest_server_list.json", "r")
    if file then
        local content = assert(file:read("*all"))
        table.insert(response_data, content)
        -- response_data = cjson.decode(content)
        file:close()
        -- print(cjson.encode(response_data))
    else
        Calculator.download_file()
        return Calculator.get_server_list() --rerun function to get data
    end
    --   print(response_data)
    return response_data
end

function Calculator.find_server_latency(url, server)
    local easy = curl.easy {
        url = url .. "/upload.php",
        connecttimeout = 3
    }
    local start_time = socket.gettime()

    easy:perform()

    local end_time = socket.gettime()
    local latency = end_time - start_time
    -- local custom_server = { server_info = server, latency = latency }

    -- local results = {
    --     custom_server
    -- }
    -- print(cjson.encode(results))
    return latency
end

function Calculator.find_best_location(servers)
    local best_server = nil
    local best_latency = math.huge
    for key, value in pairs(servers) do
        if value.latency ~= nil and value.latency < best_latency then
            best_latency = value.latency
            best_server = value.host
        end
    end
    local results = {
        best_server = best_server,
        best_latency = string.format("%.6f", best_latency)
    }
    local json_results = cjson.encode(results)
    --   print(json_results) -- Print the JSON string
    return json_results
end

return Calculator