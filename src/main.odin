package main

import gl "vendor:OpenGL"
import glfw "vendor:glfw"

import "core:fmt"
import "core:runtime"

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

key_callback :: proc "c" (window : glfw.WindowHandle, key, scancode, action, mods : i32) {
	context = runtime.default_context()
	if (key == glfw.KEY_E && action == glfw.PRESS) {
        fmt.println("PRESS")
	}
}

size_callback :: proc "c" (window: glfw.WindowHandle, width, height: i32) {
	gl.Viewport(0, 0, width, height)
}

main :: proc() {
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
	glfw.SetKeyCallback(game_window.handle, key_callback)

	gl.load_up_to(GL_MAJOR_VERSION, GL_MINOR_VERSION, glfw.gl_set_proc_address)

	game_shaders = load_all_shaders()

	for !glfw.WindowShouldClose(game_window.handle) {
        glfw.PollEvents()

        gl.ClearColor(CL_COLOR_DEFAULT.r, CL_COLOR_DEFAULT.g, CL_COLOR_DEFAULT.b, 1.0)
		gl.Clear(gl.COLOR_BUFFER_BIT)

		rect_dimensions_1 := get_rect_2d_anchor_vh_to_ndc(.top_right, {5, 5}, {25, 25})
		draw_rect_2d(rect_dimensions_1, {1.0, 0.5, 0.0})

		rect_dimensions_2 := get_rect_2d_anchor_vh_to_ndc(.bot_right, {20, 10}, {33, 33})
		draw_rect_2d(rect_dimensions_2, {1.0, 0.5, 0.8})

        glfw.SwapBuffers(game_window.handle)
    }
}
