Engravings :: enum u32
{
    None;
    Adrenaline;
    All_Out_Attack;
    Ambush_Master;
    Arthetinean_Skill;
    Awakening;
    Barrage_Enhancement;
    Barricade;
    Berserkers_Technique;
    Blessed_Aura;
    Broken_Bone;
    Combat_Readiness;
    Communication_Overflow;
    Contender;
    Control;
    Crisis_Evasion;
    Crushing_Fist;
    Cursed_Doll;
    Death_Strike;
    Deathblow;
    Demonic_Impulse;
    Desperate_Salvation;
    Disrespect;
    Divine_Protection;
    Drops_of_Ether;
    Emergency_Rescue;
    Empress_Grace;
    Energy_Overflow;
    Enhanced_Shield;
    Enhanced_Weapon;
    Esoteric_Flurry;
    Esoteric_Skill_Enhancement;
    Ether_Predator;
    Evolutionary_Legacy;
    Expert;
    Explosive_Expert;
    Firepower_Enhancement;
    First_Intention;
    Fortitude;
    Gravity_Training;
    Grudge;
    Heavy_Armor;
    Hit_Master;
    Hunger;
    Igniter;
    Judgment;
    Keen_Blunt_Weapon;
    Lightning_Fury;
    Lone_Knight;
    Loyal_Companion;
    Lunar_Voice;
    Magick_Stream;
    Mass_Increase;
    Master_Brawler;
    Master_of_Escape;
    Master_Summoner;
    Masters_Tenacity;
    Max_MP_Increase;
    Mayhem;
    MP_Efficiency_Increase;
    Necromancy;
    Order_of_the_Emperor;
    Peacemaker;
    Perfect_Suppression;
    Pinnacle;
    Pistoleer;
    Precise_Dagger;
    Preemptive_Strike;
    Propulsion;
    Rage_Hammer;
    Raid_Captain;
    Reflux;
    Remaining_Energy;
    Robust_Spirit;
    Shield_Piercing;
    Shock_Training;  
    Sight_Focus;
    Spirit_Absorption;
    Stabilized_Status;
    Strong_Will;
    Super_Charge;
    Surge_Zero;
    Time_to_Hunt;
    True_Courage;
    Ultimate_Skill_Taijutsu;
    Vital_Point_Hit;
}

Accessory :: enum u32
{
    Necklace;
    Earring_1;
    Earring_2;
    Ring_1;
    Ring_2;
    Engraving_1;
    Engraving_2;
    Stone;
}

NUM_ENGRAVING :: 6;
NUM_ACCESSORY :: #run enum_highest_value(Accessory)+1;

Engraving_Preset :: struct
{
    name: *u8;
    engravings: [NUM_ENGRAVING] Engravings;
    engraving_points: [NUM_ACCESSORY*NUM_ENGRAVING] u8;
    reduced_abilities_points: [5] u8;
}

