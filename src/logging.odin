package main

import "core:log"

log_debug :: proc(args: ..any, sep := " ", location := #caller_location) {
        when ODIN_DEBUG {
                log.debug(args, sep, location)
        }
}

log_info :: proc(args: ..any, sep := " ", location := #caller_location) {
        log.info(args, sep, location)
}

log_and_panic :: proc(args: ..any, sep := " ", location := #caller_location) {
        log.panic(args, sep, location)
}