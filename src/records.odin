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
}

KeyboardControls :: struct {
	keys: map[KeyboardKeys]KeyState,
}

GameControls :: struct {
	mouse: MouseControls,
	keyboard: KeyboardControls,
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
}

TTF_Font :: struct {
	font_scaling: f32,
	texture_atlas_id: u32,
	texture_atlas_size: Vec2,
	codepoints: [96]CodepointBitmapInfo,
}

CodepointBitmapInfo :: struct {
	char: rune,
	width: i32,
	height: i32,
	xoff: i32,
	yoff: i32,
	atlas_uv_00: Vec2,
	atlas_uv_11: Vec2,
}