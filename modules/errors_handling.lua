local Errors = require("config.Errors")
local ErrorHandling = {}

function ErrorHandling.handle_error_message_by_curl_code(msg)
    return tonumber(tostring(msg):match("%((%d+)%)"))
end

function ErrorHandling.handle_error_message(msg)
    return string.match(msg, "%b[]%s(.+)")
end

function ErrorHandling.custom_error_by_key(key)
    if Errors[key] then
        return Errors[key]
    else
        return "Unknown error occurred"
    end
end

return ErrorHandling