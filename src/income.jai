ilv_breakpoints := float.[1340, 1370, 1385, 1400, 1415, 1430, 1445, 1460, 1475, 1490, 1520, 1540, 1550, 1560];
RAID_LIST_STRINGS := string.["Oreha's Well", "Argos", "Valtan N", "Valtan H", "Vykas N", "Vykas H", "Kakul-Saydon", "Brelshaza"];
MATERIAL_LIST_STRINGS := string.["Guardian Stones", "Destroyer Stones", "Leapstones", "Greater Leapstones", "Protection Stones", "Obliteration Stones", "Marvelous Leapstones"];

Material :: enum u32
{
    blue;
    red;
    leapstone;
    greater_leapstone;
    protection_stone;
    obliteration_stone;
    marvelous_leapstone;
}

MATERIAL_COUNT :: #run enum_highest_value(Material)+1;

Income_Menu :: struct
{
    materials_prices: [MATERIAL_COUNT] float;
    materials_storage: Table(string, [ilv_breakpoints.count] int);
    raid_gold_income: [RAID_LIST_STRINGS.count] float;
    total_material_daily_gold: float;
    total_raid_gold: float;
}

init_income_menu_settings :: ()
{
    using lost_ark_helper.income_menu;
    using lost_ark_helper.character_page;

    //TODO Use enums?
    raid_gold_income[0] = 2100;
    raid_gold_income[1] = 2700;
    raid_gold_income[2] = 3500;
    raid_gold_income[3] = 4500;
    raid_gold_income[4] = 3300;
    raid_gold_income[5] = 4500;
    raid_gold_income[6] = 4500;
    raid_gold_income[7] = 6000;

    materials_prices[0] = 0.2;
    materials_prices[1] = 0.8;
    materials_prices[2] = 20;
    materials_prices[3] = 30;
    materials_prices[Material.protection_stone] = 0.3;
    materials_prices[Material.obliteration_stone] = 0.8;
    materials_prices[Material.marvelous_leapstone] = 135;

    table_add(*materials_storage, "Guardian Stones", int.[400, 500, 550, 600, 650, 700, 750, 800, 850, 0, 0, 0, 0, 0]);
    table_add(*materials_storage, "Protection Stones", int.[0, 0, 0, 0, 0, 0, 0, 0, 0, 500, 700, 750, 750, 800]);
    table_add(*materials_storage, "Destroyer Stones", int.[133, 167, 183, 200, 217, 233, 250, 267, 300, 0, 0, 0, 0, 0]);
    table_add(*materials_storage, "Obliteration Stones", int.[0, 0, 0, 0, 0, 0, 0, 0, 0, 250, 300, 320, 320, 350]);
    table_add(*materials_storage, "Leapstones", int.[7, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]);
    table_add(*materials_storage, "Greater Leapstones", int.[0, 6, 6, 6, 10, 10, 10, 14, 14, 0, 0, 0, 0, 0]);
    table_add(*materials_storage, "Marvelous Leapstones", int.[0, 0, 0, 0, 0, 0, 0, 0, 0, 10, 10, 14, 14, 14]);
}

update_total_income :: ()
{
    using lost_ark_helper.income_menu;

    total_material_daily_gold = 0;
    total_raid_gold = 0;
    for c, c_index : lost_ark_helper.character_page.characters
    {
        ilv_index := get_ilv_breakpoint_index(c.item_level);
        if ilv_index >= 0
        {
            for materials_prices
            {
                material, found := table_find(*materials_storage, MATERIAL_LIST_STRINGS[it_index]);
                if found then total_material_daily_gold += material[ilv_index] * it;
            }
            for raid: 0 .. RAID_LIST_STRINGS.count-1
            {
                if c.is_designated
                {
                    total_raid_gold += get_raid_income(raid, c.item_level, false);
                }
            }
        }
    }
}

get_ilv_breakpoint_index :: (item_level: float) -> int
{
    ilv_index: int = -1;
    for < ilv_breakpoints
    {
        if item_level >= it
        {
            ilv_index = it_index;
            break;
        }
    }

    return ilv_index;
}

