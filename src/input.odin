package main

import glfw "vendor:glfw"

set_game_frame_controls_state :: proc() {
	x, y := glfw.GetCursorPos(game_window.handle);
	game_controls.mouse.window_pos = {f32(x), game_window.size_px.y - f32(y)}
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

