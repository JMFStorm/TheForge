package main

import gl "vendor:OpenGL"
import glfw "vendor:glfw"
import stbtt "vendor:stb/truetype"

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

init_game_window :: proc(x, y: i32, title: cstring) -> (window: GameWindow, error: bool) {
	// glfw.WindowHint(glfw.RESIZABLE, 0)
	glfw.WindowHint(glfw.MAXIMIZED, 1)
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
        init_global_temporary_allocator(mem.Megabyte * 15)
        logger_data := new(log.File_Console_Logger_Data)
        defer free(logger_data)
	when ODIN_DEBUG {
		mem.tracking_allocator_init(&mem_tracker, context.allocator)
		context.allocator = mem.tracking_allocator(&mem_tracker)
		defer display_allocations_tracker(&mem_tracker)
		defer deallocate_all_memory()
                context.logger = create_debug_build_logger(logger_data)
                log_info("Game started. Debug build.")
	}
        else {
                context.logger = create_release_build_logger(logger_data)
                log_info("Game started. Release build.")
        }
        str_perma_allocator = init_str_perma_allocator(mem.Kilobyte * 512)
        set_game_file_info()
        free_all(context.temp_allocator)
        
	if success := glfw.Init(); success == false {
                log_and_panic("glfw.Init() failed")
	}
	defer glfw.Terminate()

	window_error: bool
	game_window, window_error = init_game_window(1200, 900, "jmfg2d")
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

                if game_controls.keyboard.keys[.v].pressed { 
                        display_allocations_tracker(&mem_tracker)
                        debug_display_all_perma_strings()
                        load_all_fonts()
                }

                menu_text_size = vh(7.5)

                switch game_logic_state.main_state {
                        case .main_menu: {
                                switch game_logic_state.main_menu_state {
                                        case .main_menu: {
                                                // IMUI
                                                imui_menu_title("Main menu", menu_text_size)
                                                play_dimensions := ui_rect2d_anchored_to_ndc(.center, {0, vh(5)}, {vh(25), menu_text_size})
                                                if imui_menu_button(play_dimensions, "Play", vh(5)) { 
                                                        log_debug("Play game") 
                                                        game_logic_state.main_state = .main_game
                                                }
                                                setings_dimensions := ui_rect2d_anchored_to_ndc(.center, {0, -vh(10)}, {vh(25), menu_text_size})
                                                if imui_menu_button(setings_dimensions, "Settings", vh(5)) { 
                                                        log_debug("Settings") 
                                                        game_logic_state.main_menu_state = .settings
                                                }
                                                exit_rect := ui_rect2d_anchored_to_ndc(.center, {0, -vh(25)}, {vh(25), menu_text_size})
                                                if imui_menu_button(exit_rect, "Exit", vh(5)) { 
                                                        game_logic_state.game_running = false
                                                }

                                                // LOGIC
                                        }
                                        case .settings: {
                                                // IMUI
                                                imui_menu_title("Settings", menu_text_size)
                                                bo_back_rect := ui_rect2d_anchored_to_ndc(.center, {0, -vh(25)}, {vh(25), menu_text_size})
                                                if imui_menu_button(bo_back_rect, "Go back", vh(5)) { 
                                                        log_debug("Go back") 
                                                        game_logic_state.main_menu_state = .main_menu
                                                }

                                                // LOGIC
                                        }
                                }
                        }
                        case .main_game: {
                                switch game_logic_state.main_game_state {
                                        case .main_game: {
                                                // IMUI
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
                                                if game_controls.keyboard.keys[.esc].pressed {
                                                        log_debug("to pause") 
                                                        game_logic_state.main_game_state = .pause_menu
                                                }

                                                // LOGIC
                                        }
                                        case .pause_menu: {
                                                // IMUI
                                                imui_menu_title("Pause menu", menu_text_size)
                                                main_menu_rect := ui_rect2d_anchored_to_ndc(.center, {0, -vh(25)}, {vh(25), menu_text_size})
                                                if imui_menu_button(main_menu_rect, "To main menu", vh(5)) {
                                                        game_logic_state.main_state = .main_menu
                                                }

                                                // LOGIC
                                                if game_controls.keyboard.keys[.esc].pressed {
                                                        log_debug("to play game") 
                                                        game_logic_state.main_game_state = .main_game
                                                }
                                        }
                                }
                        }
                }
                // DRAW SCREEN
                gl.ClearColor(CL_COLOR_DEFAULT.r, CL_COLOR_DEFAULT.g, CL_COLOR_DEFAULT.b, 1.0)
                gl.Clear(gl.COLOR_BUFFER_BIT)
                if draw_selection_box == true {
                        draw_rect_2d_lined({box_start_ndc, box_end_ndc}, {0.3, 0.4, 0.35}, 2.0)
                }
	        imui_render()
                display_debug_info()
                glfw.SwapBuffers(game_window.handle)
                game_logic_state.frames += 1
                free_all(context.temp_allocator)
        }
        log_info("Game terminated.")
}

display_debug_info :: proc() {
        font_size := vh(2)
        start := ui_point_anchored_to_ndc(.top_left, {vh(0.5), vh(0)})
        start.y -= get_px_height_to_ndc(font_size)
        str_1 := fmt.tprintf("Frames: {}", game_logic_state.frames)
        cursor := draw_text(start, {0.9, 0.9, 0.9}, &game_fonts.debug_font, str_1, font_size)
}
