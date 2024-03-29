package main

import "core:fmt"
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

init_simple_rectangle_2d_shader :: proc() -> SimpleRectangle2DShader {
    vss : cstring = "#version 330 core\nlayout (location = 0) in vec3 aPos;\nout vec4 color;\nlayout (location = 1) in vec3 aColor;\nvoid main()\n{\ngl_Position = vec4(aPos.x, aPos.y, aPos.z, 1.0);\ncolor = vec4(aColor.x, aColor.y, aColor.z, 1.0);\n}"
    vs := gl.CreateShader(gl.VERTEX_SHADER)
    gl.ShaderSource(vs, 1, &vss, nil)
    gl.CompileShader(vs)
    check_compilation_success(vs)

    fss : cstring = "#version 330 core\nin vec4 color;\nout vec4 FragColor;\nvoid main()\n{\nFragColor = vec4(color.r, color.g, color.b, 1.0f);\n}"
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

    rect_vertex_buffer_size := 6 * 6 * size_of(f32)
    gl.BufferData(gl.ARRAY_BUFFER, rect_vertex_buffer_size, nil, gl.DYNAMIC_DRAW)

    gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 6 * size_of(f32), 0)
    gl.EnableVertexAttribArray(0)

    gl.VertexAttribPointer(1, 3, gl.FLOAT, gl.FALSE, 6 * size_of(f32), 3 * size_of(f32))
    gl.EnableVertexAttribArray(1)

    gl.BindBuffer(gl.ARRAY_BUFFER, 0)
    gl.BindVertexArray(0)

    return SimpleRectangle2DShader{vao, vbo, shader_id}
}

draw_rect_2d :: proc(rect_coords: Rect2D_NDC, color: Color3) {
    gl.BindVertexArray(game_shaders.simple_rectangle_2d.vao);

    rect_vertices := []f32 {
    	// Coords 										  	   // Color
        rect_coords.bot_left.x,  rect_coords.top_right.y, 1.0, color.r, color.g, color.b, // topleft
        rect_coords.top_right.x, rect_coords.top_right.y, 1.0, color.r, color.g, color.b, // topright
        rect_coords.bot_left.x,  rect_coords.bot_left.y,  1.0, color.r, color.g, color.b, // botleft 

        rect_coords.bot_left.x,  rect_coords.bot_left.y,  1.0, color.r, color.g, color.b, // botleft 
        rect_coords.top_right.x, rect_coords.bot_left.y,  1.0, color.r, color.g, color.b, // botright
        rect_coords.top_right.x, rect_coords.top_right.y, 1.0, color.r, color.g, color.b, // topright
    }
    gl.BindBuffer(gl.ARRAY_BUFFER, game_shaders.simple_rectangle_2d.vbo)
    gl.BufferData(gl.ARRAY_BUFFER, len(rect_vertices) * size_of(f32), raw_data(rect_vertices[:]), gl.DYNAMIC_DRAW)

    gl.UseProgram(game_shaders.simple_rectangle_2d.shader_id);
    gl.DrawArrays(gl.TRIANGLES, 0, 6);
}

load_all_shaders :: proc() -> GameShaders {
	shaders := GameShaders{}
	shaders.simple_rectangle_2d = init_simple_rectangle_2d_shader()
	return shaders
}