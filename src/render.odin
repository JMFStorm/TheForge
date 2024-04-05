package main

import "core:fmt"
import "core:os"
import "core:mem"
import "core:path/filepath"
import "core:mem/virtual"
import gl "vendor:OpenGL"

SimpleShader :: struct {
	vbo: u32,
	vao: u32,
	shader_id: u32,
}

GameShaders :: struct {
	simple_rectangle_2d: SimpleShader,
	line_2d: SimpleShader,
	ui_text: SimpleShader,
}

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
                str := fmt.tprint("Shader compilation failed", string(infoLog[:]))
                log_and_panic(str)
        }
}

create_simple_shader :: proc(vs_path, fs_path: string, mem_arena: ^virtual.Arena) -> SimpleShader {
        vss, vss_bytes_read := read_file_to_cstring(vs_path, mem_arena)
        vs := gl.CreateShader(gl.VERTEX_SHADER)
        gl.ShaderSource(vs, 1, &vss, nil)
        gl.CompileShader(vs)
        check_compilation_success(vs)

        fss, fss_bytes_read := read_file_to_cstring(fs_path, mem_arena)
        fs := gl.CreateShader(gl.FRAGMENT_SHADER)
        gl.ShaderSource(fs, 1, &fss, nil)
        gl.CompileShader(fs)
        check_compilation_success(fs)

        shader_id := create_shader_program(vs, fs)
        vao, vbo : u32
        gl.GenVertexArrays(1, &vao)
        gl.GenBuffers(1, &vbo)
        return {vbo, vao, shader_id}
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
        shaders.ui_text = init_ui_text_shader(&mem_arena)

	return shaders
}

create_texture :: proc(data: ImageData) -> TextureData {
        texture_id : u32
        gl.GenTextures(1, &texture_id)
        gl.BindTexture(gl.TEXTURE_2D, texture_id);
        gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.REPEAT)
        gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.REPEAT)
        gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR_MIPMAP_LINEAR)
        gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR)
        hasAlpha := true if data.channels == 3 else false
        format : i32 =  gl.RGB if hasAlpha else gl.RGBA
        gl.TexImage2D(gl.TEXTURE_2D, 0, format, data.width_px, data.height_px, 0, u32(format), gl.UNSIGNED_BYTE, data.data)
        gl.GenerateMipmap(gl.TEXTURE_2D)
        texture_name := filepath.short_stem(data.filename)
        return {str_perma_copy(texture_name), texture_id, data.width_px, data.height_px, hasAlpha}
}
