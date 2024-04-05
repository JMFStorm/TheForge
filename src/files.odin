package main

import "core:c"
import "core:fmt"
import "core:mem"
import "core:mem/virtual"
import "core:path/filepath"
import "core:strings"
import "core:os"

import stbi "vendor:stb/image"

GameFileInfo :: struct {
        exe_fullpath: string,
        exe_dirpath: string,
        resources_dirpath: string,
}

get_parent_dir :: proc(path: string) -> (res: string) {
        i := len(path) - 1
	for 0 <= i {
                current := path[i]
                if current == '/' || current == '\\' { break }
                i -= 1
        }
	return path[:i]
}

set_game_file_info :: proc() {
        set_executable_fullpath(context.temp_allocator)
        set_executable_dirpath(context.temp_allocator)
        set_resources_dirpath(context.temp_allocator)
        free_all(context.temp_allocator)
}

set_executable_fullpath :: proc(temp_allocator := context.temp_allocator) {
        game_file_info.exe_fullpath = str_perma_copy(get_executable_fullpath(temp_allocator))
        log_info(fmt.tprint("Executable fullpath:", game_file_info.exe_fullpath))
}

set_executable_dirpath :: proc(temp_allocator := context.temp_allocator) {
        if len(game_file_info.exe_fullpath) <= 0 {
                log_and_panic("Could not get executable dirpath, fullpath missing.")
        }
        path_str := filepath.dir(game_file_info.exe_fullpath, temp_allocator)
        game_file_info.exe_dirpath = str_perma_copy(path_str)
        log_info(fmt.tprint("Executable dirpath:", game_file_info.exe_dirpath))
}

append_dirpath :: proc(basepath: string, appended: string, temp_allocator := context.temp_allocator) -> string {
        log_debug(basepath)
        concated, str_err := strings.concatenate({basepath, appended}, temp_allocator)
        if str_err != nil {
                log_and_panic("Could not concatenate dirpaths.")
        }
        return concated
}

set_resources_dirpath :: proc(temp_allocator := context.temp_allocator) {
        if len(game_file_info.exe_dirpath) <= 0 {
                log_and_panic("Could not get resources dirpath, executable dirpath missing.")
        }
        parent := get_parent_dir(game_file_info.exe_dirpath)
        resources_dirpath := append_dirpath(parent, "\\resources", temp_allocator)
        game_file_info.resources_dirpath = str_perma_copy(resources_dirpath)
        log_info(fmt.tprint("Resources dirpath:", game_file_info.resources_dirpath))
}

read_file_to_cstring :: proc(path: string, mem_arena: ^virtual.Arena) -> (cstring, int) {
    f_handle, error := os.open(path)
    if error != 0 {
        log_and_panic("Could not get file handle")
    }
    defer os.close(f_handle)

    RESERVE_STR_BYTES :: 1024
    virtual.arena_free_all(mem_arena)
    buffer, arena_error := virtual.arena_alloc(mem_arena, mem_arena.total_reserved, 8)
    if arena_error != nil {
        log_and_panic("Could not allocate memory arena")
    }
    mem.zero(raw_data(buffer), RESERVE_STR_BYTES)

    bytes_read, read_error := os.read(f_handle, buffer[:])
    if read_error != 0 {
        log_and_panic("Could not read file")
    }
    cstr := cstring(raw_data(buffer))
    return cstr, bytes_read
}

read_file_to_buffer :: proc(path: string, mem_arena: ^virtual.Arena) -> ^[]byte {
    f_handle, error := os.open(path)
    if error != 0 {
        log_and_panic("Could not get file handle")
    }
    defer os.close(f_handle)
    virtual.arena_free_all(mem_arena)
    buffer, arena_error := virtual.arena_alloc(mem_arena, mem_arena.total_reserved, 8)
    if arena_error != nil {
        log_and_panic("Could not allocate memory arena")
    }
    bytes_read, read_error := os.read(f_handle, buffer[:])
    if read_error != 0 {
        log_and_panic("Could not read file")
    }
    return &buffer
}

load_image_data :: proc(filename: string) -> ImageData {
    x, y, channels: c.int
    stbi.set_flip_vertically_on_load(1)
    filepath := strings.concatenate({game_file_info.resources_dirpath, "\\images\\", filename}, context.temp_allocator)
    image_data := stbi.load(strings.clone_to_cstring(filepath, context.temp_allocator), &x, &y, &channels, channels)
    log_debug(fmt.tprint("Loaded image data:", filepath, x, y, channels))
    return ImageData{filename, x, y, channels, image_data}
}

free_image_data :: proc(data: ^ImageData) {
    stbi.image_free(data.data)
}
