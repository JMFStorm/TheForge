package main

import glfw "vendor:glfw"

UiAnchorPoint :: enum {
	top_left,
	top_right,
	center,
	bot_left,
	bot_right
}

Vec2 :: struct {
	x: f32,
	y: f32
}

Vec3 :: struct {
	x: f32,
	y: f32,
	z: f32
}

Color3 :: struct {
	r: f32,
	g: f32,
	b: f32
}

GameWindow :: struct {
	handle: glfw.WindowHandle,
	size_px: Vec2,
	aspect_ratio_xy: f32
}

SimpleRectangle2DShader :: struct {
	vbo: u32,
	vao: u32,
	shader_id: u32
}

GameShaders :: struct {
	simple_rectangle_2d: SimpleRectangle2DShader
}

Rect2D_NDC :: struct {
	bot_left: Vec2, // ndc
	top_right: Vec2 // ndc
}
