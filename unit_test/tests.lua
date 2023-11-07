local lu = require("luaunit")
local cjson = require("cjson")
local SpeedTest = require("modules.SpeedTest")
local curl = require("cURL")
local mock_response_data = '{"country":"Lithuania"}'

local mockCurl = {
    form = function(...)

    end,

    writefunction = function ()
        assert(io.open("speedtest_server_list.json", "w"))
    end,
    easy = function(...)
        return {
            perform = function()
                return true
            end,
            getinfo_speed_download = function()
                return 100
            end,
            getinfo_speed_upload = function()
                return 100
            end,
            getinfo_connect_time = function()
                return 0
            end,
            close = function()
                return true
            end
        }
    end
}

local mock_data = {
    url = "https://download.com",
    bad_url = "xxxx",
    empty_url = "",
    servers = {
        {
            host = "test-server1.server.com",
            country = "Lithuania",
            city = "Kaunas",
            provider = "Telia",
            id = 12345,
            latency = 0.01
        },
        {
            host = "test-server2.server.com",
            country = "Lithuania",
            city = "Kaunas",
            provider = "Kis",
            id = 22345,
            latency = 0.02
        },
        {
            host = "test-server3.server.com",
            country = "Lithuania",
            city = "Klaipeda",
            provider = "Telia",
            id = 32345,
            latency = 0.03
        },
        {
            host = "test-server4.server.com",
            country = "Lithuania",
            city = "Vilnius",
            provider = "Telia",
            id = 42345,
            latency = 0.04
        },
    }
}

TestDownload = {}
TestUpload = {}
TestGeolocation = {}
TestServerList = {}
TestBestLocation = {}

local response_data = {}
local serverList = cjson.encode(mock_data.servers)
table.insert(response_data, serverList)
local country = '{"country": "Lithuania"}'

function TestDownload:test_download_speed_no_errors()
    SpeedTest.set_curl_override(mockCurl)
    local _, result = SpeedTest.download_speed(mock_data.url)
    local expected = cjson.encode({
        download_time = "0.0000 s",
        download_speed = "0.0008Mbps"
    })
    lu.assertEquals(result, expected)
end

function TestDownload:test_download_speed_bad_url()
    local originalPerform = mockCurl.easy().perform

    local mockEasy = mockCurl.easy()
    mockEasy.perform = function()
        error("(6)")
    end

    mockCurl.easy = function()
        return mockEasy
    end
    SpeedTest.set_curl_override(mockCurl)
    local result, _ = SpeedTest.download_speed(mock_data.bad_url)
    local expected =
    "Error: The host could not be located. The specified remote host name could not be found. Check your internet connection."
    lu.assertEquals(result, expected)
    mockCurl.easy().perform = originalPerform
end

function TestDownload:test_download_speed_no_url()
    local result, _ = SpeedTest.download_speed(mock_data.empty_url)
    local expected =
    "Error: Url is not provided."
    lu.assertEquals(result, expected)
end

function TestUpload:test_upload_speed_no_errors()
    SpeedTest.set_curl_override(mockCurl)
    local _, result = SpeedTest.upload_speed(mock_data.url)
    local expected = cjson.encode({
        upload_time = "0.0000 s",
        upload_speed = "0.0008Mbps"
    })
    lu.assertEquals(result, expected)
end

function TestUpload:test_upload_speed_bad_url()
    local originalPerform = mockCurl.easy().perform

    local mockEasy = mockCurl.easy()
    mockEasy.perform = function()
        error("(6)")
    end

    mockCurl.easy = function()
        return mockEasy
    end
    SpeedTest.set_curl_override(mockCurl)
    local result, _ = SpeedTest.upload_speed(mock_data.bad_url)
    local expected =
    "Error: The host could not be located. The specified remote host name could not be found. Check your internet connection."
    lu.assertEquals(result, expected)
    mockCurl.easy().perform = originalPerform
end

function TestUpload:test_upload_speed_no_url()
    local result, _ = SpeedTest.upload_speed(mock_data.empty_url)
    local expected =
    "Error: Url is not provided."
    lu.assertEquals(result, expected)
end

function TestGeolocation:test_geo_location_no_errors()
    SpeedTest.set_curl_override(curl)
    local _, result = SpeedTest.get_geolocation()
    lu.assertEquals(result, mock_response_data)
end

function TestGeolocation:test_geo_location_throw_error()
    local originalPerform = mockCurl.easy().perform

    local mockEasy = mockCurl.easy()
    mockEasy.perform = function()
        error("(6)")
    end

    mockCurl.easy = function()
        return mockEasy
    end
    SpeedTest.set_curl_override(mockCurl)
    local expected =
    "Error: The host could not be located. The specified remote host name could not be found. Check your internet connection."

    local result, _ = SpeedTest.get_geolocation()
    lu.assertEquals(result, expected)
    mockCurl.easy().perform = originalPerform
end

function TestServerList:test_get_server_list_errors()
    -- local expected =
    -- "Error: The host could not be located. The specified remote host name could not be found. Check your internet connection."
    local expected = {""}

    local result, _ = SpeedTest.get_server_list()
    lu.assertEquals(result, expected)
end

function TestServerList:test_download_file_with_errors()
    local originalPerform = mockCurl.easy().perform

    local mockEasy = mockCurl.easy()
    mockEasy.perform = function()
        error("(6)")
    end

    mockCurl.easy = function()
        return mockEasy
    end
    SpeedTest.set_curl_override(mockCurl)
    local result, _ = SpeedTest.download_file()
    local expected =
    "Error: The host could not be located. The specified remote host name could not be found. Check your internet connection."
    lu.assertEquals(result, expected)
    mockCurl.easy().perform = originalPerform
end
function TestServerList:test_download_file()
    local result = SpeedTest.download_file()
    lu.assertEquals(result, nil)
end
function TestBestLocation:test_server_latancy_no_error()
    local result = SpeedTest.find_server_latency(response_data, country)
    lu.assertEquals(result, mock_data.servers)
end
function TestBestLocation:test_best_server_latancy_no_error()
    local result = SpeedTest.find_best_location(mock_data.servers)
    local expected = '{"best_latency":"0.010000","best_server":"test-server1.server.com"}'
    lu.assertEquals(result, expected)
end

os.exit(lu.LuaUnit.run())
