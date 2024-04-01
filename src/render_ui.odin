package main

import "core:fmt"
import "core:os"
import "core:mem"
import "core:path/filepath"
import "core:mem/virtual"
import gl "vendor:OpenGL"

init_simple_rectangle_2d_shader :: proc(mem_arena: ^virtual.Arena) -> SimpleShader {
        vs_path := "G:\\projects\\game\\TheForge\\resources\\shaders\\simple_rectangle_2d_vs.txt"
        fs_path := "G:\\projects\\game\\TheForge\\resources\\shaders\\simple_rectangle_2d_fs.txt"
        shader := create_simple_shader(vs_path, fs_path, mem_arena)

        gl.BindVertexArray(shader.vao)
        gl.BindBuffer(gl.ARRAY_BUFFER, shader.vbo)
    
        rect_vertex_buffer_size := RECTANGLE_2D_VERTICIES * size_of(f32) * MAX_BUFFERED_IMUI_RECTANGLES_2D
        gl.BufferData(gl.ARRAY_BUFFER, rect_vertex_buffer_size, nil, gl.DYNAMIC_DRAW)

        gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 8 * size_of(f32), 0)
        gl.EnableVertexAttribArray(0)

        gl.VertexAttribPointer(1, 3, gl.FLOAT, gl.FALSE, 8 * size_of(f32), 3 * size_of(f32))
        gl.EnableVertexAttribArray(1)

        gl.VertexAttribPointer(2, 2, gl.FLOAT, gl.FALSE, 8 * size_of(f32), 6 * size_of(f32))
        gl.EnableVertexAttribArray(2)

        gl.BindBuffer(gl.ARRAY_BUFFER, 0)
        gl.BindVertexArray(0)

        fmt.println("Loaded rectangle 2d shader.")
        return shader
}

init_line_2d_shader :: proc(mem_arena: ^virtual.Arena) -> SimpleShader {
        vs_path := "G:\\projects\\game\\TheForge\\resources\\shaders\\simple_rectangle_2d_vs.txt"
        fs_path := "G:\\projects\\game\\TheForge\\resources\\shaders\\simple_rectangle_2d_fs.txt"
        shader := create_simple_shader(vs_path, fs_path, mem_arena)

        gl.BindVertexArray(shader.vao)
        gl.BindBuffer(gl.ARRAY_BUFFER, shader.vbo)

        SINGLE_LINE :: 2 * 6
        rect_vertex_buffer_size := MAX_BUFFERED_LINES_2D * SINGLE_LINE * size_of(f32)
        gl.BufferData(gl.ARRAY_BUFFER, rect_vertex_buffer_size, nil, gl.DYNAMIC_DRAW)

        gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 6 * size_of(f32), 0)
        gl.EnableVertexAttribArray(0)

        gl.VertexAttribPointer(1, 3, gl.FLOAT, gl.FALSE, 6 * size_of(f32), 3 * size_of(f32))
        gl.EnableVertexAttribArray(1)

        gl.BindBuffer(gl.ARRAY_BUFFER, 0)
        gl.BindVertexArray(0)

        fmt.println("Loaded line 2d shader.")
        return shader
}

draw_rect_2d :: proc(rect_coords: Rect2D_NDC, color: Color3, texture_id: u32 = 0) {
        gl.BindVertexArray(game_shaders.simple_rectangle_2d.vao)
        rect_vertices := []f32 {
    	        // Coords                                               // Color                          // UV
                rect_coords.bot_left.x,  rect_coords.top_right.y,       1.0, color.r, color.g, color.b,   0.0, 1.0, // topleft
                rect_coords.top_right.x, rect_coords.top_right.y,       1.0, color.r, color.g, color.b,   1.0, 1.0, // topright
                rect_coords.bot_left.x,  rect_coords.bot_left.y,        1.0, color.r, color.g, color.b,   0.0, 0.0, // botleft 

                rect_coords.bot_left.x,  rect_coords.bot_left.y,        1.0, color.r, color.g, color.b,   0.0, 0.0, // botleft 
                rect_coords.top_right.x, rect_coords.bot_left.y,        1.0, color.r, color.g, color.b,   1.0, 0.0, // botright
                rect_coords.top_right.x, rect_coords.top_right.y,       1.0, color.r, color.g, color.b,   1.0, 1.0, // topright
        }
        gl.BindBuffer(gl.ARRAY_BUFFER, game_shaders.simple_rectangle_2d.vbo)
        gl.BufferData(gl.ARRAY_BUFFER, len(rect_vertices) * size_of(f32), raw_data(rect_vertices[:]), gl.DYNAMIC_DRAW)

        gl.UseProgram(game_shaders.simple_rectangle_2d.shader_id)
        u_draw_texture := gl.GetUniformLocation(game_shaders.simple_rectangle_2d.shader_id, "draw_texture")
        if texture_id != 0 {
                gl.BindTexture(gl.TEXTURE_2D, texture_id)
                gl.Uniform1i(u_draw_texture, 1)
        }
        else {
                gl.Uniform1i(u_draw_texture, 0)
        }
        gl.DrawArrays(gl.TRIANGLES, 0, 6)
}

draw_rect_2d_lined :: proc(rect_coords: Rect2D_NDC, color: Color3, width: f32) {
        gl.BindVertexArray(game_shaders.line_2d.vao)
        rect_vertices := []f32 {
                // Coords                                           // Color
                rect_coords.bot_left.x,  rect_coords.top_right.y,   1.0, color.r, color.g, color.b, // topleft
                rect_coords.top_right.x, rect_coords.top_right.y,   1.0, color.r, color.g, color.b, // topright
                rect_coords.top_right.x, rect_coords.bot_left.y,    1.0, color.r, color.g, color.b, // botright
                rect_coords.bot_left.x,  rect_coords.bot_left.y,    1.0, color.r, color.g, color.b, // botleft 
                rect_coords.bot_left.x,  rect_coords.top_right.y,   1.0, color.r, color.g, color.b, // topleft
        }
        gl.BindBuffer(gl.ARRAY_BUFFER, game_shaders.line_2d.vbo)
        gl.BufferData(gl.ARRAY_BUFFER, len(rect_vertices) * size_of(f32), raw_data(rect_vertices[:]), gl.DYNAMIC_DRAW)

        gl.UseProgram(game_shaders.line_2d.shader_id)
        gl.LineWidth(width)
        gl.DrawArrays(gl.LINE_STRIP, 0, 5)
}

draw_line_2d :: proc(line_2d_ndc: Line2D_NDC, color: Color3, width: f32) {
        gl.BindVertexArray(game_shaders.line_2d.vao)
        line_vertices := []f32 {
                // Coords                                      // Color
                line_2d_ndc.start.x, line_2d_ndc.start.y, 1.0, color.r, color.g, color.b, // start
                line_2d_ndc.end.x,   line_2d_ndc.end.y,   1.0, color.r, color.g, color.b, // end
        }
        gl.BindBuffer(gl.ARRAY_BUFFER, game_shaders.line_2d.vbo)
        gl.BufferData(gl.ARRAY_BUFFER, len(line_vertices) * size_of(f32), raw_data(line_vertices[:]), gl.DYNAMIC_DRAW)

        gl.UseProgram(game_shaders.line_2d.shader_id)
        gl.LineWidth(width)
        gl.DrawArrays(gl.LINES, 0, 2)
}
