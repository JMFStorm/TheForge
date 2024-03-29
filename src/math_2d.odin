package main

get_rect_2d_vh_to_ndc :: proc(bot_left_vh, size_vh: Vec2) -> Rect2D_NDC {
	x0_ndc : f32 = ((bot_left_vh.x / 100) * 2) - 1.0
	y0_ndc : f32 = ((bot_left_vh.y / 100) * 2) - 1.0

	height_px : f32 = game_window.size_px.y * (size_vh.y / 100)
	width_px : f32 = height_px * (size_vh.x / size_vh.y)

	width_percentage := width_px / game_window.size_px.x
	height_percentage := height_px / game_window.size_px.y

	x1_ndc : f32 = (((bot_left_vh.x / 100) + width_percentage) * 2) - 1.0
	y1_ndc : f32 = (((bot_left_vh.y / 100) + height_percentage) * 2) - 1.0

	return Rect2D_NDC{{x0_ndc, y0_ndc}, {x1_ndc, y1_ndc}}
}

get_rect_2d_anchor_vh_to_ndc :: proc(anchor: UiAnchorPoint, bot_left_vh, size_vh: Vec2) -> Rect2D_NDC {
	used_bot_left := bot_left_vh
	used_size_vh := size_vh
	switch anchor {
		case .top_left: {
			used_bot_left.y = 100.0 - bot_left_vh.y
			used_size_vh.y = used_size_vh.y * (-1)
		}
		case .top_right: {
			used_bot_left.x = 100.0 - bot_left_vh.x
			used_size_vh.x = used_size_vh.x * (-1)
			used_bot_left.y = 100.0 - bot_left_vh.y
			used_size_vh.y = used_size_vh.y * (-1)
		}
		case .center: {
			used_bot_left.x = bot_left_vh.x + 50
			used_bot_left.y = bot_left_vh.y + 50
		}
		case .bot_left: // nada
		case .bot_right: {
			used_bot_left.x = 100.0 - bot_left_vh.x
			used_size_vh.x = used_size_vh.x * (-1)
		}
	}
	return get_rect_2d_vh_to_ndc(used_bot_left, used_size_vh)
}