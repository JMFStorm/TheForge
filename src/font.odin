package main

import gl "vendor:OpenGL"
import stbtt "vendor:stb/truetype"

import "core:c"
import "core:os"
import "core:fmt"
import "core:mem"
import "core:mem/virtual"
import "core:strings"

GameFonts :: struct {
        debug_font: TTF_Font
}

TTF_Font :: struct {
	font_scaling: f32,
	font_size_px: f32,
	texture_atlas_id: u32,
	texture_atlas_size: Vec2,
	codepoints: [96]CodepointBitmapInfo,
}

CodepointBitmapInfo :: struct {
	char: rune,
	width: i32,
	height: i32,
	xoff: i32,
	yoff: i32,
	glyph_uv_bot_left: Vec2,
	glyph_uv_top_right: Vec2,
}

load_all_fonts :: proc() -> GameFonts {
	buffer := make([]u8, mem.Megabyte * 20)
	defer delete(buffer)
	mem_arena := init_arena_buffer(buffer[:])
        game_fonts : GameFonts
	font_path_1 := strings.concatenate({get_fonts_directory(), "\\FragmentMono-Regular.ttf"}, context.temp_allocator)
	game_fonts.debug_font = load_ttf_font(font_path_1, FONT_BITMAP_SIZE_DEFAULT, &mem_arena)
        log_info("(Re)loaded all fonts.")
        return game_fonts
}

get_char_codepoint_bitmap_data :: proc(font: ^TTF_Font, char: rune) -> ^CodepointBitmapInfo {
	as_int := int(char)
	bitmap_data := &font.codepoints[as_int - 32]
	return bitmap_data
}

get_font_text_width_px :: proc(font_data: ^TTF_Font, text: string, font_size_px: f32) -> int {
        font_scale := font_size_px / font_data.font_size_px
        width_px : f32 = 0
        text_len := len(text)
        for c, i in text {
                data := get_char_codepoint_bitmap_data(font_data, c)
                advance := f32(data.width + data.xoff)
                width_px += advance * font_scale
        }
        return int(width_px)
}

get_font_atlas_size :: proc(font_data: ^TTF_Font, stb_font_info: ^stbtt.fontinfo) {
        current_x : i32 = 0
        {      
                char := cast(rune)(32)  // spacebar
                width := i32(font_data.font_size_px) / 4
                height := i32(font_data.font_size_px)
                current := CodepointBitmapInfo{char, width, height, 0, 0, {}, {}}
                font_data.codepoints[0] = current
                current_x += width + FONT_ATLAS_PADDING_PX
        }
        for i := 1; i < 96; i += 1 {
                char := cast(rune)(i + 32)
                xoff, yoff, ix1, iy1: c.int
                stbtt.GetCodepointBitmapBox(stb_font_info, char, font_data.font_scaling, font_data.font_scaling, &xoff, &yoff, &ix1, &iy1)
                width := ix1 - xoff
                height := iy1 - yoff
                current := CodepointBitmapInfo{char, width, height, xoff, yoff, {}, {}}
                font_data.codepoints[i] = current
                current_x += width + FONT_ATLAS_PADDING_PX
        }
        font_data.texture_atlas_size.x = f32(current_x)
        font_data.texture_atlas_size.y = font_data.font_size_px
}

load_ttf_font :: proc(filepath: string, font_height_px: f32, mem_arena: ^virtual.Arena) -> TTF_Font {
        file_buffer := read_file_to_buffer(filepath, mem_arena)
        font_data: TTF_Font
        font_data.font_size_px = font_height_px
        stb_font_info: stbtt.fontinfo
        success := stbtt.InitFont(&stb_font_info, raw_data(file_buffer[:]), 0)
        if !success {
                log_and_panic("ERROR: InitFont()")
        }
        font_scaling := stbtt.ScaleForPixelHeight(&stb_font_info, font_height_px)
        font_data.font_scaling = font_scaling
        get_font_atlas_size(&font_data, &stb_font_info) 
        build_font_atlas_bitmap(&font_data, &stb_font_info)
        log_debug(fmt.tprint("Loaded font", filepath, "with font size", font_height_px))
        return font_data
}

build_font_atlas_bitmap :: proc(font_data: ^TTF_Font, stb_font_info: ^stbtt.fontinfo) {
        current_x : i32 = 0
        bitmap_width := i32(font_data.texture_atlas_size.x)
        bitmap_height := i32(font_data.texture_atlas_size.y)
        atlas_bitmap := make([]u8, bitmap_width * bitmap_height)
        defer delete(atlas_bitmap)
        {       // spacebar
                width := font_data.codepoints[0].width
                for i : i32 = 0; i < (i32(font_data.font_size_px) - 1); i += 1 {
                        dest_offset := (i * bitmap_width) + current_x
                        dest := &atlas_bitmap[dest_offset]
                        mem.set(dest, 0x00, int(width))
                }
                uv_botleft_x : f32 = f32(current_x) / f32(bitmap_width)
                uv_topright_x : f32 = f32(current_x) + (font_data.font_size_px / 4) / f32(bitmap_width)
                uv_topright_y : f32 = font_data.font_size_px
                current := &font_data.codepoints[0]
                current.glyph_uv_bot_left = {uv_botleft_x, 0.0}
                current.glyph_uv_top_right = {uv_topright_x, uv_topright_y}
                current_x += i32(width) + FONT_ATLAS_PADDING_PX
        }
        for i := 1; i < 96; i += 1 {
                char := cast(rune)(i + 32)
                width, height, xoff, yoff: c.int
                bitmap := stbtt.GetCodepointBitmap(stb_font_info, 0, font_data.font_scaling, char, &width, &height, &xoff, &yoff)
                atlas_offset := bitmap_height - height
                y_offset := height + yoff
                dest_offset_start := i32(bitmap_width * (bitmap_height - 1 - atlas_offset)) + current_x
                max_height := i32(font_data.font_size_px) if i32(font_data.font_size_px) <= (height - 1) else height
                for i : i32 = 0; i < max_height; i += 1 {
                        src_offset := (width * (height - i - 1))
                        source := &bitmap[src_offset]
                        dest_offset := (i * bitmap_width) + current_x
                        dest := &atlas_bitmap[dest_offset]
                        mem.zero(dest, int(width))
                        mem.copy(dest, source, int(width))
                }
                uv_botleft_x : f32 = f32(current_x) / f32(bitmap_width)
                uv_topright_x : f32 = f32(current_x + width) / f32(bitmap_width)
                uv_topright_y : f32 = f32(height) / f32(bitmap_height)

                current := &font_data.codepoints[i]
                current.glyph_uv_bot_left = {uv_botleft_x, 0.0}
                current.glyph_uv_top_right = {uv_topright_x, uv_topright_y}
                stbtt.FreeBitmap(bitmap, nil)
                current_x += width + FONT_ATLAS_PADDING_PX
        }
        create_font_atlas_texture(font_data, atlas_bitmap)
}
