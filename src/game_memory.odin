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