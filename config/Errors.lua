local Errors = {
    ["no_url"] = "Error: Url is not provided.",
    ["serv_not_resp"] = "Error: Server is not responding.",
    ["no_best_server"] = "Error: There were no servers to compare with.",
    ["no_country"] = "Error: Country is not provided.",
    ["no_server_list"] = "Error: Server list is not provided.",
    ["no_servers_compare"] = "Error: There were no servers to compare.",
    ["best_server_not_valid"] = "Error: There were no best servers located.",
    ["decode_fail"] = "Error: Try to remove \"speedtest_server_list.json\" (located in same directory as your application is) file and try again.",
    ["server_error"] = "There was an error connecting to the server",
    [6] = "Error: The host could not be located. The specified remote host name could not be found. Check your internet connection.",
    [9] = "Error: Remote access denied.",
    [18] = "Error: A file transfer was shorter or larger than expected. Please try again.",
    [23] = "Error: An error occurred when writing received data to a local file.",
    [25] = "Error: Failed starting the upload. Please try again.",
    [26] = "Error: There was a problem reading a local file.",
    [27] = "Error: OUT OF MEMORY.",
    [28] = "Error: Host is not responding.",
}

return Errors