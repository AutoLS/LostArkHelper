#import "File";
#import "File_Utilities";

DEFAULT_PATH_SIZE :: 1024;

File_Handler :: struct
{
    recent_file: string;
    unsaved: bool;
    begin_open_file: bool;
    begin_new_file: bool;

    current_opened_save: *u8;
}

User_Data_File :: struct
{
    recent_path: string;
    program_closed_time: Calendar_Time; 
}

LOA_Helper_Save_File :: struct
{
    recent_path: string;
    characters_data: [..] Character;
    engravings_data: [..] Engraving_Preset;
    selected_engraving_preset: s32;
    raids_data: [..] Raid;
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
        save_file_json(to_string(file_dialogue.lpstrFile));
    }
}

save_file_dialogue_json :: ()
{
    file_name: [128] u8;
    initial_dir := path_strip_filename(get_path_of_running_executable());
    replace_chars(initial_dir, "/", #char "\\");
    file_dialogue: OPENFILENAME(u8);
    file_dialogue.lStructSize = size_of(OPENFILENAME(u8));
    file_dialogue.lpstrFilter = "JSON files (*.json)\0*.json\0\0";
    file_dialogue.lpstrDefExt = "json";
    file_dialogue.nMaxFile = 128;
    file_dialogue.lpstrFile = file_name.data;
    file_dialogue.lpstrInitialDir = temp_c_string(initial_dir);
    if GetSaveFileNameA(*file_dialogue)
    {
        save_file_json(to_string(file_dialogue.lpstrFile));
    }
}

get_open_file_name :: (filter: *u8, ext: *u8, file_name: *u8, size: s32 = DEFAULT_PATH_SIZE) -> OPENFILENAME(u8)
{
    initial_dir := path_strip_filename(get_path_of_running_executable());
    replace_chars(initial_dir, "/", #char "\\");
    file_dialogue: OPENFILENAME(u8);
    file_dialogue.lStructSize = size_of(OPENFILENAME(u8));
    file_dialogue.lpstrFilter = filter;
    file_dialogue.lpstrDefExt = ext;
    file_dialogue.nMaxFile = xx size;
    file_dialogue.lpstrFile = file_name;
    file_dialogue.lpstrInitialDir = temp_c_string(initial_dir);

    return file_dialogue;
}

open_file_dialogue :: ()
{
    file_dialogue := get_open_file_name("Save files (*.sav)\0*.sav\0\0", "sav", lost_ark_helper.file_handler.current_opened_save);

    if GetOpenFileNameA(*file_dialogue)
    {
        open_file(to_string(file_dialogue.lpstrFile));
    }
}

open_file_dialogue_json :: ()
{
    file_dialogue := get_open_file_name("JSON files (*.json)\0*.json\0\0", "json", lost_ark_helper.file_handler.current_opened_save);

    if GetOpenFileNameA(*file_dialogue)
    {
        open_file(to_string(file_dialogue.lpstrFile));
    }
}

new_file :: ()
{
    using lost_ark_helper;
    array_reset(*character_page.characters);
    array_reset(*engraving_builder.presets);
    lost_ark_helper.character_page.selected_character = 0;
    lost_ark_helper.engraving_builder.selected_preset = 0;
    add_character(*character_page, "Character1", 0);
    add_engraving_preset(*engraving_builder, "Preset1");
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
    for materials_storage
    {
        key, value := it_index, it;
        name := copy_temporary_string(key);
        replace_chars(name, " ", #char "_");
        append_array(*user_data_builder, name, value);
    }
    write_entire_file("data/user.dat", *user_data_builder);

    set_saved();
}

load_user_data_file :: ()
{
    using lost_ark_helper.character_page;

    if file_exists("data/raids_data.json")
    {
        using lost_ark_helper.raids_settings;
        raids=, ok:, err := JSON.from_json_file([..] Raid, "data/raids_data.json");
        if ok then total_gates = get_total_gates(raids);
    }

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
                }
            }

            open_file(recent_path);
            //open_file_json(recent_path);
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

save_file_json :: (path: string)
{
    using lost_ark_helper.file_handler;

    if recent_file.data
    {
        free(recent_file);
    }
    recent_file = copy_string(path);

    loa_helper_save_file: LOA_Helper_Save_File;
    loa_helper_save_file.recent_path = recent_file;
    loa_helper_save_file.characters_data = lost_ark_helper.character_page.characters;
    loa_helper_save_file.engravings_data = lost_ark_helper.engraving_builder.presets;
    loa_helper_save_file.selected_engraving_preset = lost_ark_helper.engraving_builder.selected_preset;
    loa_helper_save_file.raids_data = lost_ark_helper.raids_settings.raids;

    json_write_file(path, loa_helper_save_file);
    set_saved();
}

save_file :: (path: string)
{
    using lost_ark_helper.character_page;
    using lost_ark_helper.income_menu;
    using lost_ark_helper.engraving_builder;

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

    loa_helper_save_file: LOA_Helper_Save_File;
    loa_helper_save_file.recent_path = recent_file;
    loa_helper_save_file.characters_data = lost_ark_helper.character_page.characters;
    loa_helper_save_file.engravings_data = lost_ark_helper.engraving_builder.presets;
    loa_helper_save_file.selected_engraving_preset = lost_ark_helper.engraving_builder.selected_preset;
    loa_helper_save_file.raids_data = lost_ark_helper.raids_settings.raids;

    json_write_file("sav/default.json", loa_helper_save_file);

    file_builder: String_Builder;
    init_string_builder(*file_builder);
    //append_with_newline(*file_builder, "%", path);
    print_to_builder(*file_builder, "character_count %\n", characters.count);
    print_to_builder(*file_builder, "last_selected_character %\n", selected_character);
    print_to_builder(*file_builder, "last_selected_preset %\n", selected_preset);

    for characters
    {
        name := it.name;
        checks := get_checked_indices(it.checklist);
        purchasing_box := get_checked_indices(it.is_purchasing_box);
        skipping := get_checked_indices(it.is_skipping);

        append_with_newline(*file_builder, "[BEGIN_CHARACTER]");
        print_to_builder(*file_builder, "character_name %\n", name);
        print_to_builder(*file_builder, "item_level %\n", it.item_level);
        append_checked_indices(*file_builder, "checklist", checks);
        append_checked_indices(*file_builder, "is_purchasing_box", purchasing_box);
        append_checked_indices(*file_builder, "is_skipping", skipping);
        print_to_builder(*file_builder, "is_designated %\n", it.is_designated);
        len := c_style_strlen(it.notes.data);
        append_with_newline(*file_builder, "[BEGIN_NOTES]");
        append_with_newline(*file_builder, to_string(it.notes.data, len));
        append_with_newline(*file_builder, "[END_NOTES]");
        append_with_newline(*file_builder, "[END_CHARACTER]");
    }

    for presets 
    {
        name := to_string(it.name);
        append_with_newline(*file_builder, "[BEGIN_ENGRAVING_PRESET]");
        print_to_builder(*file_builder, "preset_name %\n", name);
        append_array(*file_builder, "engravings", it.engravings);
        append_array(*file_builder, "engraving_points", it.engraving_points);
        negative_engravings: SOA(Negative_Engraving, 6);
        AOS_To_SOA(it.negative_engraving_points, *negative_engravings);
        append_array(*file_builder, "negative_engravings_type", negative_engravings.type);
        append_array(*file_builder, "negative_engravings_value", negative_engravings.value);
        append_with_newline(*file_builder, "[END_ENGRAVING_PRESET]");
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
        //save_file_dialogue_json();
    }
    else
    {
        path := copy_temporary_string(recent_file);
        save_user_data(path);
        save_file(path);
        //save_file_json(path);
    }
}

open_file_json :: (path: string) -> bool
{
    data, ok, err := JSON.from_json_file(LOA_Helper_Save_File, path);
    if ok
    {
        lost_ark_helper.file_handler.recent_file = data.recent_path;
        lost_ark_helper.character_page.characters = data.characters_data;
        lost_ark_helper.engraving_builder.presets = data.engravings_data;
        lost_ark_helper.engraving_builder.selected_preset = data.selected_engraving_preset;
        lost_ark_helper.raids_settings.raids = data.raids_data;
    }

    return ok;
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
        array_reset(*engraving_builder.presets);

        entries := split(file_data, "\n");
        character_count: int;

        begin_note_string := "[BEGIN_NOTES]";
        end_note_string := "[END_NOTES]";
        begin_notes_index: int;
        end_notes_index: int;
        
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
                array_resize(*character.is_purchasing_box, lost_ark_helper.raids_settings.total_gates);
                array_resize(*character.is_skipping, lost_ark_helper.raids_settings.total_gates);
                defer add_character(*character_page, character);

                begin_notes_index = find_index_from_left(file_data, begin_note_string, end_notes_index);

                if begin_notes_index != -1
                {
                    end_notes_index = find_index_from_left(file_data, end_note_string, begin_notes_index);
                    notes_cursor := begin_notes_index + begin_note_string.count + 1;
                    note_index := 0;

                    while notes_cursor < end_notes_index
                    {
                        character.notes[note_index] = file_data.data[notes_cursor];
                        note_index += 1;
                        notes_cursor += 1;
                    }
                }

                entry_index += 1;
                while !contains(entries[entry_index], "[END_CHARACTER]")
                {
                    defer entry_index += 1;
                    character_data_entry := split(entries[entry_index], " ");
                    if character_data_entry[0] == 
                    {
                        case "character_name";
                        {
                            character.name = character_data_entry[1];
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

                        case "is_skipping";
                        {
                            set_checklist_checked(character_data_entry, character.is_skipping);
                        }

                        case "is_designated";
                        {
                            character.is_designated = 
                            ifx character_data_entry[1] == "true" then true else false;
                        }
                    }
                } 
            }

            if starts_with(entries[entry_index], "[") &&
               contains(entries[entry_index], "BEGIN_ENGRAVING_PRESET")
            {
                preset: Engraving_Preset;
                defer array_add(*engraving_builder.presets, preset);

                entry_index += 1;
                while !starts_with(entries[entry_index], "[") && 
                      !contains(entries[entry_index], "END_ENGRAVING_PRESET")
                {
                    defer entry_index += 1;
                    preset_data_entry := split(entries[entry_index], " ");

                    if preset_data_entry[0] == 
                    {
                        case "preset_name";
                        {
                            size := preset_data_entry[1].count+1;
                            preset.name = alloc(size);
                            memset(preset.name, 0, size);
                            memcpy(preset.name, preset_data_entry[1].data, preset_data_entry[1].count);
                        }

                        case "engravings";
                        {
                            for 1 .. preset_data_entry.count-1
                            {
                                preset.engravings[it-1] = enum_name_to_value(Engravings, preset_data_entry[it]);
                            }
                        }

                        case "engraving_points";
                        {
                            for 1 .. preset_data_entry.count-1
                            {
                                preset.engraving_points[it-1] = xx string_to_int(preset_data_entry[it]);
                            }
                        }

                        case "negative_engravings_type";
                        {
                            for 1 .. preset_data_entry.count-1
                            {
                                preset.negative_engraving_points[it-1].type = enum_name_to_value(Reduction_Type, preset_data_entry[it]);
                            }
                        }

                        case "negative_engravings_value";
                        {
                            for 1 .. preset_data_entry.count-1
                            {
                                preset.negative_engraving_points[it-1].value = xx string_to_int(preset_data_entry[it]);
                            }
                        }
                    }
                }
            }
        }

        if engraving_builder.presets.count == 0
        {
            add_engraving_preset(*engraving_builder, "Preset1");
            engraving_builder.selected_preset = 0;
        }

        set_saved();
    }

    return ok;
}