local ErrorHandling = {}

function ErrorHandling.handle_error(err)
    return err
end

function ErrorHandling.custom_error(err_message)
    return ErrorHandling.handle_error(err_message)
end

function ErrorHandling.handle_error_message(msg)
    return string.match(msg, "%b[]%s(.+)")
end

return ErrorHandling
