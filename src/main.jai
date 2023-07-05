#load "LostArkHelper.jai";

window: *SDL_Window;

main :: ()
{
	SDL_Init(SDL_INIT_VIDEO);

	window = SDL_CreateWindow
	(
		"LostArkHelper", 
		SDL_WINDOWPOS_CENTERED,
		SDL_WINDOWPOS_CENTERED, 
		1280, 720,
		SDL_WINDOW_OPENGL
	);

	if window == null 
	{
		print("Could not create window: %\n", to_string(SDL_GetError()));
		return;
	}

	print("%\n", to_string(ImGui.GetVersion()));
	SDL_GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, xx SDL_GL_CONTEXT_PROFILE_CORE);
	gl_context := SDL_GL_CreateContext(window);
    if !gl_context 
	{
        print( "Could not create OpenGL context: %\n", to_string(SDL_GetError()));
        return;
    }

	gl_load(*gl, SDL_GL_GetProcAddress);

    imgui_context := ImGui.CreateContext();

    // Setup ImGui binding
    ImGui_ImplSdl_Init(window);

	ImGui.StyleColorsClassic();

	io := ImGui.GetIO();

	running := true;
	is_quit: bool;
	clear_color := make_vector4(0, 0, 0, 1.00);
	main_tool_active: bool;
	show_app_metric: bool;

	using lost_ark_helper;
	init_lost_ark_helper();

	while running
	{
		reset_temporary_storage();
		reset_controller_input(*input.keyboard);

		event: SDL_Event;
        while SDL_PollEvent(*event) 
		{
            ImGui_ImplSdl_ProcessEvent(*event);
            if event.type == SDL_QUIT   is_quit = true;
            if event.type == SDL_WINDOWEVENT && 
			   event.window.event == SDL_WINDOWEVENT_CLOSE && 
			   event.window.windowID == SDL_GetWindowID(window) 
			{
				is_quit = true;
            }

			if event.type ==
			{
				case SDL_KEYDOWN; #through;
				case SDL_KEYUP;
				{
					is_down: bool = event.key.state == SDL_PRESSED;
					was_down: bool;
					
					if event.key.state == SDL_RELEASED
					{
						was_down = true;
					}
					else if event.key.repeat != 0
					{
						was_down = true;
					}
					
					if event.key.repeat == 0
					{
						key := event.key.keysym.scancode;
						
						button_state := table_find_pointer(*input.keyboard.keys, key);
						if button_state 
						{
							process_keypress(button_state, is_down, was_down);
						}
						else
						{
							new_state: Button_State;
							process_keypress(*new_state, is_down, was_down);
							table_add(*input.keyboard.keys, key, new_state);
						}
					}
				}
			}
        }

		ImGui_ImplSdl_NewFrame(window);
		ImGui.NewFrame();

		is_new_file := false;
		is_open_file := false;
		is_save_file := false;
		
		ImGui.Begin("LostArkHelper", *main_tool_active, 
					IMGUI_WINDOW_FLAGS.NoTitleBar | 
					IMGUI_WINDOW_FLAGS.MenuBar |
					IMGUI_WINDOW_FLAGS.NoMove |
					IMGUI_WINDOW_FLAGS.NoResize |
					IMGUI_WINDOW_FLAGS.NoBackground | 
					IMGUI_WINDOW_FLAGS.HorizontalScrollbar);
		if ImGui.BeginMenuBar()
		{
			defer ImGui.EndMenuBar();
			if ImGui.BeginMenu("File")
			{
				defer ImGui.EndMenu();
				is_new_file = ImGui.MenuItem("New", "Ctrl+N");

				is_open_file = ImGui.MenuItem("Open..", "Ctrl+O");

				is_save_file = ImGui.MenuItem("Save", "Ctrl+S");

				if ImGui.MenuItem("Save as..") 
				{
					save_file_dialogue();
				}
			}
			if ImGui.BeginMenu("Menu")
			{
				defer ImGui.EndMenu();
				if ImGui.MenuItem("Checklist", null) current_tool = .CHARACTER_CHECKLIST;
				if ImGui.MenuItem("Income", null) current_tool = .INCOME_MENU;
				if ImGui.MenuItem("Raids", null) current_tool = .RAIDS_SETTINGS_MENU;
				if ImGui.MenuItem("Engraving Builder", null) current_tool = .ENGRAVING_BUILDER;
				if ImGui.MenuItem("Preset Converter", null) current_tool = .CUSTOMIZATION_CONVERTER;
				ImGui.MenuItem("Debug Metrics", null, *show_app_metric);
			}
		}

		handle_file_action(is_new_file, is_open_file, is_save_file);
		if is_quit
		{
			if is_unsaved()
			{
				ImGui.OpenPopup("Unsaved");
				if ImGui.BeginPopupModal("Unsaved", null, IMGUI_WINDOW_FLAGS.AlwaysAutoResize)
				{
					ImGui.Text("Would you like to save the file first?\n\n");
					ImGui.Separator();

					if ImGui.Button("YES")
					{
						initiate_save_file();
						ImGui.CloseCurrentPopup();
						running = false; 
					}
					ImGui.SameLine();
					if ImGui.Button("NO")
					{
						save_user_data_if_recent_file_is_valid();
						ImGui.CloseCurrentPopup();
						running = false;
					}
					ImGui.SameLine();
					if ImGui.Button("CANCEL")
					{
						ImGui.CloseCurrentPopup();
						is_quit = false;
					}

					ImGui.EndPopup();
				}
			}
			else 
			{
				save_user_data_if_recent_file_is_valid();
				running = false;
			}
		}

		if show_app_metric then ImGui.ShowMetricsWindow(*show_app_metric);

		if current_tool == 
		{
			case .CHARACTER_CHECKLIST;
			{
				update_character_page(*character_page);
			}

			case .INCOME_MENU;
			{
				update_income_menu();
			}

			case .RAIDS_SETTINGS_MENU;
			{
				update_raids_settings_menu();
			}

			case .ENGRAVING_BUILDER;
			{
				update_engraving_builder_page(*engraving_builder);
			}

			case .CUSTOMIZATION_CONVERTER;
			{
				update_customization_converter_menu(*cus_converter_data);
			}
		}
		ImGui.End();

		lock_fps(*lost_ark_helper.clock, 60);

		ImGui.Render();
        glViewport(0, 0, xx io.DisplaySize.x, xx io.DisplaySize.y);
        glClearColor(clear_color.x, clear_color.y, clear_color.z, clear_color.w);
        glClear(GL_COLOR_BUFFER_BIT);
        ImGui_ImplSdl_RenderDrawLists(ImGui.GetDrawData());
        SDL_GL_SwapWindow(window);

		update_clock(*lost_ark_helper.clock);
	} 
}