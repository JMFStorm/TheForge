package main

import "core:mem"
import glfw "vendor:glfw"

mem_tracker : mem.Tracking_Allocator
game_window : GameWindow

game_logic_state : GameLogicState
game_controls: GameControls
game_shaders : GameShaders
game_textures : map[string]TextureData

imui_buffers : ImUiBuffers
game_fonts : GameFonts
