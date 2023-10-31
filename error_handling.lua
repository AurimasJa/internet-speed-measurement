local ErrorHandling = {}
local Errors = {
    ["url"] = "Error: Url is not provided",
    ["serv_not_resp"] = "Error: Server is not responding",
    ["no_best_server"] = "Error: There were no servers to compare with",
    ["no_country"] = "Error: Country is not provided",
    ["no_server_list"] = "Error: Server list is not provided",
    ["no_servers_compare"] = "Error: There were no servers to compare",
    [6] = "Error: The host could not be located. The specified remote host name could not be found.",
    [9] = "Error: Remote access denied.",
    [18] = "Error: A file transfer was shorter or larger than expected. Please try again.",
    [23] = "Error: An error occurred when writing received data to a local file",
    [25] = "Error: Failed starting the upload. Please try again.",
    [26] = "Error: There was a problem reading a local file",
    [27] = "Error: OUT OF MEMORY.",
    [28] = "Error: Host is not responding.",
}

function ErrorHandling.handle_error_by_key(key)
    return Errors[key]
end

function ErrorHandling.handle_error(err)
    return err
end

function ErrorHandling.custom_error(err_message)
    return ErrorHandling.handle_error(err_message)
end

function ErrorHandling.custom_error_by_key(err_message)
    return ErrorHandling.handle_error_by_key(err_message)
end

function ErrorHandling.handle_error_message(msg)
    return string.match(msg, "%b[]%s(.+)")
end
function ErrorHandling.handle_error_message_by_code(msg)
    return tonumber(tostring(msg):match("%((%d+)%)"))
end

return ErrorHandling
