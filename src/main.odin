package main

import gl "vendor:OpenGL"
import glfw "vendor:glfw"

import "core:fmt"
import "core:mem"
import "core:mem/virtual"

draw_selection_box := false
box_start_ndc : Vec2
box_end_ndc : Vec2

init_game_window :: proc(x, y: i32, title: cstring) -> (window: GameWindow, error: bool) {
	glfw.WindowHint(glfw.RESIZABLE, 0)
	glfw.WindowHint(glfw.CONTEXT_VERSION_MAJOR, GL_MAJOR_VERSION) 
	glfw.WindowHint(glfw.CONTEXT_VERSION_MINOR, GL_MINOR_VERSION)
	glfw.WindowHint(glfw.OPENGL_PROFILE, glfw.OPENGL_CORE_PROFILE)
	
	window_handle := glfw.CreateWindow(x, y, title, nil, nil)
	if window_handle == nil {
		return {}, true
	}
	aspect := f32(x) / f32(y)
	return GameWindow{window_handle, {f32(x), f32(y)}, aspect}, false
}

set_game_controls_state :: proc() {
	x, y := glfw.GetCursorPos(game_window.handle);
	game_controls.mouse.window_pos = {f32(x), f32(y)}

	for _, &button_state in game_controls.mouse.buttons {
		state := glfw.GetMouseButton(game_window.handle, button_state.key)
		if state == glfw.PRESS {
			button_state.pressed = false if button_state.is_down == true else true
			button_state.is_down = true
		}
		else {
			button_state.is_down = false
		}
	}

	for _, &key_state in game_controls.keyboard.keys {
		state := glfw.GetKey(game_window.handle, key_state.key)
		if state == glfw.PRESS {
			key_state.pressed = false if key_state.is_down == true else true
			key_state.is_down = true
		}
		else {
			key_state.is_down = false
		}
	}
}

size_callback :: proc "c" (window: glfw.WindowHandle, width, height: i32) {
	gl.Viewport(0, 0, width, height)
}

arena_count : int = 0

main :: proc() {
	mem_tracker : mem.Tracking_Allocator
	mem.tracking_allocator_init(&mem_tracker, context.allocator)
	context.allocator = mem.tracking_allocator(&mem_tracker)

	if success := glfw.Init(); success == false {
		fmt.println("ERROR: glfw.Init() failed.")
		return
	}
	defer glfw.Terminate()

	error: bool
	game_window, error = init_game_window(1600, 1200, "jmfg2d")
	if error {
		fmt.println("ERROR: init_game_window() failed.")
		return
	}
	defer glfw.DestroyWindow(game_window.handle)

	glfw.MakeContextCurrent(game_window.handle)
	glfw.SwapInterval(1)
	glfw.SetFramebufferSizeCallback(game_window.handle, size_callback)

	gl.load_up_to(GL_MAJOR_VERSION, GL_MINOR_VERSION, glfw.gl_set_proc_address)
	game_shaders = load_all_shaders()
	game_controls = init_game_controls()

	for !glfw.WindowShouldClose(game_window.handle) {
        glfw.PollEvents()
		set_game_controls_state()

		if game_controls.mouse.buttons[.m1].is_down {
			draw_selection_box = true
			if game_controls.mouse.buttons[.m1].pressed {
				box_start_ndc = get_px_pos_to_ndc(game_controls.mouse.window_pos.x, game_controls.mouse.window_pos.y)
			}
			box_end_ndc = get_px_pos_to_ndc(game_controls.mouse.window_pos.x, game_controls.mouse.window_pos.y)
		}
		else {
			draw_selection_box = false
		}

		if game_controls.keyboard.keys[.v].pressed {
			display_allocations_tracker(&mem_tracker)
		}

        gl.ClearColor(CL_COLOR_DEFAULT.r, CL_COLOR_DEFAULT.g, CL_COLOR_DEFAULT.b, 1.0)
		gl.Clear(gl.COLOR_BUFFER_BIT)

		if game_controls.keyboard.keys[.e].is_down {
			draw_rect_2d_filled(get_rect_2d_anchor_vh_to_ndc(.top_right, {5, 5}, {25, 25}), {1.0, 0.5, 0.0})
			draw_line_2d({{-0.5, 0.6}, {0.6, 0}}, {0.2, 0.2, 0.5}, 3.0)
		}

		if draw_selection_box == true {
			draw_rect_2d_lined({box_start_ndc, box_end_ndc}, {0.3, 0.5, 0.3}, 2.0)
		}

        glfw.SwapBuffers(game_window.handle)
    }

	deallocate_memory()
	defer display_allocations_tracker_program_end(&mem_tracker)
}
