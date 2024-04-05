package main

import glfw "vendor:glfw"

import "core:fmt"
import "core:mem"
import "core:mem/virtual"
import "core:strings"

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
        log_debug("Tracked memory allocations:")
        for _, leak in a.allocation_map {
                log_debug(fmt.tprintf("- %v leaked %m", leak.location, leak.size))
        }
        for bad_free in a.bad_free_array {
                log_debug(fmt.tprintf("- %v allocation %p was freed badly", bad_free.location, bad_free.memory))
        }
}

load_all_textures :: proc() -> map[string]TextureData {
	image_data := load_image_data("wall.jpg")
	texture_1 := create_texture(image_data)
	free_image_data(&image_data)
	image_data2 := load_image_data("awesomeface.png")
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

str_perma_copy :: proc(str: string) -> string {
        perma_str_allocator := context.allocator // Replace
        copied, err := strings.clone(str, perma_str_allocator)
        if err != nil {
                log_and_panic("Failed to strcopy executable path")
        }
        return copied
}
