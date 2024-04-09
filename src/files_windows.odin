package main

import "core:c"
import "core:fmt"
import "core:path/filepath"
import "core:strings"
import win32 "core:sys/windows"

wchar_str_to_string :: proc(wchar_str: win32.LPCWSTR) -> string {
        length := win32.WideCharToMultiByte(win32.CP_UTF8, 0, wchar_str, -1, nil, 0, nil, nil)
        byte_buffer := make([]byte, int(length), context.temp_allocator)
        bytes := win32.WideCharToMultiByte(win32.CP_UTF8, 0, wchar_str, -1, raw_data(byte_buffer), length, nil, nil)
        if bytes > 0 { bytes -= 1 }
        return string(byte_buffer[:bytes])
}

get_executable_fullpath :: proc() -> string {
        buffer := make([]win32.WCHAR, 255, context.temp_allocator)
        win32.GetModuleFileNameW(nil, raw_data(buffer), 255)
        return wchar_str_to_string(raw_data(buffer))
}