get_raid_income :: (raid_index: int, ilv: float, box: bool) -> float
{
    using lost_ark_helper.income_menu;
    raid := RAID_LIST_STRINGS[raid_index];
    if raid == 
    {
        case "Oreha's Well";
        {
            if ilv >= 1370 && ilv < 1415 then return raid_gold_income[raid_index]; else return 0;
        }
        case "Argos";
        {
            if ilv >= 1370 && ilv < 1475 then return raid_gold_income[raid_index]; else return 0;
        }
        case "Valtan N";
        {
            if ilv >= 1415 && ilv < 1445 then return raid_gold_income[raid_index]; else return 0;
        }
        case "Valtan H";
        {
            if ilv >= 1445 then return raid_gold_income[raid_index]; else return 0;
        }
        case "Vykas N";
        {
            if ilv >= 1430 && ilv < 1460 then return raid_gold_income[raid_index]; else return 0;
        }
        case "Vykas H";
        {
            if ilv >= 1460 then return raid_gold_income[raid_index]; else return 0;
        }
        case "Kakul-Saydon";
        {
            if ilv >= 1475 then return raid_gold_income[raid_index]; else return 0;
        }
        case "Brelshaza";
        {
            if ilv >= 1490 then return raid_gold_income[raid_index]; else return 0;
        }
        case;
            return 0;
    }
}

update_settings_tab :: ()
{
    using lost_ark_helper.income_menu;
    if (ImGui.BeginTabItem("Settings"))
    {
        flags := TABLE_FLAGS.Borders | TABLE_FLAGS.RowBg;
        text_height := ImGui.GetTextLineHeightWithSpacing();
        if ImGui.BeginTable("Settings_Table", 2, flags, make_ImVec2(400, 224)) 
        {
            defer ImGui.EndTable();

            ImGui.TableSetupColumn("Items", TABLE_COLUMN_FLAGS.DefaultSort);
            ImGui.TableSetupColumn("Prices (Per one of)", TABLE_COLUMN_FLAGS.DefaultSort);
            ImGui.TableHeadersRow();

            column_type := Type.[string, float];

            for material, material_index : MATERIAL_LIST_STRINGS
            {
                ImGui.TableNextRow();
                for type, type_index : column_type
                {
                    ImGui.TableSetColumnIndex(xx type_index);
                    if type == string
                    {
                        ImGui.Text(material);
                    }

                    if type == float
                    {
                        cell: s32 = cast(s32)(material_index * type_index);
                        ImGui.PushID(cell);
                        if ImGui.InputFloat("##cell", *materials_prices[material_index], 0.1, 1.0, "%.1f") then set_unsaved();
                        ImGui.PopID();
                    }
                }
            }
        }
        ImGui.SameLine();
        if ImGui.BeginTable("Materials_Count_Table", MATERIAL_LIST_STRINGS.count + 1, TABLE_FLAGS.SizingFixedFit | TABLE_FLAGS.Resizable | TABLE_FLAGS.Hideable | TABLE_FLAGS.BordersOuter | TABLE_FLAGS.ScrollX | TABLE_FLAGS.ScrollY | flags, make_ImVec2(0, 300))
        {
            defer ImGui.EndTable();

            ImGui.TableSetupColumn("Item Level");
            for MATERIAL_LIST_STRINGS
            {
                ImGui.TableSetupColumn(temp_c_string(it), TABLE_COLUMN_FLAGS.DefaultSort);
            }
            ImGui.TableHeadersRow();

            for ilv, row_index: ilv_breakpoints
            {
                ImGui.TableNextRow();

                ImGui.TableSetColumnIndex(0);
                ImGui.Text(tprint("%", ilv));

                for col, col_index: MATERIAL_LIST_STRINGS
                {
                    material := table_find_pointer(*materials_storage, col);
                    if material 
                    {
                        col_count := MATERIAL_LIST_STRINGS.count + 1;
                        ImGui.TableSetColumnIndex(xx (col_index+1));
                        cell: s32 = cast(s32)(row_index * col_count + col_index);
                        mat_input: s32 = xx material.data[row_index];
                        ImGui.PushID(cell);
                        if ImGui.InputInt("##cell", *mat_input) 
                        {
                            set_unsaved();
                            material.data[row_index] = xx mat_input;
                        }
                        ImGui.PopID();
                    }
                }
            }
        }
        ImGui.NewLine();
        /* if ImGui.BeginTable("Raid_Gold_Settings_Table", 2, flags, make_ImVec2(400, 224))
        {
            defer ImGui.EndTable();

            ImGui.TableSetupColumn("Raids", TABLE_COLUMN_FLAGS.DefaultSort);
            ImGui.TableSetupColumn("Gold", TABLE_COLUMN_FLAGS.DefaultSort);
            ImGui.TableHeadersRow();

            column_type := Type.[string, float];

            for raid, raid_index : RAID_LIST_STRINGS
            {
                ImGui.TableNextRow();
                for type, type_index : column_type
                {
                    ImGui.TableSetColumnIndex(xx type_index);
                    if type == string
                    {
                        ImGui.Text(raid);
                    }

                    if type == float
                    {
                        cell: s32 = cast(s32)(raid_index * type_index);
                        ImGui.PushID(cell);
                        if ImGui.InputFloat("##cell", *raid_gold_income[raid_index], 0.1, 1.0, "%.1f") then set_unsaved();
                        ImGui.PopID();
                    }
                }
            }
        }
        */
        ImGui.SameLine();
        if ImGui.BeginChild("Designated Characters Checklist", make_ImVec2(300, 200))
        {
            ImGui.Text("Designated characters (up to 6)");
            for *lost_ark_helper.character_page.characters
            {
                if ImGui.Checkbox(it.name, *it.is_designated)
                {
                    set_unsaved();
                    designated_count := get_designated_count(*lost_ark_helper.character_page);
                    if it.is_designated && designated_count > 6
                    {
                        it.is_designated = false;
                    }
                }
            }
        }
        ImGui.EndChild();
        ImGui.EndTabItem();
    }
}

