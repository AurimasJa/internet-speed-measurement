local error_handling = {}

function error_handling.handle_error(err)
    return err
end

function error_handling.custom_error(err_message)
    return error_handling.handle_error(err_message)
end

function error_handling.handle_error_message(msg)
    return string.match(msg, "%b[]%s(.+)")
end

return error_handling