package main

import "core:log"
import "core:runtime"
import "core:os"
import "core:fmt"
import "core:strings"

create_debug_build_logger :: proc(data: ^log.File_Console_Logger_Data) -> log.Logger {
	data.file_handle = os.INVALID_HANDLE
	data.ident = ""
        options := runtime.Logger_Options {
                .Level,
                .Time,
                .Short_File_Path,
                .Line,
        }
	return log.Logger{log.file_console_logger_proc, data, log.Level.Debug, options}
}

create_release_build_logger :: proc(data: ^log.File_Console_Logger_Data) -> log.Logger {
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

init_loggers :: proc() -> log.Logger {
        console_logger_data = new(log.File_Console_Logger_Data)
        file_logger_data = new(log.File_Console_Logger_Data)
        console_logger := create_debug_build_logger(console_logger_data)
        file_logger := create_release_build_logger(file_logger_data)
        return log.create_multi_logger(console_logger, file_logger)
}

log_debug :: proc(text: string, location := #caller_location) {
        logger := context.logger
        if logger.lowest_level <= runtime.Logger_Level.Debug {
                context.logger.procedure(logger.data, .Debug, text, logger.options, location)
        }
}

log_info :: proc(text: string, location := #caller_location) {
        logger := context.logger
        if logger.lowest_level <= runtime.Logger_Level.Info {
                context.logger.procedure(logger.data, .Info, text, logger.options, location)
        }
}

log_warning :: proc(text: string, location := #caller_location) {
        logger := context.logger
        context.logger.procedure(logger.data, .Warning, text, logger.options, location)
}

log_error :: proc(text: string, location := #caller_location) {
        logger := context.logger
        context.logger.procedure(logger.data, .Error, text, logger.options, location)
}

log_and_panic :: proc(text: string, location := #caller_location) {
        logger := context.logger
        context.logger.procedure(logger.data, .Fatal, text, logger.options, location)
        runtime.panic("log.panic", location)
}