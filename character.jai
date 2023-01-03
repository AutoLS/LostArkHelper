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

update_on_reset :: (using page: *Character_Page)
{
/*
    current_time := current_time_consensus();
    current_calendar_time := to_calendar(current_time);

    if current_calendar_time.hour >= 10 && 
       current_calendar_time.day_of_week_starting_at_0 != last_reset_day 
    {
        last_reset_day = current_calendar_time.day_of_week_starting_at_0;
        for characters
        {
            reset_checklist(it.dailies_checklist.data, it.dailies_checklist.count);
        }

        if current_calendar_time.day_of_week_starting_at_0 == 3
        {
            for characters
            {
                reset_checklist(it.weekly_raid_checklist.data, it.weekly_raid_checklist.count);
                reset_checklist(it.weekly_activity_checklist.data, it.weekly_activity_checklist.count);
            }
        }

        recent_file := get_recent_file();
        
        if recent_file != ""
        {
            save_file(recent_file);
        }
    }
*/
}
