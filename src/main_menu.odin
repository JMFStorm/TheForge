package main

GameUserSettings :: struct {
        is_fullscreen: bool,
}

apply_game_settings :: proc() {
        set_window_fullscreen(game_user_settings.is_fullscreen)
}

main_menu_logic :: proc() {
        switch game_logic_state.main_menu_state {
                case .main_menu: {
                        // IMUI
                        imui_menu_title("Main menu", menu_title_text_size)
                        play_dimensions := ui_rect2d_anchored_to_ndc(.center, {0, vh(5)}, {vh(30), menu_text_size})
                        if imui_menu_button(play_dimensions, "Play", menu_text_size) { 
                                log_debug("Play game") 
                                game_logic_state.main_state = .main_game
                        }
                        setings_dimensions := ui_rect2d_anchored_to_ndc(.center, {0, -vh(10)}, {vh(30), menu_text_size})
                        if imui_menu_button(setings_dimensions, "Settings", menu_text_size) { 
                                log_debug("Settings") 
                                game_logic_state.main_menu_state = .settings
                        }
                        exit_rect := ui_rect2d_anchored_to_ndc(.center, {0, -vh(25)}, {vh(30), menu_text_size})
                        if imui_menu_button(exit_rect, "Exit", menu_text_size) { 
                                game_logic_state.game_running = false
                        }

                        // LOGIC
                        if game_controls.keyboard.keys[.esc].state.pressed {
                                game_logic_state.game_running = false
                        }
                }
                case .settings: {
                        // IMUI
                        imui_menu_title("Settings", menu_title_text_size)

                        checbox_1_pos := ui_rect2d_anchored_to_ndc(.center, {0, vh(5)}, {vh(30), 0})
                        imui_setting_checkbox(checbox_1_pos.bot_left, "Fullscreen", menu_text_size, &game_user_settings.is_fullscreen) 

                        go_back_rect := ui_rect2d_anchored_to_ndc(.center, {vh(17), -vh(25)}, {vh(30), menu_text_size})
                        if imui_menu_button(go_back_rect, "Go back", menu_text_size) { 
                                log_debug("Go back") 
                                game_logic_state.main_menu_state = .main_menu
                        }

                        apply_back_rect := ui_rect2d_anchored_to_ndc(.center, {vh(-17), -vh(25)}, {vh(30), menu_text_size})
                        if imui_menu_button(apply_back_rect, "Apply", menu_text_size) { 
                                log_debug("Apply") 
                                apply_game_settings()
                        }

                        // LOGIC
                }
        }
}