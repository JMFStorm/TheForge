package main

import glfw "vendor:glfw"

UiAnchorPoint :: enum {
	top_left,
	top_right,
	center,
	bot_left,
	bot_right,
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
        display_console: bool,
        frames: int,
        main_state: GameMainState,
        main_game_state: MainGameState,
        main_menu_state: MainMenuState,
}

GameWindow :: struct {
	handle: glfw.WindowHandle,
	size_px: Vec2,
        is_fullscreen: bool,
}

GameMonitor :: struct {
        handle: glfw.MonitorHandle,
        width: i32,
        height: i32,
        refresh_rate: i32,
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
        data: [^]byte
}

TextureData :: struct {
	name: string,
	texture_id: u32,
	width_px: i32,
	height_px: i32,
	has_alpha: bool,
}
