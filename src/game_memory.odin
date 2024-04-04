package main

import glfw "vendor:glfw"

import "core:fmt"
import "core:mem"
import "core:mem/virtual"

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
}

display_allocations_tracker :: proc(a: ^mem.Tracking_Allocator) {
    log_debug("Displaying all tracked memory allocations:")
	for key, value in a.allocation_map {
		log_debug("- Allocation:", value.location, "bytes:", value.size)
	}
}

display_allocations_tracker_program_end :: proc(a: ^mem.Tracking_Allocator) {
	if 0 < len(a.allocation_map) {
		log_debug("Program end, memory leaks:")
		for key, value in a.allocation_map {
			log_debug("- Allocation:", value.location, "bytes:", value.size)
		}
	}
	else {
		log_debug("Program end, no memory leaks found.")
	}
}

load_all_textures :: proc() -> map[string]TextureData {
	buffer := make([]u8, mem.Megabyte * 20)
	defer delete(buffer)
	mem_arena := init_arena_buffer(buffer[:])
	image_data := load_image_data("G:\\projects\\game\\TheForge\\resources\\images\\wall.jpg")
	texture_1 := create_texture(image_data)
	free_image_data(&image_data)
	image_data2 := load_image_data("G:\\projects\\game\\TheForge\\resources\\images\\awesomeface.png")
	texture_2 := create_texture(image_data2)
	free_image_data(&image_data2)
	game_textures := make(map[string]TextureData)
	game_textures[texture_1.name] = texture_1
	game_textures[texture_2.name] = texture_2
	return game_textures
}

init_game_controls :: proc() -> GameControls {
	controls : GameControls
	controls.mouse.buttons[.m1] = {glfw.MOUSE_BUTTON_LEFT, false, false}
	controls.mouse.buttons[.m2] = {glfw.MOUSE_BUTTON_RIGHT, false, false}
	controls.keyboard.keys[.e] = {glfw.KEY_E, false, false} 
	controls.keyboard.keys[.v] = {glfw.KEY_V, false, false} 
	return controls
}
