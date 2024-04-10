package main

main_menu_logic :: proc() {
        switch game_logic_state.main_menu_state {
                case .main_menu: {
                        // IMUI
                        imui_menu_title("Main menu", menu_text_size)
                        play_dimensions := ui_rect2d_anchored_to_ndc(.center, {0, vh(5)}, {vh(30), menu_text_size})
                        if imui_menu_button(play_dimensions, "Play", vh(5)) { 
                                log_debug("Play game") 
                                game_logic_state.main_state = .main_game
                        }
                        setings_dimensions := ui_rect2d_anchored_to_ndc(.center, {0, -vh(10)}, {vh(30), menu_text_size})
                        if imui_menu_button(setings_dimensions, "Settings", vh(5)) { 
                                log_debug("Settings") 
                                game_logic_state.main_menu_state = .settings
                        }
                        exit_rect := ui_rect2d_anchored_to_ndc(.center, {0, -vh(25)}, {vh(30), menu_text_size})
                        if imui_menu_button(exit_rect, "Exit", vh(5)) { 
                                game_logic_state.game_running = false
                        }

                        // LOGIC
                        if game_controls.keyboard.keys[.esc].state.pressed {
                                game_logic_state.game_running = false
                        }
                }
                case .settings: {
                        // IMUI
                        imui_menu_title("Settings", menu_text_size)
                        bo_back_rect := ui_rect2d_anchored_to_ndc(.center, {0, -vh(25)}, {vh(30), menu_text_size})
                        if imui_menu_button(bo_back_rect, "Go back", vh(5)) { 
                                log_debug("Go back") 
                                game_logic_state.main_menu_state = .main_menu
                        }

                        // LOGIC
                }
        }
}