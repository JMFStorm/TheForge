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

test_font_1 : TTF_Font

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

	imui_init()

	{
		f_handle, error := os.open("G:\\projects\\game\\TheForge\\resources\\fonts\\Inter-Regular.ttf")
		if error != 0 {
			panic("ERROR: Get file handle")
		}
		defer os.close(f_handle)
	
		file_buffer := make([]u8, 1024 * 1024 * 5)
		bytes_read, read_error := os.read(f_handle, file_buffer[:])
		if read_error != 0 {
			panic("ERROR: Read file")
		}

		font_info: stbtt.fontinfo
		success := stbtt.InitFont(&font_info, raw_data(file_buffer[:]), 0)
		if !success {
			fmt.println("ERROR: InitFont()")
		}
		font_height_px : f32 = 32.0
		font_scaling := stbtt.ScaleForPixelHeight(&font_info, font_height_px)
		test_font_1.font_scaling = font_scaling
		fmt.println("font_scaling:", font_scaling)

		current_x : i32 = 0
		for char in "fajLHGaq" {
			width, height, xoff, yoff: c.int
			bitmap := stbtt.GetCodepointBitmap(&font_info, 0, font_scaling, char, &width, &height, &xoff, &yoff)
			fmt.println(char, "width", width, "height", height, "xoff", xoff, "yoff", yoff)
			y_offset := height + yoff
			fmt.println("y_offset", y_offset)

			current := CodepointBitmapInfo{width, height, xoff, yoff}
			test_font_1.codepoints[char] = current
			stbtt.FreeBitmap(bitmap, nil)

			current_x += width
			fmt.println("current_x", current_x)
		}

		test_font_1.texture_atlas_size.x = f32(current_x)
		test_font_1.texture_atlas_size.y = font_height_px

		fmt.println("texture_atlas_size", test_font_1.texture_atlas_size.x, "/", test_font_1.texture_atlas_size.y)

		current_x = 0
		atlas_bitmap := make([]u8, i32(test_font_1.texture_atlas_size.x * test_font_1.texture_atlas_size.y))
		for char in "fajLHGaq" {
			width, height, xoff, yoff: c.int
			bitmap := stbtt.GetCodepointBitmap(&font_info, 0, font_scaling, char, &width, &height, &xoff, &yoff)
			y_offset := height + yoff
			for i : i32 = 0; i < height; i += 1 {
				src_offset := (height * width) - width * (i + 1)
				source := &bitmap[src_offset]
				// dest_offset := (i32(test_font_1.texture_atlas_size.x) * i) + current_x
				// buffer them on top
				dest_offset := (i32(test_font_1.texture_atlas_size.x) * i) + current_x
				dest := &atlas_bitmap[dest_offset]
				mem.zero(dest, int(width))
				mem.copy(dest, source, int(width))
			}
			stbtt.FreeBitmap(bitmap, nil)
			current_x += width
		}

		gl.PixelStorei(gl.UNPACK_ALIGNMENT, 1)
		gl.GenTextures(1, &test_font_1.texture_atlas_id)
		gl.BindTexture(gl.TEXTURE_2D, test_font_1.texture_atlas_id)
		gl.TexImage2D(gl.TEXTURE_2D, 0, gl.RED, i32(test_font_1.texture_atlas_size.x), i32(test_font_1.texture_atlas_size.y), 0, gl.RED, gl.UNSIGNED_BYTE, raw_data(atlas_bitmap[:]))
		gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE)
		gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE)
		gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR)
		gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST)
		gl.PixelStorei(gl.UNPACK_ALIGNMENT, 4)
	}

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
			fmt.println("Debug")
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

		rect1_dimensions := ui_rect2d_anchored_to_ndc(.bot_left, {vw(0), vh(0)}, {vh(80), vh(50)})
		draw_rect_2d(rect1_dimensions, {1.0, 1.0, 1.0}, test_font_1.texture_atlas_id)

		if draw_selection_box == true {
			draw_rect_2d_lined({box_start_ndc, box_end_ndc}, {0.3, 0.4, 0.35}, 2.0)
		}

		imui_render()
        glfw.SwapBuffers(game_window.handle)
    }
}
