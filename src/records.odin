package main

import glfw "vendor:glfw"

UiAnchorPoint :: enum {
	top_left,
	top_right,
	center,
	bot_left,
	bot_right,
}

KeyState :: struct {
	key: i32,
	pressed: bool,
	is_down: bool,
}

MouseButtons :: enum {
	m1,
	m2,
}

MouseControls :: struct {
	window_pos: Vec2,
	buttons: map[MouseButtons]KeyState,
}

KeyboardKeys :: enum {
	e,
	v,
        esc,
}

KeyboardControls :: struct {
	keys: map[KeyboardKeys]KeyState,
}

GameControls :: struct {
	mouse: MouseControls,
	keyboard: KeyboardControls,
}

GameMainState :: enum {
        main_menu,
        main_game,
}

MainGameState :: enum {
        main_game,
        pause_menu,
}

MainMenuState :: enum {
        main_menu,
        settings,
}

GameLogicState :: struct {
        game_running: bool,
        frames: int,
        main_state: GameMainState,
        main_game_state: MainGameState,
        main_menu_state: MainMenuState,
}

GameWindow :: struct {
	handle: glfw.WindowHandle,
	size_px: Vec2,
	aspect_ratio_xy: f32,
}

Line2D_NDC :: struct {
	start: Vec2,
	end: Vec2,
}

Rect2D_NDC :: struct {
	bot_left: Vec2,
	top_right: Vec2,
}

Rect2D_px :: struct {
	bot_left: Vec2,
	top_right: Vec2,
}

ImageData :: struct {
	filename: string,
    width_px: i32,
    height_px: i32,
    channels: i32,
    data: rawptr
}

TextureData :: struct {
	name: string,
	texture_id: u32,
	width_px: i32,
	height_px: i32,
	has_alpha: bool,
}

ImUiBuffers :: struct {
	ui_rects: SimpleShader,
	buffered_rects_2d: int,
        ui_text: SimpleShader,
	buffered_text: int,
}
