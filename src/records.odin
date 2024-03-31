package main

import glfw "vendor:glfw"

UiAnchorPoint :: enum {
	top_left,
	top_right,
	center,
	bot_left,
	bot_right,
}

Vec2 :: struct {
	x: f32,
	y: f32,
}

Vec3 :: struct {
	x: f32,
	y: f32,
	z: f32
}

Color3 :: struct {
	r: f32,
	g: f32,
	b: f32,
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

SimpleShader :: struct {
	vbo: u32,
	vao: u32,
	shader_id: u32,
}

GameShaders :: struct {
	simple_rectangle_2d: SimpleShader,
	line_2d: SimpleShader,
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
	codepoints: map[rune]CodepointBitmapInfo,
}

CodepointBitmapInfo :: struct {
	width: i32,
	height: i32,
	xoff: i32,
	yoff: i32,
}