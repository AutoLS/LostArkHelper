#import "File";
#import "File_Utilities";

File_Handler :: struct
{
    recent_file: string;
    unsaved: bool;
    begin_open_file: bool;
    begin_new_file: bool;
}

User_Data_File :: struct
{
    recent_path: string;
    program_closed_time: Calendar_Time; 
}

set_unsaved :: ()
{
    using lost_ark_helper;
    if !file_handler.unsaved
    {
        file_handler.unsaved = true;
        SDL_SetWindowTitle(window, "*LostArkHelper");
    }
}

set_saved :: ()
{
    using lost_ark_helper;
    file_handler.unsaved = false;
    SDL_SetWindowTitle(window, "LostArkHelper");
}

is_unsaved :: () -> bool
{
    return lost_ark_helper.file_handler.unsaved;
}

get_recent_file :: () -> string
{
    return lost_ark_helper.file_handler.recent_file;
}

unsaved_popup :: (f: (), switch: *bool)
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
            f();
            << switch = false;
        }
        ImGui.SameLine();
        if ImGui.Button("NO")
        {
            ImGui.CloseCurrentPopup();
            f();
            << switch = false;
        }

        ImGui.EndPopup();
    }
}

save_file_dialogue :: ()
{
    file_name: [128] u8;
    initial_dir := path_strip_filename(get_path_of_running_executable());
    replace_chars(initial_dir, "/", #char "\\");
    file_dialogue: OPENFILENAME(u8);
    file_dialogue.lStructSize = size_of(OPENFILENAME(u8));
    file_dialogue.lpstrFilter = "Save files (*.sav)\0*.sav\0\0";
    file_dialogue.lpstrDefExt = "sav";
    file_dialogue.nMaxFile = 128;
    file_dialogue.lpstrFile = file_name.data;
    file_dialogue.lpstrInitialDir = temp_c_string(initial_dir);
    if GetSaveFileNameA(*file_dialogue)
    {
        save_file(to_string(file_dialogue.lpstrFile));
    }
}

open_file_dialogue :: ()
{
    file_name: [128] u8;
    initial_dir := path_strip_filename(get_path_of_running_executable());
    replace_chars(initial_dir, "/", #char "\\");
    file_dialogue: OPENFILENAME(u8);
    file_dialogue.lStructSize = size_of(OPENFILENAME(u8));
    file_dialogue.lpstrFilter = "Save files (*.sav)\0*.sav\0\0";
    file_dialogue.lpstrDefExt = "sav";
    file_dialogue.nMaxFile = 128;
    file_dialogue.lpstrFile = file_name.data;
    file_dialogue.lpstrInitialDir = temp_c_string(initial_dir);
    if GetOpenFileNameA(*file_dialogue)
    {
        open_file(to_string(file_dialogue.lpstrFile));
    }
}

new_file :: ()
{
    using lost_ark_helper;
    array_reset(*character_page.characters);
    lost_ark_helper.character_page.selected_character = 0;
    add_character(*character_page, "Character1", 0);
    if file_handler.recent_file.data
    {
        free(file_handler.recent_file);
    } 
    file_handler.recent_file = "";
    set_unsaved();
}

save_user_data :: (path: string)
{
    //User data
    set_working_directory(path_strip_filename(get_path_of_running_executable()));
    make_directory_if_it_does_not_exist("data");
    now := to_calendar(current_time_consensus());

    using lost_ark_helper.income_menu;

    user_data_builder: String_Builder;
    init_string_builder(*user_data_builder);
    print_to_builder(*user_data_builder, "recent_file %\n", path);
    print_to_builder(*user_data_builder, "last_reset_day %\n", now.day_of_week_starting_at_0);
    append_array(*user_data_builder, "material_prices", materials_prices);
    append_array(*user_data_builder, "raid_gold_income", raid_gold_income);
    for materials_storage
    {
        key, value := it_index, it;
        name := copy_temporary_string(key);
        replace_chars(name, " ", #char "_");
        append_array(*user_data_builder, name, value);
    }
    write_entire_file("data/user.dat", *user_data_builder);
}

load_user_data_file :: ()
{
    using lost_ark_helper.character_page;
    if file_exists("data/user.dat")
	{
		file_data, ok := read_entire_file("data/user.dat");
		if ok
		{
            entry := split(file_data, "\n");
            recent_path: string;
            
            for entry
            {
                using lost_ark_helper.income_menu;
                current_entry := split(it, " ");

                material_name := copy_temporary_string(current_entry[0]);
                replace_chars(material_name, "_", #char " ");
                found, index := array_find(MATERIAL_LIST_STRINGS, material_name);

                if found 
                {
                    material := table_find_pointer(*materials_storage, material_name);
                    if material
                    {
                        for i : 1 .. current_entry.count-1
                        {
                            material.data[i-1] = string_to_int(current_entry[i]);
                        }
                    }
                }

                if current_entry[0] == 
                {
                    case "recent_file"; recent_path = current_entry[1];
                    case "last_reset_day";
                    {
                        last_day := string_to_int(current_entry[1]);
                        last_reset_day = last_day;
                    }
                    case "material_prices";
                    {
                        for i : 1 .. current_entry.count-1
                        {
                            materials_prices[i-1] = string_to_float(current_entry[i]);
                        }
                    }
                    case "raid_gold_income";
                    {
                        
                        for i : 1 .. current_entry.count-1
                        {
                            raid_gold_income[i-1] = string_to_float(current_entry[i]);
                        }
                    }
                }
            }

            open_file(recent_path);
		}
	}
}

save_user_data_if_recent_file_is_valid :: ()
{
    recent_file := get_recent_file();
    if file_exists(recent_file)
    {
        save_user_data(recent_file);
    }
}

save_file :: (path: string)
{
    using lost_ark_helper.character_page;
    using lost_ark_helper.income_menu;

    set_working_directory(path_strip_filename(get_path_of_running_executable()));

    get_checked_indices :: (checklist: [] bool) -> [..] u32
    {
        arr: [..] u32;
        arr.allocator = temp;
        for checklist
        {
            if it then array_add(*arr, xx it_index);
        }

        return arr;
    }

    using lost_ark_helper.file_handler;

    if recent_file.data
    {
        free(recent_file);
    }
    recent_file = copy_string(path);

    file_builder: String_Builder;
    init_string_builder(*file_builder);
    //append_with_newline(*file_builder, "%", path);
    print_to_builder(*file_builder, "character_count %\n", characters.count);
    print_to_builder(*file_builder, "last_selected_character %\n", selected_character);

    for characters
    {
        name := to_string(it.name);
        checks := get_checked_indices(it.checklist);
        purchasing_box := get_checked_indices(it.is_purchasing_box);

        append_with_newline(*file_builder, "[BEGIN_CHARACTER]");
        print_to_builder(*file_builder, "character_name %\n", name);
        print_to_builder(*file_builder, "item_level %\n", it.item_level);
        append_checked_indices(*file_builder, "checklist", checks);
        append_checked_indices(*file_builder, "is_purchasing_box", purchasing_box);
        print_to_builder(*file_builder, "is_designated %\n", it.is_designated);
        append_with_newline(*file_builder, "[END_CHARACTER]");
    }

    write_entire_file(path, *file_builder);
    set_saved();
}

initiate_save_file :: ()
{
    using lost_ark_helper.file_handler;
    if recent_file == ""
    {
        save_file_dialogue();
    }
    else
    {
        save_user_data(recent_file);
        save_file(recent_file);
    }
}

open_file :: (path: string) -> bool
{
    set_checklist_checked :: (data: [] string, items: [] bool)
    {
        for i : 1 .. data.count-1
        {
            index := string_to_int(data[i]);
            items[index] = true;
        }
    }

    using lost_ark_helper;
    file_data, ok := read_entire_file(path);
    if ok
    {
        lost_ark_helper.file_handler.recent_file = copy_string(path);
        array_reset(*character_page.characters);
        entries := split(file_data, "\n");
        character_count: int;
        
        for entry_index : 0 .. entries.count-1
        {
            current_entry := split(entries[entry_index], " ");

            if current_entry[0] == 
            {
                case "character_count"; character_count = string_to_int(current_entry[1]);
                case "last_selected_character"; character_page.selected_character = xx string_to_int(current_entry[1]);
            }

            if starts_with(entries[entry_index], "[") &&
               contains(entries[entry_index], "BEGIN_CHARACTER")
            {
                character: Character;
                defer add_character(*character_page, character);

                entry_index += 1;
                while !starts_with(entries[entry_index], "[") && 
                      !contains(entries[entry_index], "END_CHARACTER")
                {
                    defer entry_index += 1;
                    character_data_entry := split(entries[entry_index], " ");
                    if character_data_entry[0] == 
                    {
                        case "character_name";
                        {
                            character.name = alloc(17);
                            memset(character.name, 0, 17);
                            memcpy(character.name, character_data_entry[1].data, character_data_entry[1].count);
                        }
                        
                        case "item_level";
                        {
                            character.item_level = string_to_float(character_data_entry[1]);
                        }

                        case "checklist";
                        {
                            set_checklist_checked(character_data_entry, character.checklist);
                        }

                        case "is_purchasing_box";
                        {
                            set_checklist_checked(character_data_entry, character.is_purchasing_box);
                        }

                        case "is_designated";
                        {
                            character.is_designated = 
                            ifx character_data_entry[1] == "true" then true else false;
                        }
                    }
                } 
            }
        }

        set_saved();
    }

    return ok;
}