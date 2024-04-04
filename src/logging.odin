package main

import "core:log"
import "core:runtime"
import "core:os"
import "core:fmt"

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
        handle, open_error := os.open("./log.txt", os.O_WRONLY|os.O_TRUNC|os.O_CREATE)
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

log_debug :: proc(text: string, location := #caller_location) {
        logger := context.logger
        if logger.lowest_level <= runtime.Logger_Level.Debug {
                context.logger.procedure(logger.data, .Debug, text, logger.options, location)
        }
}

log_info :: proc(text: string, location := #caller_location) {
        logger := context.logger
        context.logger.procedure(logger.data, .Info, text, logger.options, location)
}

log_and_panic :: proc(text: string, location := #caller_location) {
        logger := context.logger
        context.logger.procedure(logger.data, .Fatal, text, logger.options, location)
        runtime.panic("log.panic", location)
}