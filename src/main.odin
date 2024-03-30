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
	// glfw.WindowHint(glfw.RESIZABLE, 0)
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
	game_window.size_px.x = f32(width)
	game_window.size_px.y = f32(height)
	game_window.aspect_ratio_xy = f32(width) / f32(height)
}

main :: proc() {
	when ODIN_DEBUG {
		fmt.println("ODIN DEBUG BUILD")
		mem.tracking_allocator_init(&mem_tracker, context.allocator)
		context.allocator = mem.tracking_allocator(&mem_tracker)
		defer display_allocations_tracker_program_end(&mem_tracker)
		defer deallocate_all_memory()
	}

	if success := glfw.Init(); success == false {
		fmt.println("ERROR: glfw.Init() failed.")
		return
	}
	defer glfw.Terminate()

	error: bool
	game_window, error = init_game_window(1200, 900, "jmfg2d")
	if error {
		fmt.println("ERROR: init_game_window() failed.")
		return
	}
	defer glfw.DestroyWindow(game_window.handle)

	glfw.MakeContextCurrent(game_window.handle)
	glfw.SwapInterval(1)
	glfw.SetFramebufferSizeCallback(game_window.handle, size_callback)

	gl.load_up_to(GL_MAJOR_VERSION, GL_MINOR_VERSION, glfw.gl_set_proc_address)

	gl.Enable(gl.BLEND)
	gl.BlendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA)
	game_textures = load_all_textures()
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

		draw_rect_2d({{-0.25, -0.25}, {0.25, 0.25}}, {1.0, 0.5, 0.0})
		draw_line_2d({{-0.5, 0.6}, {0.6, 0}}, {0.2, 0.2, 0.5}, 3.0)

		rect1_dimensions := ui_rect2d_anchored_to_ndc(.center, {vw(0), vh(0)}, {vh(25), vh(25)})
		draw_rect_2d(rect1_dimensions, {1.0, 1.0, 1.0}, game_textures["wall"].texture_id)

		if draw_selection_box == true {
			draw_rect_2d_lined({box_start_ndc, box_end_ndc}, {0.3, 0.5, 0.3}, 2.0)
		}

        glfw.SwapBuffers(game_window.handle)
    }
}
