DAILIES_LIST := string.["Chaos Dungeons", "Guardian Raids", "Una tasks", "Guild donation"];
WEEKLY_RAID_LIST := string.["Abyss Dungeons", "Argos", "Valtan", "Vykas"];
WEEKLY_ACTIVITY := string.["Guild Mission #1", "Guild Mission #2", "Guild Mission #3", "Guild contribution reached", "Guild shop exchange", "Una task #1", "Una task #2", "Una task #3", "Sailing exchange"];
TODO_LIST := string.["Guild donation", "Guild contribution", "Guild shop exchange", "Sailing exchange"];

Character_Page :: struct
{
    characters: [..] Character;
    notes_buffer: [65536] u8;
    selected_character: s32;

    edit_name: *u8;

    last_reset_day: int = -1;
}

Character :: struct
{
    name: string;
    item_level: float;
    checklist: [#run TODO_LIST.count] bool;
    is_purchasing_box: [..] bool;
    is_skipping: [..] bool;
    is_designated: bool;
    notes: string;
}

init_character_page :: (page: *Character_Page)
{
    add_character(page, "Character1", 0);
    page.edit_name = alloc(17);
    memset(page.edit_name, 0, 17);
}

add_character :: (using page: *Character_Page, name: string, item_level: float)
{
    c: Character;
    c.name = name;
    c.item_level = item_level; 
    array_add(*characters, c);
}

add_character :: (using page: *Character_Page, character: Character)
{
    array_add(*characters, character);
}

remove_character :: (using page: *Character_Page)
{
    character := *characters[selected_character];
    if characters.count == 1
    {
        free(character.name);
        array_ordered_remove_by_index(*characters, selected_character);
        selected_character = 0;
        add_character(page, "Character1", 0);
    }
    else
    {
        free(character.name);
        array_ordered_remove_by_index(*characters, selected_character);
        if selected_character == characters.count 
        then selected_character -= 1;
    }
}

get_designated_count :: (using page: *Character_Page) -> int
{
    count: int;
    for characters
    {
        if it.is_designated then count += 1; 
    }

    return count;
}

update_character_page :: (using page: *Character_Page)
{
    //TODO: Doesn't work
    //update_on_reset(page);
    current_character := *characters[selected_character];
    edit_name = to_c_string(current_character.name);
    if current_character.notes.count == 0
    {
        memset(notes_buffer.data, 0, 65536);
    }
    memcpy(notes_buffer.data, current_character.notes.data, current_character.notes.count);

    character_names: [..] *u8;
    character_names.allocator = temp;

    for characters array_add(*character_names, to_c_string(it.name));

    ImGui.SetNextItemWidth(150);
    combo_box("Character Select", character_names, *selected_character);
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
        name := tprint("Character%", characters.count+1);
        add_character(page, copy_string(name), 0);
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
        edit_name, 16, 
        IMGUI_INPUT_TEXT_FLAGS.CharsNoBlank
    );

    if character_name_edited 
    {
        //TODO: Does this leak memory? This seems like a bad idea
        if current_character.name then free(current_character.name);  
        current_character.name = to_string(edit_name);
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

    ImGui.Text("Notes");
    notes_input_flags := IMGUI_INPUT_TEXT_FLAGS.AllowTabInput;
    if ImGui.InputTextMultiline("##Notes", notes_buffer.data, notes_buffer.count, make_ImVec2(0, ImGui.GetTextLineHeight() * 16), notes_input_flags) 
    {
        set_unsaved();
        if current_character.notes.data then free(current_character.notes);
        current_character.notes = copy_string(notes_buffer.data);
    }
}

