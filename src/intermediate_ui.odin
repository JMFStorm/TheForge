package main

import "core:fmt"
import gl "vendor:OpenGL"

imui_init :: proc() {
        init_imui_rect_2d_buffers()
        init_imui_text_buffers()
}

init_imui_rect_2d_buffers :: proc() {
        gl.GenVertexArrays(1, &imui_buffers.ui_rects.vao)
        gl.GenBuffers(1, &imui_buffers.ui_rects.vbo)
        gl.BindVertexArray(imui_buffers.ui_rects.vao)
        gl.BindBuffer(gl.ARRAY_BUFFER, imui_buffers.ui_rects.vbo)
        rect_vertex_buffer_size := RECTANGLE_2D_VERTICIES * size_of(f32) * MAX_BUFFERED_IMUI_RECTANGLES_2D
        gl.BufferData(gl.ARRAY_BUFFER, rect_vertex_buffer_size, nil, gl.DYNAMIC_DRAW)
        // xyz
        gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 8 * size_of(f32), 0)
        gl.EnableVertexAttribArray(0)
        // rgb
        gl.VertexAttribPointer(1, 3, gl.FLOAT, gl.FALSE, 8 * size_of(f32), 3 * size_of(f32))
        gl.EnableVertexAttribArray(1)
        // uv
        gl.VertexAttribPointer(2, 2, gl.FLOAT, gl.FALSE, 8 * size_of(f32), 6 * size_of(f32))
        gl.EnableVertexAttribArray(2)   
        gl.BindBuffer(gl.ARRAY_BUFFER, 0)
        gl.BindVertexArray(0)
}

init_imui_text_buffers :: proc() {
        gl.GenVertexArrays(1, &imui_buffers.ui_text.vao)
        gl.GenBuffers(1, &imui_buffers.ui_text.vbo)
        gl.BindVertexArray(imui_buffers.ui_text.vao)
        gl.BindBuffer(gl.ARRAY_BUFFER, imui_buffers.ui_text.vbo)
        text_vertex_buffer_size := TEXT_CHAR_VERTICIES * size_of(f32) * MAX_BUFFERED_IMUI_CHARACTERS
        gl.BufferData(gl.ARRAY_BUFFER, text_vertex_buffer_size, nil, gl.DYNAMIC_DRAW)
        // xyz
        gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 8 * size_of(f32), 0)
        gl.EnableVertexAttribArray(0)
        // rgb
        gl.VertexAttribPointer(1, 3, gl.FLOAT, gl.FALSE, 8 * size_of(f32), 3 * size_of(f32))
        gl.EnableVertexAttribArray(1)
        // uv
        gl.VertexAttribPointer(2, 2, gl.FLOAT, gl.FALSE, 8 * size_of(f32), 6 * size_of(f32))
        gl.EnableVertexAttribArray(2)   
        gl.BindBuffer(gl.ARRAY_BUFFER, 0)
        gl.BindVertexArray(0)
}

buffer_imui_rect_2d :: proc(rect_coords: Rect2D_NDC, color: Color3) {
        rect_vertices := []f32 {
    	        // Coords 					        // Color                          // UV
                rect_coords.bot_left.x,  rect_coords.top_right.y,       1.0, color.r, color.g, color.b,   0.0, 1.0, // topleft
                rect_coords.top_right.x, rect_coords.top_right.y,       1.0, color.r, color.g, color.b,   1.0, 1.0, // topright
                rect_coords.bot_left.x,  rect_coords.bot_left.y,        1.0, color.r, color.g, color.b,   0.0, 0.0, // botleft 

                rect_coords.bot_left.x,  rect_coords.bot_left.y,        1.0, color.r, color.g, color.b,   0.0, 0.0, // botleft 
                rect_coords.top_right.x, rect_coords.bot_left.y,        1.0, color.r, color.g, color.b,   1.0, 0.0, // botright
                rect_coords.top_right.x, rect_coords.top_right.y,       1.0, color.r, color.g, color.b,   1.0, 1.0, // topright
        }
        verticies_byte_size := len(rect_vertices) * size_of(f32)
        offset := imui_buffers.buffered_rects_2d * verticies_byte_size
        gl.BindBuffer(gl.ARRAY_BUFFER, imui_buffers.ui_rects.vbo)
        gl.BufferSubData(gl.ARRAY_BUFFER, offset, verticies_byte_size, raw_data(rect_vertices[:]))
        imui_buffers.buffered_rects_2d += 1
}