update_materials_income_tab :: ()
{
    using lost_ark_helper.income_menu;
    if (ImGui.BeginTabItem("Materials income"))
    {
        flags := TABLE_FLAGS.Borders | TABLE_FLAGS.RowBg;
        materials_total: [MATERIAL_LIST_STRINGS.count] float;

        if ImGui.BeginTable("MaterialsIncomeTable", MATERIAL_LIST_STRINGS.count+2, flags)
        {
            defer ImGui.EndTable();
            ImGui.TableSetupColumn("Character");
            ImGui.TableSetupColumn("Item Level");
            for MATERIAL_LIST_STRINGS 
            {
                ImGui.TableSetupColumn(temp_c_string(it), TABLE_COLUMN_FLAGS.DefaultSort);
            }
            ImGui.TableHeadersRow();

            using lost_ark_helper.character_page;
            for c, c_index : characters
            {
                ImGui.TableNextRow(TABLE_ROW_FLAGS.None, 24);

                ilv_index := get_ilv_breakpoint_index(c.item_level);

                ImGui.TableSetColumnIndex(0);
                ImGui.Text(to_string(c.name));
                
                ImGui.TableSetColumnIndex(1);
                ImGui.Text(tprint("%", c.item_level));

                for column, column_index : MATERIAL_LIST_STRINGS
                {
                    ImGui.TableSetColumnIndex(xx (column_index+2));

                    material, found := table_find(*materials_storage, column);

                    if found 
                    {
                        mat_count := 
                        ifx ilv_index >= 0
                        then material[ilv_index] 
                        else 0;
                        
                        ImGui.Text(tprint("%", mat_count));
                        materials_total[column_index] += mat_count;
                    }
                    else
                    {
                        ImGui.Text("0");
                    }
                }
            }

            ImGui.TableNextRow(TABLE_ROW_FLAGS.None, 24);
            ImGui.TableNextRow(TABLE_ROW_FLAGS.None, 24);
            ImGui.TableSetColumnIndex(1);
            ImGui.Text("Total per day");
            total_row_column_index: s32 = 2;
            for materials_total
            {
                ImGui.TableSetColumnIndex(total_row_column_index);
                ImGui.Text("%", it);
                total_row_column_index += 1;
            }
            ImGui.TableNextRow(TABLE_ROW_FLAGS.None, 24);
            ImGui.TableSetColumnIndex(1);
            ImGui.Text("Total per week");
            total_row_column_index = 2;
            for materials_total
            {
                ImGui.TableSetColumnIndex(total_row_column_index);
                ImGui.Text("%", it * 7);
                total_row_column_index += 1;
            }
            ImGui.TableNextRow(TABLE_ROW_FLAGS.None, 24);
            ImGui.TableSetColumnIndex(1);
            ImGui.Text("Daily gold income");
            total_row_column_index = 2;
            total_material_daily_gold = 0;
            for materials_total
            {
                gold := it * materials_prices[it_index];
                ImGui.TableSetColumnIndex(total_row_column_index);
                ImGui.Text("%g", round_real_to_int(gold));
                total_material_daily_gold += gold;
                total_row_column_index += 1;
            }
            ImGui.TableNextRow(TABLE_ROW_FLAGS.None, 24);
            ImGui.TableSetColumnIndex(1);
            ImGui.Text("Weekly gold income");
            total_row_column_index = 2;
            for materials_total
            {
                gold := it * materials_prices[it_index];
                ImGui.TableSetColumnIndex(total_row_column_index);
                ImGui.Text("%g", round_real_to_int(gold) * 7);
                total_row_column_index += 1;
            }
        }
        ImGui.EndTabItem();
    }
}

