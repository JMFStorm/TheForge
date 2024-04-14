package main

import gl "vendor:OpenGL"
import glfw "vendor:glfw"
import stbtt "vendor:stb/truetype"
import stbi "vendor:stb/image"

import "core:c"
import "core:os"
import "core:fmt"
import "core:log"
import "core:mem"
import "core:mem/virtual"
import "base:runtime"

draw_selection_box := false
box_start_ndc : Vec2
box_end_ndc : Vec2

init_game_window :: proc() -> (window: GameWindow, error: bool) {
        monitor := glfw.GetPrimaryMonitor()
        mode := glfw.GetVideoMode(monitor)
	glfw.WindowHint(glfw.CONTEXT_VERSION_MAJOR, GL_MAJOR_VERSION)
	glfw.WindowHint(glfw.CONTEXT_VERSION_MINOR, GL_MINOR_VERSION)
	glfw.WindowHint(glfw.OPENGL_PROFILE, glfw.OPENGL_CORE_PROFILE)
        game_monitor.handle = monitor
        game_monitor.width = mode.width
        game_monitor.height = mode.height
        game_monitor.refresh_rate = mode.refresh_rate
	window_handle := glfw.CreateWindow(1200, 900, "The Forge", nil, nil)
	if window_handle == nil {
		return {}, true
	}
	return GameWindow{window_handle, {f32(1200), f32(900)}, false}, false
}

size_callback :: proc "c" (window: glfw.WindowHandle, width, height: i32) {
        context = runtime.default_context()
        gl.Viewport(0, 0, width, height)
        game_window.size_px.x = f32(width)
        game_window.size_px.y = f32(height)
}

set_game_cursor :: proc() -> glfw.CursorHandle {
        set_image_load_flip_vertical(false)
        image_data := load_image_data("cursor_01.png")
        i_data := glfw.Image{image_data.width_px, image_data.height_px, image_data.data}
        cursor := glfw.CreateCursor(&i_data, 0, 0)
        glfw.SetCursor(game_window.handle, cursor)
        return cursor
}

main :: proc() {
        init_global_temporary_allocator(mem.Megabyte * 15)
        str_perma_allocator = init_str_perma_allocator(mem.Kilobyte * 512)

	when ODIN_DEBUG {
		mem.tracking_allocator_init(&mem_tracker, context.allocator)
		context.allocator = mem.tracking_allocator(&mem_tracker)
		defer display_allocations_tracker(&mem_tracker)
		defer deallocate_all_memory()
	}

        set_game_file_info()
        init_loggers()
        free_all(context.temp_allocator)

        when ODIN_DEBUG {
                log_info("Game started. Debug build.")
	}
        else {
                log_info("Game started. Release build.")
        }
        
	if success := glfw.Init(); success == false {
                log_and_panic("glfw.Init() failed")
	}
	defer glfw.Terminate()

	window_error: bool
	game_window, window_error = init_game_window()
	if window_error {
		log_and_panic("init_game_window() failed")
	}
	defer glfw.DestroyWindow(game_window.handle)

	glfw.MakeContextCurrent(game_window.handle)
	glfw.SwapInterval(1)
	glfw.SetFramebufferSizeCallback(game_window.handle, size_callback)

	gl.load_up_to(GL_MAJOR_VERSION, GL_MINOR_VERSION, glfw.gl_set_proc_address)
	gl.Enable(gl.BLEND)
	gl.BlendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA)

        main_cursor = set_game_cursor()
	game_textures = load_all_textures()
	game_shaders = load_all_shaders()
	game_controls = init_game_controls()
	game_fonts = load_all_fonts()
        free_all(context.temp_allocator)

	imui_init()
        game_logic_state.main_state = .main_menu
        game_logic_state.game_running = true

	for !glfw.WindowShouldClose(game_window.handle) && game_logic_state.game_running {
                glfw.PollEvents()
		set_game_frame_controls_state()

                if game_controls.keyboard.keys[.q].state.pressed { 
                        log_debug("Q pressed")
                        debug_print_console_logs()
                }

                if game_controls.keyboard.keys[.f1].state.pressed {
                        game_logic_state.display_console = true if game_logic_state.display_console == false else false
                }

                if game_controls.keyboard.keys[.w].state.pressed {
                        log_debug("W pressed")
                        if glfw.GetWindowMonitor(game_window.handle) != nil {
                                glfw.SetWindowMonitor(game_window.handle, nil, 100, 100, 1200, 900, glfw.DONT_CARE)
                                game_window.is_fullscreen = false
                        }
                        else {
                                glfw.SetWindowMonitor(game_window.handle, game_monitor.handle, 0, 0, game_monitor.width,  game_monitor.height, game_monitor.refresh_rate)
                                game_window.is_fullscreen = true
                        }
                }

                menu_title_text_size = vh(7.5)
                menu_text_size = vh(5)
                
                switch game_logic_state.main_state {
                        case .main_menu: {
                                main_menu_logic()
                        }
                        case .main_game: {
                                main_game_logic()
                        }
                }

                // DRAW SCREEN
                gl.ClearColor(CL_COLOR_DEFAULT.r, CL_COLOR_DEFAULT.g, CL_COLOR_DEFAULT.b, 1.0)
                gl.Clear(gl.COLOR_BUFFER_BIT)
                draw_rect_2d({{0,0}, {0.5, 0.5}}, {1.0, 1.0, 0}, game_textures["awesomeface"].texture_id)
                draw_character({-0.6,0}, {0.1,0.1,0.1}, &game_fonts.debug_font, 'X')
                if draw_selection_box == true {
                        draw_rect_2d_lined({box_start_ndc, box_end_ndc}, {0.3, 0.4, 0.35}, 2.0)
                }
                if check_1_is_checked {
                        draw_text({-0.25, -0.25}, {0.1, 0.9, 0.1}, &game_fonts.debug_font, "check_1_is_checked", 30)
                }
	        imui_render()
                if game_logic_state.display_console == true {
                        display_console()
                }
                display_debug_info()
                glfw.SwapBuffers(game_window.handle)
                game_logic_state.frames += 1
                free_all(context.temp_allocator)
        }
        log_info("Game terminated.")
}

display_console :: proc() {
        logs_count, start_index := get_logs_display_indexes()
        font_size := vh(1.75)
        cursor := ui_point_anchored_to_ndc(.top_left, {vh(0.5), vh(0)})
        cursor.y -= get_px_height_to_ndc(font_size)
        for i in 0 ..< logs_count {
                index := (start_index + i) % STRING_CONSOLE_BUFFER_LENGTH
                str := console_str_buffer.strings[index]
                cursor = draw_text(cursor, {0.9, 0.9, 0.9}, &game_fonts.debug_font, str, font_size, true)
        }
}

display_debug_info :: proc() {
        font_size := vh(2)
        start := ui_point_anchored_to_ndc(.top_left, {vh(0.5), vh(0)})
        start.y -= get_px_height_to_ndc(font_size)
        str_1 := fmt.tprintf("Frames: {}", game_logic_state.frames)
        cursor := draw_text(start, {0.9, 0.9, 0.9}, &game_fonts.debug_font, str_1, font_size)
}
