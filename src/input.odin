package main

import glfw "vendor:glfw"

InputKey :: enum {
        m1,m2,
        num1,num2,num3,num4,num5,num6,num7,num8,num9,num0,
        q,w,e,r,t,y,u,i,o,p,a,s,d,f,g,h,j,k,l,z,x,c,v,b,n,m,
        ctrl,space,shift,esc,tab,enter,
        f1,f2,f3,f4,f5,f6,f7,f8,f9,f10,f11,f12,
}

KeyCode :: struct {
        glfw_code: i32,
        key: InputKey,
}

InputState :: struct {
	pressed: bool,
	is_down: bool,
}

KeyInput :: struct {
        key: KeyCode,
        state: InputState,
}

KeyboardControls :: struct {
	keys: map[InputKey]KeyInput,
}

@(private)
game_keys := [?]KeyCode{
        {glfw.KEY_ESCAPE, .esc},
        {glfw.KEY_F1, .f1},
        {glfw.KEY_Q, .q}, {glfw.KEY_W, .w}, {glfw.KEY_E, .e}, {glfw.KEY_R, .r}, {glfw.KEY_T, .t}, {glfw.KEY_Y, .y}, {glfw.KEY_I, .i}, {glfw.KEY_O, .o}, {glfw.KEY_P, .p}
}

MouseControls :: struct {
	window_pos: Vec2,
	buttons: map[InputKey]KeyInput,
}

@(private)
mouse_buttons := [?]KeyCode{
        {glfw.MOUSE_BUTTON_1, .m1}, {glfw.MOUSE_BUTTON_2, .m2}
}

GameControls :: struct {
	mouse: MouseControls,
	keyboard: KeyboardControls,
}

init_game_controls :: proc() -> GameControls {
	controls : GameControls
        for key_code in mouse_buttons {
                controls.mouse.buttons[key_code.key] = {{key_code.glfw_code, key_code.key}, {}}
        }
        for key_code in game_keys {
                controls.keyboard.keys[key_code.key] = {{key_code.glfw_code, key_code.key}, {}}
        }
	return controls
}

set_game_frame_controls_state :: proc() {
	x, y := glfw.GetCursorPos(game_window.handle);
	game_controls.mouse.window_pos = {f32(x), game_window.size_px.y - f32(y)}
	for _, &button in game_controls.mouse.buttons {
		state := glfw.GetMouseButton(game_window.handle, button.key.glfw_code)
		if state == glfw.PRESS {
			button.state.pressed = false if button.state.is_down == true else true
			button.state.is_down = true
		}
		else {
			button.state.is_down = false
                        button.state.pressed = false
		}
	}
	for _, &key in game_controls.keyboard.keys {
		state := glfw.GetKey(game_window.handle, key.key.glfw_code)
		if state == glfw.PRESS {
			key.state.pressed = false if key.state.is_down == true else true
			key.state.is_down = true
		}
		else {
			key.state.is_down = false
                        key.state.pressed = false
		}
	}
}