update_raids_income_tab :: ()
{
    using lost_ark_helper.income_menu;
    using lost_ark_helper.raids_settings;
    using lost_ark_helper.character_page;
    if (ImGui.BeginTabItem("Raids income"))
    {
        flags := TABLE_FLAGS.Borders | TABLE_FLAGS.RowBg | TABLE_FLAGS.SizingFixedSame | TABLE_FLAGS.ScrollX | TABLE_FLAGS.ScrollY;
        designated_count := get_designated_count(*lost_ark_helper.character_page);
        n_columns: s32 = xx (1 + designated_count);
        if ImGui.BeginTable("RaidsIncomeTable", n_columns, flags)
        {
            defer ImGui.EndTable();

            column_headers: [..] string;
            column_headers.allocator = temp;
            array_add(*column_headers, "Source");
            for characters
            {
                if it.is_designated then array_add(*column_headers, tprint("% [%]", to_string(it.name), it.item_level));
            }

            for column_headers 
            {
                ImGui.TableSetupColumn(temp_c_string(it), TABLE_COLUMN_FLAGS.DefaultSort);
            }
            ImGui.TableHeadersRow();
            ImGui.TableNextRow();
            checkbox_id: s32 = 0;
            row_index := 0;
            total_raid_income: [..] int;
            total_raid_income.allocator = temp;
            array_resize(*total_raid_income, designated_count);
            for raid, raid_index : raids
            {
                for gate, gate_index : raid.gate_info
                {
                    column_index: s32 = 0;
                    ImGui.TableSetColumnIndex(column_index);
                    ImGui.Text(tprint("% Gate % - (%g)", raid.name, gate_index + 1, gate.gold_income));
                    for c, c_index : characters
                    {
                        if c.is_designated
                        {
                            column_index += 1;
                            ImGui.TableSetColumnIndex(column_index);
                            if c.item_level >= xx gate.ilv_requirement
                            {
                                total_raid_income[column_index-1] += gate.gold_income;
                                label := temp_c_string(tprint("box? - (%g)##%", gate.chest_cost, checkbox_id));
                                if ImGui.Checkbox(label, *c.is_purchasing_box[row_index]) then set_unsaved();
                                if c.is_purchasing_box[row_index]
                                {
                                    total_raid_income[column_index-1] -= gate.chest_cost;
                                }
                            }
                            checkbox_id += 1;
                        }
                    }
                    row_index += 1;
                    if raid_index == raids.count-1 && gate_index == raid.gate_info.count-1
                    then ImGui.TableNextRow(TABLE_ROW_FLAGS.None, 24);
                    else ImGui.TableNextRow();
                }
            }

            ImGui.TableNextRow(TABLE_ROW_FLAGS.None, 24);
            ImGui.TableSetColumnIndex(0);
            ImGui.Text("Total");

            for 1 .. n_columns-1 
            {
                ImGui.TableSetColumnIndex(it);
                ImGui.Text(tprint("%g", total_raid_income[it-1]));
            }
        }
        ImGui.EndTabItem();
    }
}

update_total_income_tab :: ()
{
    using lost_ark_helper.income_menu;
    if (ImGui.BeginTabItem("Total income"))
    {
        update_total_income();
        rounded_mat_daily_gold := round_real_to_int(total_material_daily_gold);
        ImGui.Text("Total daily gold from mats      ~= %g", rounded_mat_daily_gold);
        ImGui.Text("Total weekly gold from mats     ~= %g", rounded_mat_daily_gold * 7);
        ImGui.Text("Total weekly gold from raids    ~= %g", cast(int)total_raid_gold);
        ImGui.Text("Total gold per week             ~= %g", cast(int)total_raid_gold + (rounded_mat_daily_gold * 7));

        ImGui.EndTabItem();
    }
}

update_income_menu :: ()
{
    using lost_ark_helper.income_menu;
    if (ImGui.BeginTabBar("Income_Tables", TAB_BAR_FLAGS.Reorderable)) 
    {
        update_settings_tab();
        update_materials_income_tab();
        update_raids_income_tab();
        update_total_income_tab();
        
        ImGui.EndTabBar();
    }
}