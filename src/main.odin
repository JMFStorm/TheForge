package main

import gl "vendor:OpenGL"
import glfw "vendor:glfw"
import stbtt "vendor:stb/truetype"

import "core:c"
import "core:os"
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
	game_fonts = load_all_fonts()

	imui_init()

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
                if game_controls.keyboard.keys[.e].pressed {
                        game_fonts = load_all_fonts()
                        fmt.println("Reloaded fonts.")
                }
		button1_dimensions := ui_rect2d_anchored_to_ndc(.top_left, {vw(2.5), vh(2.5)}, {vh(20), vh(15)})
		if imui_menu_button(button1_dimensions) { 
                        fmt.println("Button1") 
                }
		button2_dimensions := ui_rect2d_anchored_to_ndc(.top_right, {vw(3.5), vh(3.5)}, {vh(10), vh(12.5)})
		if imui_menu_button(button2_dimensions) { 
                        fmt.println("Button2") 
                }

                gl.ClearColor(CL_COLOR_DEFAULT.r, CL_COLOR_DEFAULT.g, CL_COLOR_DEFAULT.b, 1.0)
	        gl.Clear(gl.COLOR_BUFFER_BIT)

	        draw_rect_2d({{-0.75, -0.75}, {-0.25, -0.25}}, {1.0, 0.5, 0.0})
	        draw_line_2d({{-0.5, 0.6}, {0.6, 0}}, {0.2, 0.2, 0.5}, 3.0)

	        rect1_dimensions := ui_rect2d_anchored_to_ndc(.bot_left, {vw(1), vh(1)}, {vw(260), vh(25)})
	        draw_rect_2d(rect1_dimensions, {1.0, 1.0, 1.0}, game_fonts.debug_font.texture_atlas_id)

	        char1_dimensions := ui_rect2d_anchored_to_ndc(.top_right, {vh(12), vh(12)}, {vh(20), vh(25)})
	        draw_character(char1_dimensions.bot_left, {0.0, 1.0 , 0.0}, &game_fonts.debug_font, 'P')

                start := ui_rect2d_anchored_to_ndc(.top_left, {vh(2), vh(25)}, {vh(40), vh(15)})
                cursor := draw_text(start.bot_left, {0.8, 0.8, 0.8}, &game_fonts.debug_font, "FPS: 165   Frame: 90001", true)
                draw_text(cursor, {0.8, 0.8, 0.8}, &game_fonts.debug_font, "Delta: 6.66ms   Draw calls: 184")

	        if draw_selection_box == true {
		        draw_rect_2d_lined({box_start_ndc, box_end_ndc}, {0.3, 0.4, 0.35}, 2.0)
	        }

	        imui_render()
                glfw.SwapBuffers(game_window.handle)
        }
}
