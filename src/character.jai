DAILIES_LIST := string.["Chaos Dungeons", "Guardian Raids", "Una tasks", "Guild donation"];
WEEKLY_RAID_LIST := string.["Abyss Dungeons", "Argos", "Valtan", "Vykas"];
WEEKLY_ACTIVITY := string.["Guild Mission #1", "Guild Mission #2", "Guild Mission #3", "Guild contribution reached", "Guild shop exchange", "Una task #1", "Una task #2", "Una task #3", "Sailing exchange"];
TODO_LIST := string.["Guild donation", "Guild contribution", "Guild shop exchange", "Sailing exchange"];

Character_Page :: struct
{
    characters: [..] Character;
    selected_character: s32;

    last_reset_day: int = -1;
}

Character :: struct
{
    name: *u8;
    item_level: float;
    checklist: [#run TODO_LIST.count] bool;
    is_purchasing_box: [#run WEEKLY_RAID_LIST.count] bool;
    is_designated: bool;
    notes: [65536] u8;
}

add_character :: (using page: *Character_Page, name: string, item_level: float)
{
    c: Character;
    c.name = alloc(17);
    memset(c.name, 0, 17);
    memcpy(c.name, name.data, name.count);
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

    character_names: [..] *u8;
    character_names.allocator = temp;

    for characters array_add(*character_names, it.name);

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

    ImGui.Text("Notes");
    notes_input_flags := IMGUI_INPUT_TEXT_FLAGS.AllowTabInput;
    if ImGui.InputTextMultiline("##Notes", current_character.notes.data, current_character.notes.count, make_ImVec2(0, ImGui.GetTextLineHeight() * 16), notes_input_flags) then set_unsaved();
}