imui_text :: proc(cursor_ndc: Vec2, color: Color3, font_data: ^TTF_Font, text: string, size_px: f32, end_in_newline := false) -> (cursor_next: Vec2) {
        gl.BindBuffer(gl.ARRAY_BUFFER, imui_buffers.ui_text.vbo)
        current_cursor := cursor_ndc
        font_scale := size_px / font_data.font_size_px
        for char, i in text {
                font_vertices : [48]f32
                build_char_vertex_data(char, &current_cursor, color, font_data, &font_vertices, font_scale)
                bytes := len(font_vertices) * size_of(f32)
                offset := imui_buffers.buffered_text * bytes
                gl.BufferSubData(gl.ARRAY_BUFFER, offset, bytes, raw_data(font_vertices[:]))
                imui_buffers.buffered_text += 1
        }
        if end_in_newline {
                current_cursor.x = cursor_ndc.x
                current_cursor.y = current_cursor.y - get_px_height_to_ndc(font_data.font_size_px)
        }
        gl.BindBuffer(gl.ARRAY_BUFFER, 0)
        return current_cursor
}

imui_menu_button :: proc(dimensions: Rect2D_NDC, text: string, font_size: f32) -> bool {
        dimensions_px := get_rect_ndc_to_px(dimensions)
        rect_2d_point_collide := rect_2d_point_collide(game_controls.mouse.window_pos, dimensions_px)
        on_hover := rect_2d_point_collide
        on_click := on_hover && game_controls.mouse.buttons[.m1].pressed
        buffer_imui_rect_2d(dimensions, {0.8, 0.8, 0.8})
        if on_hover {
                buffer_imui_rect_2d(dimensions, {1.0, 0.2, 0.2})
        }
        if 0 < len(text) {
                text_width := get_font_text_width_px(&game_fonts.debug_font, text, font_size)
                button_center := dimensions.bot_left + ((dimensions.top_right - dimensions.bot_left) / 2)
                text_x_offset :=  get_px_width_to_ndc(f32(text_width / 2))
                text_y_offset :=  get_px_height_to_ndc(font_size / 4)
                button_text_start := Vec2{button_center.x - text_x_offset, button_center.y - text_y_offset}
                imui_text(button_text_start, {0, 0, 0}, &game_fonts.debug_font, text, font_size)
        }
        return on_click
}

imui_menu_title :: proc(menu_name: string, font_size: f32) {
        text_width := get_font_text_width_px(&game_fonts.debug_font, menu_name, font_size)
        text_x_offset := get_px_width_to_ndc(f32(text_width / 2))
        text_pos := Vec2{0 - text_x_offset, get_px_height_to_ndc(vh(30))}
        imui_text(text_pos, {0.9, 0.9, 0.9}, &game_fonts.debug_font, menu_name, font_size)
}

draw_buffered_imui_rects_2d :: proc() {
        gl.BindVertexArray(imui_buffers.ui_rects.vao)
        gl.BindBuffer(gl.ARRAY_BUFFER, imui_buffers.ui_rects.vbo)
        gl.UseProgram(game_shaders.simple_rectangle_2d.shader_id)
        u_draw_texture := gl.GetUniformLocation(game_shaders.simple_rectangle_2d.shader_id, "draw_texture")
        gl.Uniform1i(u_draw_texture, 0)
        verticies := imui_buffers.buffered_rects_2d * 6
        gl.DrawArrays(gl.TRIANGLES, 0, i32(verticies))
        imui_buffers.buffered_rects_2d = 0      
        gl.UseProgram(0)
        gl.BindVertexArray(0)
        gl.BindBuffer(gl.ARRAY_BUFFER, 0)
}

draw_buffered_imui_text :: proc() {
        gl.BindVertexArray(imui_buffers.ui_text.vao)
        gl.BindBuffer(gl.ARRAY_BUFFER, imui_buffers.ui_text.vbo)
        gl.UseProgram(game_shaders.ui_text.shader_id)
        verticies := imui_buffers.buffered_text * 6
        gl.BindTexture(gl.TEXTURE_2D, game_fonts.debug_font.texture_atlas_id)
        gl.DrawArrays(gl.TRIANGLES, 0, i32(verticies))
        imui_buffers.buffered_text = 0      
        gl.UseProgram(0)
        gl.BindVertexArray(0)
        gl.BindBuffer(gl.ARRAY_BUFFER, 0)
}

imui_render :: proc() {
        if 0 < imui_buffers.buffered_rects_2d {
                draw_buffered_imui_rects_2d()
        }
        if 0 < imui_buffers.buffered_text {
                draw_buffered_imui_text()
        }
}
