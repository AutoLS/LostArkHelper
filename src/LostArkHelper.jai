#import "Basic";
#import "String";
#import "Windows";
#import "System";
#import "Deep_Copy";
#import "Hash_Table";
#import "Math";
#import "Reflection";
#import "JSON";
JSON :: #import "JSON_Plus";
#import "Curl";
#import "Sort";
#load "math.jai";
#load "input.jai";
#load "opengl.jai";
#load "render.jai";
#load "ui.jai";
#load "character.jai";
#load "raids.jai";
#load "income.jai";
#load "engraving.jai";
#load "save.jai";
#load "util.jai";
#load "time.jai";
#load "customization.jai";
#load "network.jai";
#load "itemAPI.jai";
#load "bingo.jai";
#load "log_calculator.jai";

/* TODO: Maybe convert save files to json? 

*/

APP_VERSION :: "v1.4.2";

Lost_Ark_Tools :: enum u32
{
    CHARACTER_CHECKLIST;
    INCOME_MENU;
    RAIDS_SETTINGS_MENU;
    ENGRAVING_BUILDER;
    CUSTOMIZATION_CONVERTER;
    BINGO_CALCULATOR;
    LOG_CALCULATOR;
}

Lost_Ark_Helper :: struct
{
    character_page: Character_Page;
    income_menu: Income_Menu;
    raids_settings: Raids_Settings_Menu;
    engraving_builder: Engraving_Builder;
    current_tool: Lost_Ark_Tools;
    cus_converter_data: Customization_Converter_Data;
    log_calculator_data: Log_Calculator_Data;
    bingo_board: Bingo_Board;

    file_handler: File_Handler;

    input: Input;
    clock: Clock;
    curl_handle: *CURL;

    window_dimension: Vector2;
    simple_renderer: Simple_Renderer;
}

lost_ark_helper: Lost_Ark_Helper;

init_lost_ark_helper :: ()
{
    using lost_ark_helper;
    current_tool = .CHARACTER_CHECKLIST;
    window_dimension = .{1280, 720};
    simple_renderer = create_simple_renderer();
    curl_handle = curl_easy_init();
    //assert(curl_handle != null);
    file_handler.current_opened_save = alloc(DEFAULT_PATH_SIZE);
    cus_converter_data.file_name_ptr = alloc(DEFAULT_PATH_SIZE);
    memset(cus_converter_data.file_name_ptr, 0, DEFAULT_PATH_SIZE);
    memset(file_handler.current_opened_save, 0, DEFAULT_PATH_SIZE);
    lost_ark_helper.clock = init_clock();
	init_character_page(*character_page);
	init_engraving_builder(*engraving_builder);
	init_income_menu_settings();
    init_bingo_board(*bingo_board);
	load_user_data_file();
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
            //open_file_dialogue();
            open_file_dialogue_json();
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