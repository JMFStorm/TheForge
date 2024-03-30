package main

import "core:fmt"
import "core:os"
import "core:mem"
import "core:path/filepath"
import "core:mem/virtual"
import gl "vendor:OpenGL"

create_shader_program :: proc(vs, fs: u32) -> u32 {
    shader_id := gl.CreateProgram()
    gl.AttachShader(shader_id, vs);
    gl.AttachShader(shader_id, fs);
    gl.LinkProgram(shader_id);

    gl.DeleteShader(vs);
    gl.DeleteShader(fs);
    return shader_id
}

check_compilation_success :: proc(shader: u32) {
    success: i32
    infoLog : [512]u8
    gl.GetShaderiv(shader, gl.COMPILE_STATUS, &success);
    if bool(success) == gl.FALSE {
        gl.GetShaderInfoLog(shader, 512, nil, raw_data(&infoLog))
        fmt.println("ERROR::SHADER::COMPILATION_FAILED", string(infoLog[:]))
    }
}

init_simple_rectangle_2d_shader :: proc(mem_arena: ^virtual.Arena) -> SimpleShader {
    vs_path := "G:\\projects\\game\\TheForge\\resources\\shaders\\vs_simple_rectangle_2d.txt"
    vss, vss_bytes_read := read_file_to_cstring(vs_path, mem_arena)
    vs := gl.CreateShader(gl.VERTEX_SHADER)
    gl.ShaderSource(vs, 1, &vss, nil)
    gl.CompileShader(vs)
    check_compilation_success(vs)

    fs_path := "G:\\projects\\game\\TheForge\\resources\\shaders\\fs_simple_rectangle_2d.txt"
    fss, fss_bytes_read := read_file_to_cstring(fs_path, mem_arena)
    fs := gl.CreateShader(gl.FRAGMENT_SHADER)
    gl.ShaderSource(fs, 1, &fss, nil)
    gl.CompileShader(fs)
    check_compilation_success(fs)

    shader_id := create_shader_program(vs, fs)
    vao, vbo : u32
    gl.GenVertexArrays(1, &vao)
    gl.GenBuffers(1, &vbo)
    gl.BindVertexArray(vao)
    gl.BindBuffer(gl.ARRAY_BUFFER, vbo)
    
    RECTANGLE_2D_VERTICIES :: 6 * 6
    rect_vertex_buffer_size := RECTANGLE_2D_VERTICIES * size_of(f32) * MAX_BUFFERED_RECTANGLES_2D
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
    return SimpleShader{vao, vbo, shader_id}
}

init_line_2d_shader :: proc(mem_arena: ^virtual.Arena) -> SimpleShader {
    vs_path := "G:\\projects\\game\\TheForge\\resources\\shaders\\vs_simple_rectangle_2d.txt"
    vss, vss_bytes_read := read_file_to_cstring(vs_path, mem_arena)
    vs := gl.CreateShader(gl.VERTEX_SHADER)
    gl.ShaderSource(vs, 1, &vss, nil)
    gl.CompileShader(vs)
    check_compilation_success(vs)

    fs_path := "G:\\projects\\game\\TheForge\\resources\\shaders\\fs_simple_rectangle_2d.txt"
    fss, fss_bytes_read := read_file_to_cstring(fs_path, mem_arena)
    fs := gl.CreateShader(gl.FRAGMENT_SHADER)
    gl.ShaderSource(fs, 1, &fss, nil)
    gl.CompileShader(fs)
    check_compilation_success(fs)

    shader_id := create_shader_program(vs, fs)

    vao, vbo : u32
    gl.GenVertexArrays(1, &vao)
    gl.GenBuffers(1, &vbo)
    gl.BindVertexArray(vao)
    gl.BindBuffer(gl.ARRAY_BUFFER, vbo)

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
    return SimpleShader{vao, vbo, shader_id}
}

draw_rect_2d_filled :: proc(rect_coords: Rect2D_NDC, color: Color3, texture_id: u32 = 0) {
    gl.BindVertexArray(game_shaders.simple_rectangle_2d.vao)

    rect_vertices := []f32 {
    	// Coords 								            // Color                          // UV
        rect_coords.bot_left.x,  rect_coords.top_right.y,   1.0, color.r, color.g, color.b,   0.0, 1.0, // topleft
        rect_coords.top_right.x, rect_coords.top_right.y,   1.0, color.r, color.g, color.b,   1.0, 1.0, // topright
        rect_coords.bot_left.x,  rect_coords.bot_left.y,    1.0, color.r, color.g, color.b,   0.0, 0.0, // botleft 

        rect_coords.bot_left.x,  rect_coords.bot_left.y,    1.0, color.r, color.g, color.b,   0.0, 0.0, // botleft 
        rect_coords.top_right.x, rect_coords.bot_left.y,    1.0, color.r, color.g, color.b,   1.0, 0.0, // botright
        rect_coords.top_right.x, rect_coords.top_right.y,   1.0, color.r, color.g, color.b,   1.0, 1.0, // topright
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

load_all_shaders :: proc() -> GameShaders {
    bytes : uint = 1024 * 16
    buffer := make([]u8, bytes)
    defer delete(buffer)
    mem_arena := init_arena_buffer(buffer)
    defer virtual.arena_destroy(&mem_arena)

	shaders := GameShaders{}
	shaders.simple_rectangle_2d = init_simple_rectangle_2d_shader(&mem_arena)
    shaders.line_2d = init_line_2d_shader(&mem_arena)
	return shaders
}

create_texture :: proc(data: ImageData) -> TextureData {
    texture : u32
    gl.GenTextures(1, &texture)
    gl.BindTexture(gl.TEXTURE_2D, texture);
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.REPEAT)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.REPEAT)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR_MIPMAP_LINEAR)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR)

    hasAlpha := true if data.channels == 3 else false
    format : i32 =  gl.RGB if hasAlpha else gl.RGBA
    gl.TexImage2D(gl.TEXTURE_2D, 0, format, data.width_px, data.height_px, 0, u32(format), gl.UNSIGNED_BYTE, data.data)
    gl.GenerateMipmap(gl.TEXTURE_2D)

    texture_name := filepath.short_stem(data.filename)
    return {texture_name, texture, data.width_px, data.height_px, hasAlpha}
}