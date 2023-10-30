local curl = require("cURL")
local cjson = require("cjson")
local socket = require "socket"

local SpeedTest = {}
local success, error, result = nil, nil, nil
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
    if dltotal > 0 then
        print(cjson.encode(data))
    end
end

USER_AGENT = "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/109.0.0.0 Safari/537.36"

function SpeedTest.download_speed(url)
    if not url then
        print("Url is not provided")
    end
    if url then
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
        success, error = pcall(easy.perform, easy)
        if not success then
            local errorMessage = string.match(error, "%b[]%s(.+)")
            if not (string.match(errorMessage, "28")) then
                print("Error: " .. errorMessage)
                easy:close()
            elseif not ((socket.gettime() - download_started) < 3.5) then
                print("Test completed successfully")
                local download_ended = socket.gettime()
                local download_time = download_ended - download_started
                local speed = easy:getinfo_speed_download() / 1024 / 1024 * 8
                print("Download time (in seconds): " .. string.format("%.4f", download_time),
                    "Speed: " .. string.format("%.4f", speed) .. " Mbps")
                easy:close()
            else
                print("There was an error connecting to the server - " .. url)
            end
        end
    end
end

SpeedTest.download_speed("speed-kaunas.telia.lt:8080/")

-- SpeedTest.download_speed("vln038-speedtest-1.tele2.net:8080/")

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
    if uptotal > 0 then
        print(cjson.encode(data))
    end
end

function SpeedTest.upload_speed(url)
    if not url then
        print("Url is not provided")
    end
    if url then
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
                    local errorMessage = string.match(error, "%b[]%s(.+)")
                    if not (string.match(errorMessage, "28")) then
                        print("Error: " .. errorMessage)
                        easy:close()
                    elseif not ((socket.gettime() - download_started) < 3.5) then
                        print("Test completed successfully")

                        local upload_ended = socket.gettime()
                        local upload_time = upload_ended - upload_started
                        local speed = easy:getinfo_speed_upload() / 1024 / 1024 * 8

                        print("Upload: " .. string.format("%.4f", upload_time) .. " total time passed (seconds)",
                            string.format("%.4f", speed) .. " Mbps")
                        easy:close()
                    else
                        print("There was an error connecting to the server - " .. url)
                    end
                end
            else
                print("Error reading from the file: uploadData is nil")
            end
            file:close()
        else
            print("Error opening the file for reading data to upload")
        end
    end
end

-- SpeedTest.upload_speed("https://speedtest.kis.lt.prod.hosts.ooklaserver.net:8080/")
local response_data = {}
local function table_insert(data)
    table.insert(response_data, data)
end
function SpeedTest.get_geolocation()
    local easy = curl.easy {
        url = "https://api.myip.com/",
        writefunction = table_insert,
    }
    success, error = pcall(easy.perform, easy)
    if not success then
        local errorMessage = string.match(error, "%b[]%s(.+)")
        if not (string.match(errorMessage, "28")) then
            print("Error: " .. errorMessage)
        end
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
    local json = cjson.encode({ country = country })
    return json
end

function SpeedTest.download_file()
    local file = assert(io.open("speedtest_server_list.json", "w"))
    local easy = curl.easy {
        url = "https://raw.githubusercontent.com/AurimasJa/server-list-speed-test/main/speedtest_server_list.json",
        writefunction = file
    }
    success, error = pcall(easy.perform, easy)
    if not success then
        local errorMessage = string.match(error, "%b[]%s(.+)")
        if not (string.match(errorMessage, "28")) then
            print("Error: " .. errorMessage)
        end
    end
    file:close()
end

function SpeedTest.get_server_list()
    response_data = {}
    local file = io.open("speedtest_server_list.json", "r")
    if file then
        local content = assert(file:read("*all"))
        table.insert(response_data, content)
        file:close()
    else
        SpeedTest.download_file()
        return SpeedTest.get_server_list()
    end
    return response_data
end

-- function SpeedTest.find_server_latency(url, server)
--     local easy = curl.easy {
--         url = url .. "/upload.php",
--         connecttimeout = 3
--     }
--     local start_time = socket.gettime()

--     easy:perform()

--     local end_time = socket.gettime()
--     local latency = end_time - start_time

--     return latency
-- end
function SpeedTest.find_server_latency(serverList, country)
    local decodedCountry = cjson.decode(country)
    if serverList then
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

                if success then
                    server.latency = latency
                else
                    print("There was an error connecting to the server" .. " - " .. server.host)
                end
            end
        end
        success, result = pcall(SpeedTest.find_best_location, serverData)

        if not success then
            print("There was an error finding best server")
        end
    end
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
    local results = {
        best_server = best_server,
        best_latency = string.format("%.6f", best_latency)
    }
    if best_server == nil then
        return print("There were no servers")
    else
        local json_results = cjson.encode(results)
        return print(json_results)
    end
end

-------------------------------
-- local success, country = pcall(SpeedTest.get_geolocation)

-- if not success then
--     print("Ip address is incorrect or connection was terminated")
-- else
--     print(country)
-- end

-- local success, serverList = pcall(SpeedTest.get_server_list)

-- if not success then
--     print("Ip address is incorrect or connection was terminated")
-- end

-- if serverList then
--     local serverData = cjson.decode(serverList[1])
--     for _, server in pairs(serverData) do
--         if server.country == country then
--             success, result = pcall(SpeedTest.find_server_latency, server.host, server)

--             if success then
--                 server.latency = result
--             else
--                 print("There was an error connecting to the server" .. " - " .. server.host)
--             end
--         end
--     end
--     local success, result = pcall(SpeedTest.find_best_location, serverData)

--     if success then
--         print(result)
--     else
--         print("There was an error finding best server")
--     end
-- end
return SpeedTest
