package main

import "core:fmt"
import "core:mem/virtual"
import gl "vendor:OpenGL"

init_ui_text_shader :: proc(mem_arena: ^virtual.Arena) -> SimpleShader {
        vs_path := "G:\\projects\\game\\TheForge\\resources\\shaders\\ui_text_vs.txt"
        fs_path := "G:\\projects\\game\\TheForge\\resources\\shaders\\ui_text_fs.txt"
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
        fmt.println("Loaded ui text shader.")
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

draw_text :: proc(cursor_ndc: Vec2, color: Color3, font_data: ^TTF_Font, text: string, end_in_newline:= false) -> (cursor_next: Vec2) {
        gl.BindBuffer(gl.ARRAY_BUFFER, game_shaders.ui_text.vbo)
        current_cursor := cursor_ndc
        for char, i in text {
                bitmap_info := get_char_codepoint_bitmap_data(font_data, char)
                width_ndc := get_px_width_to_ndc(f32(bitmap_info.width))
                height_ndc := get_px_height_to_ndc(f32(bitmap_info.height))
                xoff_ndc := get_px_width_to_ndc(f32(bitmap_info.xoff))
                yoff_ndc := get_px_height_to_ndc(f32(bitmap_info.height + bitmap_info.yoff))
                x0 : f32 = current_cursor.x + xoff_ndc
                x1 : f32 = x0 + width_ndc
                y0 : f32 = current_cursor.y - yoff_ndc
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
                bytes := len(font_vertices) * size_of(f32)
                offset := i * bytes
                gl.BufferSubData(gl.ARRAY_BUFFER, offset, bytes, raw_data(font_vertices[:]))
                current_cursor.x += width_ndc + xoff_ndc
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
