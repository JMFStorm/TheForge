package main

import "core:c"
import "core:fmt"
import "core:mem"
import "core:mem/virtual"
import "core:os"

import stbi "vendor:stb/image"

read_file_to_cstring :: proc(path: string, mem_arena: ^virtual.Arena) -> (cstring, int) {
    f_handle, error := os.open(path)
    if error != 0 {
        panic("ERROR: Get file handle")
    }
    defer os.close(f_handle)

    RESERVE_BYTES :: 1024
    // virtual.arena_static_reset_to(mem_arena, 0)
    virtual.arena_free_all(mem_arena)
    buffer, arena_error := virtual.arena_alloc(mem_arena, RESERVE_BYTES, 8)
    if arena_error != nil {
        panic("ERROR: Allocate memory arena")
    }
    mem.zero(raw_data(buffer), RESERVE_BYTES)

    bytes_read, read_error := os.read(f_handle, buffer[:])
    if read_error != 0 {
        panic("ERROR: Read file")
    }
    cstr := cstring(raw_data(buffer))
    return cstr, bytes_read
}

load_image_data :: proc(path: cstring) -> ImageData {
    x, y, channels: c.int
    stbi.set_flip_vertically_on_load(1)
    image_data := stbi.load(path, &x, &y, &channels, channels)
    fmt.println(path, x, y, channels)
    return ImageData{string(path), x, y, channels, image_data}
}

free_image_data :: proc(data: ^ImageData) {
    stbi.image_free(data.data)
}