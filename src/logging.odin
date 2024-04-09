package main

import "core:log"
import "core:runtime"
import "core:os"
import "core:fmt"
import "core:strings"
import "core:mem"
import "core:unicode/utf8"

create_file_logger :: proc(data: ^log.File_Console_Logger_Data) -> log.Logger {
        logger_path := strings.concatenate({game_file_info.exe_dirpath, "\\log.txt"}, context.temp_allocator)
        handle, open_error := os.open(logger_path, os.O_WRONLY|os.O_TRUNC|os.O_CREATE)
        if open_error != 0 {
                fmt.panicf("ERROR: Could not init file logger")
        }
	data.file_handle = handle
	data.ident = ""
        options := runtime.Logger_Options {
                .Level,
                .Date,
                .Time,
                .Short_File_Path,
                .Line,
        }
	return log.Logger{log.file_console_logger_proc, data, log.Level.Info, options}
}

console_log :: proc(text: string) {
        copy_len := len(text) if len(text) < STRING_CONSOLE_BUFFER_SIZE else STRING_CONSOLE_BUFFER_SIZE
        src_index := (console_str_buffer.strings_count * STRING_CONSOLE_BUFFER_SIZE) % (STRING_CONSOLE_BUFFER_SIZE * STRING_CONSOLE_BUFFER_LENGTH)
        dst := console_str_buffer.data[src_index:(src_index + copy_len)]
        mem.zero(raw_data(dst), STRING_CONSOLE_BUFFER_SIZE)
        copy(dst, text)
        when ODIN_DEBUG {
                fmt.println(text)
        }
        used_index := console_str_buffer.strings_count % STRING_CONSOLE_BUFFER_LENGTH
        console_str_buffer.strings[used_index] = string(dst)
        console_str_buffer.strings_count += 1
}

debug_print_console_logs :: proc() {
        fmt.println("")
        fmt.println("---------------------------------")
        fmt.println("Debug print console logs:")
        fmt.println("---------------------------------")
        logs_count := min(console_str_buffer.strings_count, STRING_CONSOLE_BUFFER_LENGTH)
        start_index := (console_str_buffer.strings_count - logs_count) % STRING_CONSOLE_BUFFER_LENGTH
        for i in 0 ..< logs_count {
                index := (start_index + i) % STRING_CONSOLE_BUFFER_LENGTH
                str := console_str_buffer.strings[index]
                fmt.println(str)
        }
        fmt.println("---------------------------------")
        fmt.println("")
}

init_loggers :: proc() {
        if len(game_file_info.exe_dirpath) == 0 {
                panic("Do not call init_loggers() before setting directory path info.")
        }
        console_buffer_size := STRING_CONSOLE_BUFFER_SIZE * STRING_CONSOLE_BUFFER_LENGTH
        console_str_buffer.data = make([]byte, console_buffer_size)
        console_str_buffer.max_size = console_buffer_size
}

log_debug :: proc(text: string, location := #caller_location) {
        console_log(text)
}

log_info :: proc(text: string, location := #caller_location) {
        console_log(text)
}

log_warning :: proc(text: string, location := #caller_location) {
        console_log(text)
}

log_error :: proc(text: string, location := #caller_location) {
        console_log(text)
}

log_and_panic :: proc(text: string, location := #caller_location) {
        runtime.panic("log and panic", location)
}