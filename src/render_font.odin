package main

import gl "vendor:OpenGL"

draw_character :: proc(rect_coords: Rect2D_NDC, color: Color3, font_data: ^TTF_Font, char: rune) {
	bitmap_info := get_char_codepoint_bitmap_data(font_data, char)

	gl.BindVertexArray(game_shaders.simple_rectangle_2d.vao)
    rect_vertices := []f32 {
    	// Coords 								            // Color                          // UV
        rect_coords.bot_left.x,  rect_coords.top_right.y,   1.0, color.r, color.g, color.b,   bitmap_info.glyph_uv_bot_left.x,  bitmap_info.glyph_uv_top_right.y, // topleft
        rect_coords.top_right.x, rect_coords.top_right.y,   1.0, color.r, color.g, color.b,   bitmap_info.glyph_uv_top_right.x, bitmap_info.glyph_uv_top_right.y, // topright
        rect_coords.bot_left.x,  rect_coords.bot_left.y,    1.0, color.r, color.g, color.b,   bitmap_info.glyph_uv_bot_left.x,  bitmap_info.glyph_uv_bot_left.y, // botleft 

        rect_coords.bot_left.x,  rect_coords.bot_left.y,    1.0, color.r, color.g, color.b,   bitmap_info.glyph_uv_bot_left.x,  bitmap_info.glyph_uv_bot_left.y, // botleft 
        rect_coords.top_right.x, rect_coords.bot_left.y,    1.0, color.r, color.g, color.b,   bitmap_info.glyph_uv_top_right.x, bitmap_info.glyph_uv_bot_left.y, // botright
        rect_coords.top_right.x, rect_coords.top_right.y,   1.0, color.r, color.g, color.b,   bitmap_info.glyph_uv_top_right.x, bitmap_info.glyph_uv_top_right.y, // topright
    }
    gl.BindBuffer(gl.ARRAY_BUFFER, game_shaders.simple_rectangle_2d.vbo)
    gl.BufferData(gl.ARRAY_BUFFER, len(rect_vertices) * size_of(f32), raw_data(rect_vertices[:]), gl.DYNAMIC_DRAW)

    gl.UseProgram(game_shaders.simple_rectangle_2d.shader_id)
    u_draw_texture := gl.GetUniformLocation(game_shaders.simple_rectangle_2d.shader_id, "draw_texture")
    gl.BindTexture(gl.TEXTURE_2D, font_data.texture_atlas_id)
    gl.Uniform1i(u_draw_texture, 1)
    gl.DrawArrays(gl.TRIANGLES, 0, 6)
}