Engraving_Builder :: struct 
{
    presets: [..] Engraving_Preset;
    engraving_names: [#run enum_highest_value(Engravings) + 1] *u8;
    accessory_textures: [#run enum_highest_value(Accessory) + 1] u32;
    selected_preset: s32;
}

init_engraving_builder :: (using engraving_builder: *Engraving_Builder)
{
    enum_info := type_info(Engravings);
    for enum_info.values 
    {
        name := copy_temporary_string(enum_info.names[it_index]);
        replace_chars(name, "_", #char " ");
        engraving_names[it_index] = alloc(name.count+1);
        memset(engraving_names[it_index], 0, name.count+1);
        memcpy(engraving_names[it_index], name.data, name.count);
    }

    for 0 .. enum_highest_value(Accessory)
    {
        path := temp_c_string(tprint("ast/%.png", enum_value_to_name(cast(Accessory)it)));
        accessory_textures[it] = gl_load_texture(path, true);
    }
}

add_engraving_preset :: (using engraving_builder: *Engraving_Builder, name: string)
{
    preset: Engraving_Preset;
    size := name.count + 1;
    preset.name = alloc(size);
    memset(preset.name, 0, size);
    memcpy(preset.name, name.data, name.count);
    array_add(*presets, preset);
}

remove_preset :: (using engraving_builder: *Engraving_Builder)
{
    preset := *presets[selected_preset];
    if presets.count == 1
    {
        free(preset.name);
        array_ordered_remove_by_index(*presets, selected_preset);
        selected_preset = 0;
        add_engraving_preset(engraving_builder, "Preset1");
    }
    else
    {
        free(preset.name);
        array_ordered_remove_by_index(*presets, selected_preset);
        if selected_preset == presets.count 
        then selected_preset -= 1;
    }
}

update_engraving_builder_page :: (using engraving_builder: *Engraving_Builder)
{
    current_preset := *presets[selected_preset];
    ImGui.SetNextItemWidth(150);

    preset_names: [..] *u8;
    preset_names.allocator = temp;

    for presets 
    {
        array_add(*preset_names, it.name);
    }

    combo_box("Preset Select", preset_names, *selected_preset);

    if ImGui.Button("Add new")
    {
        add_engraving_preset(engraving_builder, tprint("Preset%", presets.count+1));
        selected_preset = xx (presets.count-1);
        set_unsaved();
    }
    ImGui.SameLine();
    if ImGui.Button("Delete")
    {
        remove_preset(engraving_builder);
        set_unsaved();
    }
    ImGui.Separator();
    ImGui.NewLine();
    ImGui.SetNextItemWidth(150);
    if ImGui.InputTextWithHint
    (
        "Preset Name", 
        "Enter preset name", 
        current_preset.name, 16, 
        IMGUI_INPUT_TEXT_FLAGS.CharsNoBlank
    ) then set_unsaved();

    ImGui.PushStyleVar(STYLE_VAR.CellPadding, make_ImVec2(10, 5));
    table_flags := TABLE_FLAGS.Borders | TABLE_FLAGS.SizingFixedFit | TABLE_FLAGS.NoHostExtendX;
    if ImGui.BeginTable("Engraving_Table", 7, table_flags)
    {
        defer ImGui.EndTable();

        row_headers := string.["Necklace", "Earring 1", "Earring 2", "Ring 1", "Ring 2", "Slot 1", "Slot 2", "Stone"];

        n_row := row_headers.count;
        n_col := NUM_ENGRAVING;

        ImGui.TableNextRow();

        ImGui.TableSetColumnIndex(0);
        ImGui.AlignTextToFramePadding();
        ImGui.Text("Accessory");

        for column_index: 0 .. n_col-1
        {
            ImGui.TableSetColumnIndex(xx (column_index+1));
            name := tprint("Engraving %", column_index+1);
            ImGui.Text(name);
            selected_engraving := engraving_names[current_preset.engravings[column_index]];
            cell: s32 = cast(s32)(column_index);
            ImGui.PushID(cell);
            ImGui.PushItemWidth(150);
            combo_box("##cell", engraving_names, cast(*s32)*current_preset.engravings[column_index]);
            ImGui.PopID();

            button_label := temp_c_string(tprint("Reset##%", column_index));
            if ImGui.Button(button_label)
            {
                for 0 .. n_row-1
                {
                    current_preset.engraving_points[to_2d_index(it, column_index, NUM_ENGRAVING)] = 0;
                }
                set_unsaved();
            }
        }
        
        for row_index: 0 .. n_row-1
        {
            ImGui.TableNextRow();

            ImGui.TableSetColumnIndex(0);
            ImGui.Image(cast(*void)accessory_textures[row_index], make_ImVec2(32, 32));
            ImGui.Text(row_headers[row_index]);
            
            for column_index: 0 .. n_col-1
            {
                ImGui.TableSetColumnIndex(xx (column_index+1));
                step: u8 = 1;
                data: *u8 = *current_preset.engraving_points[to_2d_index(row_index, column_index, NUM_ENGRAVING)];
                cell: s32 = cast(s32)(row_index * n_col + column_index);
                ImGui.PushItemWidth(90);
                ImGui.PushID(cell);
                if ImGui.InputScalar("##input", DType.U8, data, *step)
                {
                    if row_headers[row_index] ==
                    {
                        case "Slot 1"; #through;
                        case "Slot 2";
                        {
                            Clamp(data, 0, 12);
                        }
                        case "Stone"; Clamp(data, 0, 10);
                        case; Clamp(data, 0, 5);
                    }
                    set_unsaved();
                }
                ImGui.PopID();
            }
        }

        ImGui.TableNextRow(TABLE_ROW_FLAGS.None, 24);
        ImGui.TableNextRow(TABLE_ROW_FLAGS.None, 24);
        ImGui.TableSetColumnIndex(0);
        ImGui.Text("Total");

        for current_preset.engravings
        {
            ImGui.TableSetColumnIndex(xx (it_index+1));
            if it != Engravings.None
            {
                sum: int;
                for row: 0 .. n_row-1
                {
                    sum += current_preset.engraving_points[to_2d_index(row, it_index, NUM_ENGRAVING)];
                }
                ImGui.Text(tprint("+%", sum));
            }
            else
            {
                ImGui.Text("+0");
            }
        }
    }
    ImGui.PopStyleVar();
}