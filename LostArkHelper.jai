#import "Basic";
#import "String";
#import "Windows";
#import "System";
#import "Deep_Copy";
#import "Hash_Table";
#import "Math";
#load "math.jai";
#load "input.jai";
#load "ui.jai";
#load "character.jai";
#load "income.jai";
#load "save.jai";
#load "util.jai";
#load "time.jai";

Lost_Ark_Raids :: enum u32
{
    Abyss_Dungeons;
    Argos;
    Valtan;
    Vykas;
}

Lost_Ark_Tools :: enum u32
{
    CHARACTER_CHECKLIST;
    INCOME_MENU;
}

Lost_Ark_Helper :: struct
{
    character_page: Character_Page;
    income_menu: Income_Menu;
    current_tool: Lost_Ark_Tools;

    file_handler: File_Handler;

    input: Input;
    clock: Clock;
}

lost_ark_helper: Lost_Ark_Helper;

get_raid_type_from_string :: (raid_str: string) -> Lost_Ark_Raids
{
    if raid_str == 
    {
        case #run WEEKLY_RAID_LIST[0]; return .Abyss_Dungeons;
        case #run WEEKLY_RAID_LIST[1]; return .Argos;
        case #run WEEKLY_RAID_LIST[2]; return .Valtan;
        case #run WEEKLY_RAID_LIST[3]; return .Vykas;
        case; return .Abyss_Dungeons;
    }
}

handle_file_action :: (is_new_file: bool, is_open_file: bool, is_save_file: bool)
{
    using lost_ark_helper.file_handler;
    keyboard_state := SDL_GetKeyboardState(null);

    new_file_shortcut := key_down(SDL_SCANCODE_LCTRL) && key_ended_down(SDL_SCANCODE_N);
    open_file_shortcut := key_down(SDL_SCANCODE_LCTRL) && key_ended_down(SDL_SCANCODE_O);
    save_file_shortcut := key_down(SDL_SCANCODE_LCTRL) && key_ended_down(SDL_SCANCODE_S);

    if is_new_file || new_file_shortcut 
    {
        begin_new_file = true;
    }

    if is_open_file || open_file_shortcut 
    {
        begin_open_file = true;
    }

    if is_save_file || save_file_shortcut 
    {
        initiate_save_file();
    }

    if begin_open_file
    {
        if is_unsaved()
        {
            unsaved_popup(open_file_dialogue, *begin_open_file);
        }
        else
        {
            open_file_dialogue();
            begin_open_file = false;
        }
    }

    if begin_new_file
    {
        if is_unsaved()
        {
            unsaved_popup(new_file, *begin_new_file);
        }
        else
        {
            new_file();
            begin_new_file = false;
        }
    }
}

update_character_page :: (using page: *Character_Page)
{
    //TODO: Doesn't work
    //update_on_reset(page);
    current_character := *characters[selected_character];

    ImGui.SetNextItemWidth(150);
    if ImGui.BeginCombo("Character Select", characters[selected_character].name)
    {
        defer ImGui.EndCombo();

        for characters
        {
            is_selected := selected_character == it_index;
            if ImGui.Selectable(it.name, is_selected)
                selected_character = xx it_index;
            
            if is_selected
                ImGui.SetItemDefaultFocus();
        }
    }
    ImGui.SameLine();
    reset_all: bool;
    ImGui.Checkbox("Reset all checklist", *reset_all);
    if reset_all
    {
        set_unsaved();
        for *characters
        {
            reset_checklist(it.checklist.data, it.checklist.count);
        }
    }

    if ImGui.Button("Add new")
    {
        add_character(page, tprint("Character%", characters.count+1), 0);
        selected_character = xx (characters.count-1);
        set_unsaved();
    }
    ImGui.SameLine();
    if ImGui.Button("Delete")
    {
        remove_character(page);
        set_unsaved();
    }
    ImGui.Separator();
    ImGui.NewLine();
    ImGui.SetNextItemWidth(150);
    character_name_edited := ImGui.InputTextWithHint
    (
        "Character Name", 
        "Enter your character name", 
        current_character.name, 16, 
        IMGUI_INPUT_TEXT_FLAGS.CharsNoBlank
    );

    if character_name_edited 
    {
        set_unsaved();
    }
    ImGui.SetNextItemWidth(100);
    if ImGui.InputFloat("Item Level", *current_character.item_level, 1.0, 5.0, "%.1f")
    {
        set_unsaved();
    }
    if current_character.item_level < 0 then current_character.item_level = 0;
    
    ImGui.NewLine();
    if ImGui.BeginChild("Checklist", .{200, 150}, false, IMGUI_WINDOW_FLAGS.HorizontalScrollbar)
    {
        if check_list("Checklist", TODO_LIST, current_character.checklist.data)
        {
            set_unsaved();
        }
    }
    ImGui.EndChild();
}