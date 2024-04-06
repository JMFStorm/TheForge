package main

import "core:mem"

str_perma_allocator : mem.Allocator
str_perma_arena : StringArena

mem_tracker : mem.Tracking_Allocator
game_window : GameWindow

game_file_info : GameFileInfo

game_logic_state : GameLogicState
game_controls: GameControls
game_shaders : GameShaders
game_textures : map[string]TextureData

imui_buffers : ImUiBuffers
game_fonts : GameFonts
