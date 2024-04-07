package main

import "core:fmt"
import "core:mem/virtual"
import "core:strings"
import gl "vendor:OpenGL"

init_ui_text_shader :: proc(mem_arena: ^virtual.Arena) -> SimpleShader {
        vs_path := strings.concatenate({get_shaders_directory(), "\\ui_text_vs.txt"}, context.temp_allocator)
        fs_path := strings.concatenate({get_shaders_directory(), "\\ui_text_fs.txt"}, context.temp_allocator)
        shader := create_simple_shader(vs_path, fs_path, mem_arena)

        gl.BindVertexArray(shader.vao)
        gl.BindBuffer(gl.ARRAY_BUFFER, shader.vbo)
        ui_text_vertex_buffer_size := RECTANGLE_2D_VERTICIES * size_of(f32) * MAX_BUFFERED_UI_CHARACTERS
        gl.BufferData(gl.ARRAY_BUFFER, ui_text_vertex_buffer_size, nil, gl.DYNAMIC_DRAW)
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
        log_info("Loaded ui text shader.")
        return shader
}

get_px_width_to_ndc :: proc(px_x: f32) -> f32 {
        ndc_x := (px_x / game_window.size_px.x) * 2
        return ndc_x
}

get_px_height_to_ndc :: proc(px_y: f32) -> f32 {
        ndc_y := (px_y / game_window.size_px.y) * 2
        return ndc_y
}

draw_character :: proc(cursor_ndc: Vec2, color: Color3, font_data: ^TTF_Font, char: rune) {
        bitmap_info := get_char_codepoint_bitmap_data(font_data, char)
        width_ndc := get_px_width_to_ndc(f32(bitmap_info.width))
        height_ndc := get_px_height_to_ndc(f32(bitmap_info.height))
        ndc_top_right := cursor_ndc + {width_ndc, height_ndc}
        font_vertices := []f32 {
    	        // Coords 	                        // Color                    // UV
                cursor_ndc.x,    ndc_top_right.y, 1.0,  color.r, color.g, color.b,  bitmap_info.glyph_uv_bot_left.x,  bitmap_info.glyph_uv_top_right.y, // topleft
                ndc_top_right.x, ndc_top_right.y, 1.0,  color.r, color.g, color.b,  bitmap_info.glyph_uv_top_right.x, bitmap_info.glyph_uv_top_right.y, // topright
                cursor_ndc.x,    cursor_ndc.y,    1.0,  color.r, color.g, color.b,  bitmap_info.glyph_uv_bot_left.x,  bitmap_info.glyph_uv_bot_left.y,  // botleft 

                cursor_ndc.x,    cursor_ndc.y,    1.0,  color.r, color.g, color.b,  bitmap_info.glyph_uv_bot_left.x,  bitmap_info.glyph_uv_bot_left.y,  // botleft 
                ndc_top_right.x, cursor_ndc.y,    1.0,  color.r, color.g, color.b,  bitmap_info.glyph_uv_top_right.x, bitmap_info.glyph_uv_bot_left.y,  // botright
                ndc_top_right.x, ndc_top_right.y, 1.0,  color.r, color.g, color.b,  bitmap_info.glyph_uv_top_right.x, bitmap_info.glyph_uv_top_right.y, // topright
        }
        gl.BindVertexArray(game_shaders.ui_text.vao)
        gl.BindBuffer(gl.ARRAY_BUFFER, game_shaders.ui_text.vbo)
        gl.BufferSubData(gl.ARRAY_BUFFER, 0, len(font_vertices) * size_of(f32), raw_data(font_vertices[:]))

        gl.UseProgram(game_shaders.ui_text.shader_id)
        gl.BindTexture(gl.TEXTURE_2D, font_data.texture_atlas_id)
        gl.DrawArrays(gl.TRIANGLES, 0, 6)

        gl.BindBuffer(gl.ARRAY_BUFFER, 0)
        gl.BindVertexArray(0)
}

