package main

import "core:mem"
import "core:log"
import glfw "vendor:glfw"

str_perma_allocator : mem.Allocator
str_perma_arena : StringBuffer

console_str_buffer : StringBuffer

mem_tracker : mem.Tracking_Allocator
game_window : GameWindow
game_monitor : GameMonitor
game_file_info : GameFileInfo

game_logic_state : GameLogicState
menu_text_size : f32
menu_title_text_size : f32
game_controls: GameControls
game_shaders : GameShaders
game_textures : map[string]TextureData

game_fonts : GameFonts
main_cursor : glfw.CursorHandle

console_logger_data : ^log.File_Console_Logger_Data
file_logger_data : ^log.File_Console_Logger_Data

game_user_settings : GameUserSettings
