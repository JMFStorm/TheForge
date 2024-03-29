package main

import glfw "vendor:glfw"

game_window : GameWindow

game_controls: GameControls
init_game_controls :: proc() -> GameControls {
	controls : GameControls
	controls.mouse.buttons[.m1] = {glfw.MOUSE_BUTTON_LEFT, false, false}
	controls.mouse.buttons[.m2] = {glfw.MOUSE_BUTTON_RIGHT, false, false}
	controls.keyboard.keys[.e] = {glfw.KEY_E, false, false} 
	controls.keyboard.keys[.v] = {glfw.KEY_V, false, false} 
	return controls
}

game_shaders : GameShaders