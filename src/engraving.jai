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
    Full_Bloom;
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
    Predator;
    Preemptive_Strike;
    Propulsion;
    Punisher;
    Rage_Hammer;
    Raid_Captain;
    Recurrence;
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

Reduction_Type :: enum u32
{
    None;
    Atk_Speed_Reduction;
    Mov_Speed_Reduction;
    Def_Reduction;
    Atk_Pow_Reduction;
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

Negative_Engraving :: struct
{
    type: Reduction_Type;
    value: u8;
}

Engraving_Preset :: struct
{
    name: *u8;
    engravings: [NUM_ENGRAVING] Engravings;
    engraving_points: [NUM_ACCESSORY*NUM_ENGRAVING] u8;
    negative_engraving_points: [6] Negative_Engraving;
}

Engraving_Builder :: struct 
{
    presets: [..] Engraving_Preset;
    engraving_names: [#run enum_highest_value(Engravings) + 1] *u8;
    negative_engraving_names: [#run enum_highest_value(Reduction_Type) + 1] *u8;
    accessory_textures: [#run enum_highest_value(Accessory) + 1] u32;
    selected_preset: s32;
}

init_engraving_builder :: (using engraving_builder: *Engraving_Builder)
{
    add_engraving_preset(engraving_builder, "Preset1");
    enum_info := type_info(Engravings);
    for enum_info.values 
    {
        name := copy_temporary_string(enum_info.names[it_index]);
        replace_chars(name, "_", #char " ");
        engraving_names[it_index] = alloc(name.count+1);
        memset(engraving_names[it_index], 0, name.count+1);
        memcpy(engraving_names[it_index], name.data, name.count);
    }

    enum_info = type_info(Reduction_Type);
    for enum_info.values 
    {
        name := copy_temporary_string(enum_info.names[it_index]);
        replace_chars(name, "_", #char " ");
        negative_engraving_names[it_index] = alloc(name.count+1);
        memset(negative_engraving_names[it_index], 0, name.count+1);
        memcpy(negative_engraving_names[it_index], name.data, name.count);
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
    preset.name = alloc(17);
    memset(preset.name, 0, 17);
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
    if ImGui.Button("Duplicate")
    {
        current_preset_copy := << current_preset;
        current_preset_copy.name = alloc(17);
        memcpy(current_preset_copy.name, current_preset.name, 17);
        array_insert_at(*presets, current_preset_copy, selected_preset);
        set_unsaved();
    }
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
    if ImGui.BeginTable("Engraving_Table", 8, table_flags)
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
        
        { // Negative Engraving
            ImGui.TableSetColumnIndex(7);
            ImGui.Text("Negative abilities");
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

                if (<< data) > 0
                {
                    r := #run 73.0/255.0;
                    g := #run 81.0/255.0;
                    b := #run 89.0/255.0;
                    cell_bg_color := ImGui.GetColorU32(make_ImVec4(r, g, b, 0.5));
                    ImGui.TableSetBgColor(ImGui.TableBgTarget.CellBg, cell_bg_color);
                }

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
                        case; Clamp(data, 0, 6);
                    }
                    set_unsaved();
                }
                ImGui.PopID();
            }

            { // Negative Engraving
                ImGui.TableSetColumnIndex(7);
                if row_headers[row_index] == 
                {
                    case "Necklace"; #through;
                    case "Earring 1"; #through;
                    case "Earring 2"; #through;
                    case "Ring 1"; #through;
                    case "Ring 2"; #through;
                    case "Stone";
                    {
                        ImGui.PushItemWidth(120);
                        engraving_index := ifx row_index >= 0 && row_index < 5 then row_index else 5;
                        step: u8 = 1;
                        cb_label := tprint("##negative_engraving_selection%", engraving_index);
                        input_label := tprint("##negative_engraving_value%", engraving_index);
                        combo_box(temp_c_string(cb_label), negative_engraving_names, cast(*s32)*current_preset.negative_engraving_points[engraving_index].type);
                        if ImGui.InputScalar(temp_c_string(input_label), DType.U8, *current_preset.negative_engraving_points[engraving_index].value, *step)
                        {
                            set_unsaved();
                        }
                    }
                } 
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