package main

import "core:fmt"
import gl "vendor:OpenGL"

imui_init :: proc() {
    init_ui_rect_2d_buffers()
    init_ui_line_2d_buffers()
}

init_ui_line_2d_buffers :: proc() {
    gl.GenVertexArrays(1, &imui_buffers.line_2d_vao)
    gl.GenBuffers(1, &imui_buffers.line_2d_vbo)
    gl.BindVertexArray(imui_buffers.line_2d_vao)
    gl.BindBuffer(gl.ARRAY_BUFFER, imui_buffers.line_2d_vbo)

    SINGLE_LINE :: 2 * 6
    vertex_buffer_size := MAX_BUFFERED_UI_LINES_2D * SINGLE_LINE * size_of(f32)
    gl.BufferData(gl.ARRAY_BUFFER, vertex_buffer_size, nil, gl.DYNAMIC_DRAW)
    // xyz
    gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 6 * size_of(f32), 0)
    gl.EnableVertexAttribArray(0)
    // rgb
    gl.VertexAttribPointer(1, 3, gl.FLOAT, gl.FALSE, 6 * size_of(f32), 3 * size_of(f32))
    gl.EnableVertexAttribArray(1)

    gl.BindBuffer(gl.ARRAY_BUFFER, 0)
    gl.BindVertexArray(0)
}

init_ui_rect_2d_buffers :: proc() {
    gl.GenVertexArrays(1, &imui_buffers.simple_rectangle_2d_vao)
    gl.GenBuffers(1, &imui_buffers.simple_rectangle_2d_vbo)
    gl.BindVertexArray(imui_buffers.simple_rectangle_2d_vao)
    gl.BindBuffer(gl.ARRAY_BUFFER, imui_buffers.simple_rectangle_2d_vbo)

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

buffer_ui_rect_2d :: proc(rect_coords: Rect2D_NDC, color: Color3) {
    rect_vertices := []f32 {
    	// Coords 								            // Color                          // UV
        rect_coords.bot_left.x,  rect_coords.top_right.y,   1.0, color.r, color.g, color.b,   0.0, 1.0, // topleft
        rect_coords.top_right.x, rect_coords.top_right.y,   1.0, color.r, color.g, color.b,   1.0, 1.0, // topright
        rect_coords.bot_left.x,  rect_coords.bot_left.y,    1.0, color.r, color.g, color.b,   0.0, 0.0, // botleft 

        rect_coords.bot_left.x,  rect_coords.bot_left.y,    1.0, color.r, color.g, color.b,   0.0, 0.0, // botleft 
        rect_coords.top_right.x, rect_coords.bot_left.y,    1.0, color.r, color.g, color.b,   1.0, 0.0, // botright
        rect_coords.top_right.x, rect_coords.top_right.y,   1.0, color.r, color.g, color.b,   1.0, 1.0, // topright
    }
    verticies_byte_size := len(rect_vertices) * size_of(f32)
    offset := imui_buffers.buffered_rects_2d * verticies_byte_size

    gl.BindBuffer(gl.ARRAY_BUFFER, imui_buffers.simple_rectangle_2d_vbo)
    gl.BufferSubData(gl.ARRAY_BUFFER, offset, verticies_byte_size, raw_data(rect_vertices[:]))
    imui_buffers.buffered_rects_2d += 1
}

imui_menu_button :: proc(dimensions: Rect2D_NDC) -> bool {
    dimensions_px := get_rect_ndc_to_px(dimensions)
    rect_2d_point_collide := rect_2d_point_collide(game_controls.mouse.window_pos, dimensions_px)

    on_hover := rect_2d_point_collide
    on_click := on_hover && game_controls.mouse.buttons[.m1].pressed

    buffer_ui_rect_2d(dimensions, {0.8, 0.8, 0.8})
    if on_hover {
        buffer_ui_rect_2d(dimensions, {1.0, 0.2, 0.2})
    }
    return on_click
}

draw_buffered_ui_rects_2d :: proc() {
    gl.BindVertexArray(imui_buffers.simple_rectangle_2d_vao)
    gl.BindBuffer(gl.ARRAY_BUFFER, imui_buffers.simple_rectangle_2d_vbo)
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

draw_buffered_ui_lined_rects_2d :: proc(line_width: f32) {

}

imui_render :: proc() {
    if 0 < imui_buffers.buffered_rects_2d {
        draw_buffered_ui_rects_2d()
    }
    if 0 < imui_buffers.buffered_lines_2d { 
        draw_buffered_ui_lined_rects_2d(4.0)
    }
}
