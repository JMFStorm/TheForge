package main

import "core:c"
import "core:fmt"
import "core:strings"
import win32 "core:sys/windows"

set_executable_dirpath :: proc() {
}

set_resources_dirpath :: proc() {
}

set_executable_fullpath :: proc() {
        buffer := make([]win32.WCHAR, 255)
        defer delete(buffer)
        win32.GetModuleFileNameW(nil, raw_data(buffer), 255)
        length := win32.WideCharToMultiByte(win32.CP_UTF8, 0, raw_data(buffer), -1, nil, 0, nil, nil)
        buffer_2 := make([]byte, int(length))
        defer delete(buffer_2)
        n := win32.WideCharToMultiByte(win32.CP_UTF8, 0, raw_data(buffer), -1, raw_data(buffer_2), length, nil, nil)
        if n > 0 {
                n -= 1
        }
        path_as_string := string(buffer_2[:n])
        perma_str_allocator := context.allocator
        copied_str, err := strings.clone(path_as_string, perma_str_allocator)
        if err != nil {
                log_and_panic("Failed to strcopy executable path")
        }
        game_file_info.exe_fullpath = copied_str
        str := fmt.tprint("Executable fullpath:", path_as_string)
        log_info(str)
}
