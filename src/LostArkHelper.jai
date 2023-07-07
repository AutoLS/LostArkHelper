#import "Basic";
#import "String";
#import "Windows";
#import "System";
#import "Deep_Copy";
#import "Hash_Table";
#import "Math";
#import "Reflection";
#import "JSON";
#load "math.jai";
#load "input.jai";
#load "opengl.jai";
#load "ui.jai";
#load "character.jai";
#load "raids.jai";
#load "income.jai";
#load "engraving.jai";
#load "save.jai";
#load "util.jai";
#load "time.jai";
#load "customization.jai";

/* TODO: Maybe convert save files to json? 

*/

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
    RAIDS_SETTINGS_MENU;
    ENGRAVING_BUILDER;
    CUSTOMIZATION_CONVERTER;
}

Lost_Ark_Helper :: struct
{
    character_page: Character_Page;
    income_menu: Income_Menu;
    raids_settings: Raids_Settings_Menu;
    engraving_builder: Engraving_Builder;
    current_tool: Lost_Ark_Tools;
    cus_converter_data: Customization_Converter_Data;

    file_handler: File_Handler;

    input: Input;
    clock: Clock;
}

lost_ark_helper: Lost_Ark_Helper;

init_lost_ark_helper :: ()
{
    using lost_ark_helper;
    file_handler.current_opened_save = alloc(DEFAULT_PATH_SIZE);
    cus_converter_data.file_name_ptr = alloc(DEFAULT_PATH_SIZE);
    memset(cus_converter_data.file_name_ptr, 0, DEFAULT_PATH_SIZE);
    memset(file_handler.current_opened_save, 0, DEFAULT_PATH_SIZE);
    lost_ark_helper.clock = init_clock();
	add_character(*character_page, "Character1", 0);
	init_engraving_builder(*engraving_builder);
	init_income_menu_settings();
	load_user_data_file();
}

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