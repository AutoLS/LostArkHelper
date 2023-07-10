// Curl expects a C function, that's why we have to use #c_call, and since #c_call doesn't provide a context and JAI function need it, we push_context
write_callback :: (contents: *u8, count: u64, size: u64, builder: *String_Builder) -> u64 #c_call {
    total_size := count * size;
    new_context: Context;
    push_context new_context {
        append(builder, contents, cast(s64) total_size);
    }
    return total_size;
}

curl_get :: (url: string) -> bool, string
{
    builder: String_Builder;
    builder.allocator = temp;
    curl_easy_setopt(lost_ark_helper.curl_handle, .WRITEFUNCTION, write_callback);
    curl_easy_setopt(lost_ark_helper.curl_handle, .WRITEDATA, *builder);
    curl_easy_setopt(lost_ark_helper.curl_handle, .URL, temp_c_string(url));

    res : CURLcode = curl_easy_perform(lost_ark_helper.curl_handle);

    if res == .OK 
    then return true, builder_to_string(*builder);
    else return false, "";
}