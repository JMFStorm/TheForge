package main

import glfw "vendor:glfw"

import "core:fmt"
import "core:mem"
import "core:mem/virtual"
import "core:strings"

StringArena :: struct {
	data:                   []byte,
        strings_indexes:        [255]int,
        strings_count:          int,
	used:                   int,
	max:                    int,
}

debug_display_all_perma_strings :: proc() {
        log_debug(fmt.tprintf("Displaying all strings in permanent str storage (count:%d, bytes:%d)", str_perma_arena.strings_count, str_perma_arena.used))
        for i := 0; i < str_perma_arena.strings_count; i += 1 {
                str_index := str_perma_arena.strings_indexes[i]
                str_index_end : int
                if i == str_perma_arena.strings_count - 1 {
                        str_index_end = str_perma_arena.used
                }
                else {
                        str_index_end = str_perma_arena.strings_indexes[i + 1]
                }
                current := str_perma_arena.data[str_index:str_index_end]
                log_debug(fmt.tprintf("%d: %s", i, string(current)))
        }
}

arena_allocator_proc :: proc(allocator_data: rawptr, mode: mem.Allocator_Mode, size, alignment: int, old_memory: rawptr, old_size: int, location := #caller_location) -> ([]byte, mem.Allocator_Error) {
        arena := cast(^StringArena)allocator_data
        #partial switch mode {
                case .Alloc: {
                        start := &arena.data[arena.used]
                        arena.strings_indexes[arena.strings_count] = arena.used
                        arena.used += size
                        arena.strings_count += 1
                        log_debug(fmt.tprintf("Permanent string memory allocation with %d bytes. New arena size: %d", size, arena.used))
                        return mem.byte_slice(start, size), nil
                }
                case .Free_All: {
                        when !ODIN_DEBUG {
                                log_and_panic("Invalid free memory call to permanent string allocator, when not on debug build.")
                        }
                        else {
                                log_warning(fmt.tprint("Permanent string allocator called with free all.")) 
                                delete(arena.data, context.allocator)
                                arena.used = 0
                                arena.max = 0
                                return nil, nil
                        }
                }
        }
        log_and_panic("Unknown mode called to string perma allocator. We'll panic for now.")
        return nil, nil
}

init_str_perma_allocator :: proc(size : int) -> mem.Allocator {
        str_perma_arena.data = make([]byte, size, context.allocator)
        str_perma_arena.max = size
        return mem.Allocator{
		procedure = arena_allocator_proc,
		data = &str_perma_arena,
	}
}

init_arena_buffer :: proc(buffer: []u8) -> virtual.Arena {
    arena : virtual.Arena
    arena_error := virtual.arena_init_buffer(&arena, buffer[:])
    if arena_error != nil {
        log_and_panic("Arena allocation error")
    }
    return arena
}

deallocate_all_memory :: proc() {
	delete(game_controls.mouse.buttons)
	delete(game_controls.keyboard.keys)
	delete(game_textures)
        free(console_logger_data)
        free(file_logger_data)
        free_all(str_perma_allocator)
}

display_allocations_tracker :: proc(a: ^mem.Tracking_Allocator) {
        log_debug("Getting current memory allocations/leaks:")
        if len(a.allocation_map) == 0 && len(a.bad_free_array) == 0 {
                log_debug("- No memory leaks found, great(?)")
                return
        }
        for _, leak in a.allocation_map {
                log_warning(fmt.tprintf("- %v leaked %m", leak.location, leak.size))
        }
        for bad_free in a.bad_free_array {
                log_warning(fmt.tprintf("- %v allocation %p was freed badly", bad_free.location, bad_free.memory))
        }
}

load_all_textures :: proc() -> map[string]TextureData {
        set_image_load_flip_vertical(true)
	image_data := load_image_data("wall.jpg")
	texture_1 := create_texture(image_data)
	free_image_data(&image_data)
	image_data2 := load_image_data("awesomeface.png")
	texture_2 := create_texture(image_data2)
	free_image_data(&image_data2)
	game_textures := make(map[string]TextureData)
	game_textures[texture_1.name] = texture_1
	game_textures[texture_2.name] = texture_2
        free_all(context.temp_allocator)
	return game_textures
}

init_game_controls :: proc() -> GameControls {
	controls : GameControls
	controls.mouse.buttons[.m1] = {glfw.MOUSE_BUTTON_LEFT, false, false}
	controls.mouse.buttons[.m2] = {glfw.MOUSE_BUTTON_RIGHT, false, false}
	controls.keyboard.keys[.e] = {glfw.KEY_E, false, false} 
	controls.keyboard.keys[.v] = {glfw.KEY_V, false, false} 
	controls.keyboard.keys[.f] = {glfw.KEY_F, false, false} 
	controls.keyboard.keys[.esc] = {glfw.KEY_ESCAPE, false, false} 
	return controls
}

str_perma_copy :: proc(str: string) -> string {
        copied, err := strings.clone(str, str_perma_allocator)
        if err != nil {
                log_and_panic("Failed to strcopy executable path")
        }
        return copied
}
