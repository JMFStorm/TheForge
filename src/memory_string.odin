package main

import "core:fmt"
import "core:mem"
import "core:mem/virtual"
import "core:strings"

StringBuffer :: struct {
        data:                   []u8,
        strings_count:          int,
        strings:                [STRING_CONSOLE_BUFFER_LENGTH]string,
	used_size:              int,
	max_size:               int,
}

perma_string_allocator_proc :: proc(allocator_data: rawptr, mode: mem.Allocator_Mode, size, alignment: int, old_memory: rawptr, old_size: int, location := #caller_location) -> ([]byte, mem.Allocator_Error) {
        buffer := cast(^StringBuffer)allocator_data
        #partial switch mode {
                case .Alloc: {
                        start := &buffer.data[buffer.used_size]
                        buffer.used_size += size
                        buffer.strings_count += 1
                        return mem.byte_slice(start, size), nil
                }
                case .Free_All: {
                        when !ODIN_DEBUG {
                                log_and_panic("Invalid free memory call to permanent string allocator, when not on debug build.")
                        }
                        else {
                                log_warning(fmt.tprint("Permanent string allocator called with free all.")) 
                                delete(buffer.data, context.allocator)
                                buffer.used_size = 0
                                buffer.max_size = 0
                                return nil, nil
                        }
                }
        }
        log_and_panic("Unknown mode called to string perma allocator. We'll panic for now.")
        return nil, nil
}

init_str_perma_allocator :: proc(size : int) -> mem.Allocator {
        str_perma_arena.data = make([]byte, size)
        str_perma_arena.max_size = size
        return mem.Allocator{
		procedure = perma_string_allocator_proc,
		data = &str_perma_arena,
	}
}

str_perma_copy :: proc(str: string) -> string {
        copied, err := strings.clone(str, str_perma_allocator)
        if err != nil {
                log_and_panic("Failed to strcopy executable path")
        }
        return copied
}
