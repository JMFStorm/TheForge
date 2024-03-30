package main

import "core:fmt"
import "core:mem"
import "core:mem/virtual"

init_arena_buffer :: proc(buffer: []u8) -> virtual.Arena {
    arena : virtual.Arena
    arena_error := virtual.arena_init_buffer(&arena, buffer[:])
    if arena_error != nil {
        panic("Arena allocation error")
    }
    return arena
}

deallocate_memory :: proc() {
	free_game_controls(&game_controls)
}

display_allocations_tracker :: proc(a: ^mem.Tracking_Allocator) {
    fmt.println("Displaying all tracked memory allocations:")
	for key, value in a.allocation_map {
		fmt.println("- Allocation:", value.location, "bytes:", value.size)
	}
}

display_allocations_tracker_program_end :: proc(a: ^mem.Tracking_Allocator) {
	if 0 < len(a.allocation_map) {
		fmt.println("Program end, memory leaks:")
		for key, value in a.allocation_map {
			fmt.println("- Allocation:", value.location, "bytes:", value.size)
		}
	}
	else {
		fmt.println("Program end, no memory leaks found.")
	}
}

load_all_textures :: proc() -> map[string]TextureData {
	buffer := make([]u8, mem.Megabyte * 20)
	defer delete(buffer)
	mem_arena := init_arena_buffer(buffer[:])

	image_data := load_image_data("G:\\projects\\game\\TheForge\\resources\\images\\wall.jpg")
	texture_1 := create_texture(image_data)
	free_image_data(&image_data)
	fmt.println("Image 1 data:", image_data.width_px, image_data.height_px)

	image_data2 := load_image_data("G:\\projects\\game\\TheForge\\resources\\images\\awesomeface.png")
	texture_2 := create_texture(image_data2)
	free_image_data(&image_data2)
	fmt.println("Image 2 data:", image_data2.width_px, image_data2.height_px)

	game_textures := make(map[string]TextureData)
	game_textures[texture_1.name] = texture_1
	game_textures[texture_2.name] = texture_2
	return game_textures
}