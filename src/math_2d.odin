package main

Vec2 :: [2]f32
Vec3 :: [3]f32
Color3 :: [3]f32

get_rect_2d_vh_to_ndc :: proc(bot_left_vh, size_vh: Vec2) -> Line2D_NDC {
	x0_ndc : f32 = ((bot_left_vh.x / 100) * 2) - 1.0
	y0_ndc : f32 = ((bot_left_vh.y / 100) * 2) - 1.0

	height_px : f32 = game_window.size_px.y * (size_vh.y / 100)
	width_px : f32 = height_px * (size_vh.x / size_vh.y)

	width_percentage := width_px / game_window.size_px.x
	height_percentage := height_px / game_window.size_px.y

	x1_ndc : f32 = (((bot_left_vh.x / 100) + width_percentage) * 2) - 1.0
	y1_ndc : f32 = (((bot_left_vh.y / 100) + height_percentage) * 2) - 1.0

	return Line2D_NDC{{x0_ndc, y0_ndc}, {x1_ndc, y1_ndc}}
}

vh :: proc(vh: f32) -> f32 {
	return (vh / 100) * game_window.size_px.y
}

vw :: proc(vw: f32) -> f32 {
	return (vw / 100) * game_window.size_px.x
}

min :: proc(a: f32, b: f32) -> f32 {
        return a if a < b else b
}

max :: proc(a: f32, b: f32) -> f32 {
        return b if a < b else a
}

ui_point_anchored_to_ndc :: proc(anchor: UiAnchorPoint, corner_dist_from_anchor_px: Vec2) -> Vec2 {
	ndc_result : Vec2
        width_percentage  : f32 = corner_dist_from_anchor_px.x / game_window.size_px.x
	height_percentage : f32 = corner_dist_from_anchor_px.y / game_window.size_px.y
        height_ndc : f32 = 2 * height_percentage
	width_ndc : f32 = 2 * width_percentage
        switch anchor {
		case .top_left: {
			ndc_result = {-1.0 + width_ndc, 1.0 - height_ndc}
		}
		case .top_right: {
                        ndc_result = {1.0 - width_ndc, 1.0 - height_ndc}
		}
		case .center: {
                        ndc_result = {0.0 + width_ndc, 0.0 + height_ndc}
		}       
		case .bot_left: {
                        ndc_result = {-1.0 + width_ndc, -1.0 + height_ndc}
		}
		case .bot_right: {
                        ndc_result = {1.0 - width_ndc, -1.0 + height_ndc}
		}
	}
        return ndc_result
}

ui_rect2d_anchored_to_ndc :: proc(
	anchor: UiAnchorPoint,
	corner_dist_from_anchor_px: Vec2,
	size_px: Vec2) -> Rect2D_NDC 
{
	bot_left : Vec2
	top_right : Vec2
	width_percentage  : f32 = size_px.x / game_window.size_px.x
	height_percentage : f32 = size_px.y / game_window.size_px.y
	height_ndc : f32 = 2 * height_percentage
	width_ndc : f32 = 2 * width_percentage
	dist_x_percentage : f32 = corner_dist_from_anchor_px.x / game_window.size_px.x
	dist_y_percentage : f32 = corner_dist_from_anchor_px.y / game_window.size_px.y
	dist_x_ndc : f32 = 2 * dist_x_percentage
	dist_y_ndc : f32 = 2 * dist_y_percentage
	switch anchor {
		case .top_left: {
			bot_left = {-1.0, 1.0} + {dist_x_ndc, -dist_y_ndc - height_ndc}
			top_right = bot_left + {width_ndc, height_ndc}
		}
		case .top_right: {
			top_right = {1.0, 1.0} + {-dist_x_ndc, -dist_y_ndc}
			bot_left = top_right + {-width_ndc, -height_ndc}
		}
		case .center: {
			width_half := width_ndc / 2
			height_half := height_ndc / 2
			bot_left = {0, 0} + {dist_x_ndc - width_half, dist_y_ndc - height_half}
			top_right = bot_left + {width_ndc, height_ndc}
		}
		case .bot_left: {
			bot_left = {-1.0, -1.0} + {dist_x_ndc, dist_y_ndc}
			top_right = bot_left + Vec2{width_ndc, height_ndc}
		}
		case .bot_right: {
			top_right = {1.0, -1.0} + {-dist_x_ndc, dist_y_ndc + height_ndc}
			bot_left = top_right + {-width_ndc, -height_ndc}
		}
	}
	return {bot_left, top_right}
}

get_px_pos_to_ndc :: proc(x, y: f32) -> Vec2 {
	x_percentage := x / game_window.size_px.x
	y_percentage := (game_window.size_px.y - y) / game_window.size_px.y
	x_ndc : f32 = (x_percentage * 2) - 1.0
	y_ndc : f32 = (y_percentage * 2) - 1.0
	return {x_ndc, y_ndc}
}

get_ndc_to_px :: proc(ndc: Vec2) -> Vec2 {
	x := (ndc.x + 1.0) * game_window.size_px.x / 2
	y := (ndc.y + 1.0) * game_window.size_px.y / 2
	return {x, y}
}

get_rect_ndc_to_px :: proc(ndc: Rect2D_NDC) -> Rect2D_px {
	bot_left := get_ndc_to_px(ndc.bot_left)
	top_right := get_ndc_to_px(ndc.top_right)
	return {bot_left, top_right}
}

rect_2d_point_collide :: proc(point_px: Vec2, rect: Rect2D_px) -> bool {
	used_height_px := game_window.size_px.y - point_px.y
	if rect.bot_left.x <= point_px.x && point_px.x <= rect.top_right.x {
		if rect.bot_left.y <= used_height_px && used_height_px <= rect.top_right.y {
			return true
		}
	}
	return false
}