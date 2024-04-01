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

get_px__width_to_ndc :: proc(px_x: f32) -> f32 {
        ndc_x := (px_x / game_window.size_px.x) * 2
        return ndc_x
}

get_px__height_to_ndc :: proc(px_y: f32) -> f32 {
        ndc_y := (px_y / game_window.size_px.y) * 2
        return ndc_y
}

draw_character :: proc(cursor_ndc: Vec2, color: Color3, font_data: ^TTF_Font, char: rune) {
        bitmap_info := get_char_codepoint_bitmap_data(font_data, char)
        width_ndc := get_px__width_to_ndc(f32(bitmap_info.width))
        height_ndc := get_px__height_to_ndc(f32(bitmap_info.height))
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
        gl.BufferData(gl.ARRAY_BUFFER, len(font_vertices) * size_of(f32), raw_data(font_vertices[:]), gl.DYNAMIC_DRAW)

        gl.UseProgram(game_shaders.ui_text.shader_id)
        gl.BindTexture(gl.TEXTURE_2D, font_data.texture_atlas_id)
        gl.DrawArrays(gl.TRIANGLES, 0, 6)
}
