package main

main_game_logic :: proc() {
        switch game_logic_state.main_game_state {
                case .main_game: {
                        // IMUI
                        if game_controls.mouse.buttons[.m1].state.is_down {
                                draw_selection_box = true
                                if game_controls.mouse.buttons[.m1].state.pressed {
                                        box_start_ndc = get_px_pos_to_ndc(game_controls.mouse.window_pos.x, game_controls.mouse.window_pos.y)
                                }
                                box_end_ndc = get_px_pos_to_ndc(game_controls.mouse.window_pos.x, game_controls.mouse.window_pos.y)
                        } 
                        else { 
                                draw_selection_box = false 
                        }
                        if game_controls.keyboard.keys[.esc].state.pressed {
                                log_debug("to pause") 
                                game_logic_state.main_game_state = .pause_menu
                        }

                        // LOGIC
                }
                case .pause_menu: {
                        // IMUI
                        imui_menu_title("Pause menu", menu_text_size)
                        main_menu_rect := ui_rect2d_anchored_to_ndc(.center, {0, -vh(25)}, {vh(30), menu_text_size})
                        if imui_menu_button(main_menu_rect, "To main menu", vh(5)) {
                                game_logic_state.main_state = .main_menu
                        }

                        // LOGIC
                        if game_controls.keyboard.keys[.esc].state.pressed {
                                log_debug("to play game") 
                                game_logic_state.main_game_state = .main_game
                        }
                }
        }
}