build_char_vertex_data :: proc(char: rune, cursor_ndc: ^Vec2, color: Color3, font_data: ^TTF_Font, font_scaling: f32) -> []f32 {
        bitmap_info := get_char_codepoint_bitmap_data(font_data, char)
        width_ndc := get_px_width_to_ndc(f32(bitmap_info.width) * font_scaling)
        height_ndc := get_px_height_to_ndc(f32(bitmap_info.height) * font_scaling)
        xoff_ndc := get_px_width_to_ndc(f32(bitmap_info.xoff) * font_scaling)
        yoff_ndc := get_px_height_to_ndc(f32(bitmap_info.height + bitmap_info.yoff) * font_scaling)
        x0 : f32 = cursor_ndc.x + xoff_ndc
        x1 : f32 = x0 + width_ndc
        y0 : f32 = cursor_ndc.y - yoff_ndc
        y1 : f32 = y0 + height_ndc
        font_vertices := []f32 {
                // Coords       // Color                        // UV
                x0, y1, 1.0,    color.r, color.g, color.b,      bitmap_info.glyph_uv_bot_left.x,  bitmap_info.glyph_uv_top_right.y, // topleft
                x1, y1, 1.0,    color.r, color.g, color.b,      bitmap_info.glyph_uv_top_right.x, bitmap_info.glyph_uv_top_right.y, // topright
                x0, y0, 1.0,    color.r, color.g, color.b,      bitmap_info.glyph_uv_bot_left.x,  bitmap_info.glyph_uv_bot_left.y,  // botleft 

                x0, y0, 1.0,    color.r, color.g, color.b,      bitmap_info.glyph_uv_bot_left.x,  bitmap_info.glyph_uv_bot_left.y,  // botleft 
                x1, y0, 1.0,    color.r, color.g, color.b,      bitmap_info.glyph_uv_top_right.x, bitmap_info.glyph_uv_bot_left.y,  // botright
                x1, y1, 1.0,    color.r, color.g, color.b,      bitmap_info.glyph_uv_top_right.x, bitmap_info.glyph_uv_top_right.y, // topright
        }
        cursor_ndc.x += width_ndc + xoff_ndc
        return font_vertices
}

draw_text :: proc(cursor_ndc: Vec2, color: Color3, font_data: ^TTF_Font, text: string, font_size_px: f32, end_in_newline:= false) -> (cursor_next: Vec2) {
        gl.BindBuffer(gl.ARRAY_BUFFER, game_shaders.ui_text.vbo)
        current_cursor := cursor_ndc
        font_scaling := font_size_px / font_data.font_size_px
        for char, i in text {
                font_vertices := build_char_vertex_data(char, &current_cursor, color, font_data, font_scaling) 
                bytes := len(font_vertices) * size_of(f32)
                offset := i * bytes
                gl.BufferSubData(gl.ARRAY_BUFFER, offset, bytes, raw_data(font_vertices[:]))
        }
        gl.BindVertexArray(game_shaders.ui_text.vao)
        gl.UseProgram(game_shaders.ui_text.shader_id)
        gl.BindTexture(gl.TEXTURE_2D, font_data.texture_atlas_id)
        verticies := i32(len(text)) * 6
        gl.DrawArrays(gl.TRIANGLES, 0, verticies)
        gl.BindBuffer(gl.ARRAY_BUFFER, 0)
        gl.BindVertexArray(0)
        if end_in_newline {
                current_cursor.x = cursor_ndc.x
                current_cursor.y = current_cursor.y - get_px_height_to_ndc(font_data.font_size_px)
        }
        return current_cursor
}

create_font_atlas_texture :: proc(font_data: ^TTF_Font, atlas_bitmap: []byte) {
        gl.PixelStorei(gl.UNPACK_ALIGNMENT, 1)
        gl.GenTextures(1, &font_data.texture_atlas_id)
        gl.BindTexture(gl.TEXTURE_2D, font_data.texture_atlas_id)
        gl.TexImage2D(gl.TEXTURE_2D, 0, gl.RED, i32(font_data.texture_atlas_size.x), i32(font_data.texture_atlas_size.y), 0, gl.RED, gl.UNSIGNED_BYTE, raw_data(atlas_bitmap[:]))
        gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE)
        gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE)
        gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR)
        gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR)
        gl.PixelStorei(gl.UNPACK_ALIGNMENT, 4)
}
