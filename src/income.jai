ilv_breakpoints := float.[1340, 1370, 1385, 1400, 1415, 1430, 1445, 1460, 1475, 1490, 1520, 1540, 1550, 1560];
RAID_LIST_STRINGS := string.["Oreha's Well", "Argos", "Valtan N", "Valtan H", "Vykas N", "Vykas H", "Kakul-Saydon", "Brelshaza"];
MATERIAL_LIST_STRINGS := string.["Crystallized Guardian Stone", "Crystallized Destruction Stone", "Honor Leapstone", "Great Honor Leapstone", "Protection Stone", "Obliteration Stone", "Marvelous Honor Leapstone"];

HONING_MATS_URL := "https://www.lostarkmarket.online/api/export-market-live/North%20America%20East?category=Enhancement%20Material&subcategory=Honing%20Materials";
ADDITIONAL_HONING_MATS_URL := "https://www.lostarkmarket.online/api/export-market-live/North%20America%20East?category=Enhancement%20Material&subcategory=Additional%20Honing%20Materials";

Item_Category :: enum u32
{
    honing_materials;
    additional_honing_materials;
}

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
    selected_category: s32;
    items_data: [#run enum_highest_value(Item_Category)+1][..] Market_Item;
    items_prices: [#run enum_highest_value(Item_Category)+1] Table(string, float);
    items_texture: Table(string, u32);
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

    table_add(*materials_storage, "Crystallized Guardian Stone", int.[400, 500, 550, 600, 650, 700, 750, 800, 850, 0, 0, 0, 0, 0]);
    table_add(*materials_storage, "Protection Stone", int.[0, 0, 0, 0, 0, 0, 0, 0, 0, 500, 700, 750, 750, 800]);
    table_add(*materials_storage, "Crystallized Destruction Stone", int.[133, 167, 183, 200, 217, 233, 250, 267, 300, 0, 0, 0, 0, 0]);
    table_add(*materials_storage, "Obliteration Stone", int.[0, 0, 0, 0, 0, 0, 0, 0, 0, 250, 300, 320, 320, 350]);
    table_add(*materials_storage, "Honor Leapstone", int.[7, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]);
    table_add(*materials_storage, "Great Honor Leapstone", int.[0, 6, 6, 6, 10, 10, 10, 14, 14, 0, 0, 0, 0, 0]);
    table_add(*materials_storage, "Marvelous Honor Leapstone", int.[0, 0, 0, 0, 0, 0, 0, 0, 0, 10, 10, 14, 14, 14]);

    get_items_live_data();
    download_and_load_necessary_images(*lost_ark_helper.income_menu, Item_Category.honing_materials);
    download_and_load_necessary_images(*lost_ark_helper.income_menu, Item_Category.additional_honing_materials);
}

download_and_load_necessary_images :: (using income_menu: *Income_Menu, category: Item_Category)
{
    for items_data[category]
    {
        texture_path := tprint("ast/%.png", it.id);
        if !file_exists(texture_path)
        {
            print("URL: %\n", it.image);
            ok, res := curl_get(it.image);
            if ok
            {
                write_entire_file(tprint("ast/%.webp", it.id), res);
                print("Downloaded %.webp successfully\n", it.id);
            }
        }
        else
        {
            table_add(*items_texture, it.name, gl_load_texture(temp_c_string(texture_path), true));
        }
    }
}

get_items_live_data :: ()
{
    using lost_ark_helper.income_menu;
    ok, res := curl_get(HONING_MATS_URL);
    if ok
    {
        parse_items_live_data(res, *items_prices[Item_Category.honing_materials], Item_Category.honing_materials);
    }

    ok, res = curl_get(ADDITIONAL_HONING_MATS_URL);
    if ok
    {
        parse_items_live_data(res, *items_prices[Item_Category.additional_honing_materials], Item_Category.additional_honing_materials);
    }
}

parse_items_live_data :: (json_str: string, table: *Table(string, float), category: Item_Category)
{
    using lost_ark_helper.income_menu;
    items, ok, err := JSON.from_json_string([..] Market_Item, json_str);
    if ok  
    {
        items_data[category] = items;
        for items_data[category]
        {
            table_set(table, it.name, xx it.low_price);
        }
    }
    else print("err: %\n", err);

    // success, result := json_parse_string(json_str);
    // if success
    // {
    //     if result.type == .ARRAY
    //     {
    //         for result.array 
    //         {
    //             name := json_get(it, "name", .STRING).str;
    //             price := json_get(it, "lowPrice", .NUMBER).number;

    //             table_set(table, name, xx price);
    //         }
    //     }
    // }
}

update_total_income :: ()
{
    using lost_ark_helper.income_menu;
    using lost_ark_helper.raids_settings;

    total_material_daily_gold = 0;
    total_raid_gold = 0;
    for c, c_index : lost_ark_helper.character_page.characters
    {
        ilv_index := get_ilv_breakpoint_index(c.item_level);
        if ilv_index >= 0
        {
            for MATERIAL_LIST_STRINGS
            {
                mat_price: float;
                found: bool;
                mat_price, found = table_find(*items_prices[Item_Category.honing_materials], it);
                if !found then mat_price, found = table_find(*items_prices[Item_Category.additional_honing_materials], it);

                material, ok := table_find(*materials_storage, it);
                if ok 
                {
                    if it == 
                    {
                        case "Crystallized Guardian Stone"; #through;
                        case "Crystallized Destruction Stone"; #through;
                        case "Protection Stone"; #through;
                        case "Obliteration Stone";
                        {
                            mat_price /= 10;
                        }
                    }
                    total_material_daily_gold += material[ilv_index] * mat_price;
                }
            }
        }
        if c.is_designated
        {
            index := 0;
            for raid, raid_index : raids
            {
                for gate, gate_index : raid.gate_info
                {
                    if c.item_level >= xx gate.ilv_requirement && !c.is_skipping[index]
                    {
                        total_raid_gold += gate.gold_income;
                        if c.is_purchasing_box[index] 
                        {
                            total_raid_gold -= gate.chest_cost;
                        }
                    }
                    index += 1;
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
        if ImGui.BeginChild("Item Prices", make_ImVec2(400, 300))
        {
            if ImGui.Button("Refresh")
            {
                get_items_live_data();
            }
            ImGui.SameLine();
            category_str := *u8.["Honing Materials", "Additional Honing Materials"];
            combo_box("Category", category_str, *selected_category);
            if ImGui.BeginTable("Settings_Table", 2, flags | TABLE_FLAGS.ScrollX | TABLE_FLAGS.ScrollY, make_ImVec2(400, 0)) 
            {
                defer ImGui.EndTable();

                ImGui.TableSetupScrollFreeze(1, 1);

                ImGui.TableSetupColumn("Items", TABLE_COLUMN_FLAGS.DefaultSort);
                ImGui.TableSetupColumn("Prices", TABLE_COLUMN_FLAGS.DefaultSort);
                ImGui.TableHeadersRow();

                for items_prices[selected_category]
                {
                    name, price := it_index, it;

                    ImGui.TableNextRow(TABLE_ROW_FLAGS.None, 24);

                    ImGui.TableSetColumnIndex(0);
                    texture, ok := table_find(*items_texture, name);
                    if ok
                    {
                        ImGui.Image(cast(*void)texture, make_ImVec2(32, 32));
                    }

                    ImGui.Text(name);

                    ImGui.TableSetColumnIndex(1);
                    ImGui.Text(tprint("%g", price));
                }
/*
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
*/
            }
        }
        ImGui.EndChild();
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
        flags := TABLE_FLAGS.Borders | TABLE_FLAGS.RowBg | TABLE_FLAGS.ScrollX | TABLE_FLAGS.ScrollY;
        materials_total: [MATERIAL_LIST_STRINGS.count] float;

        if ImGui.BeginTable("MaterialsIncomeTable", MATERIAL_LIST_STRINGS.count+2, flags)
        {
            defer ImGui.EndTable();

            ImGui.TableSetupScrollFreeze(2, 1);
            
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
                ImGui.TableNextRow(TABLE_ROW_FLAGS.None);

                ilv_index := get_ilv_breakpoint_index(c.item_level);

                ImGui.TableSetColumnIndex(0);
                ImGui.Text(to_string(c.name));
                
                ImGui.TableSetColumnIndex(1);
                ImGui.Text(tprint("%", c.item_level));

                for MATERIAL_LIST_STRINGS
                {
                    ImGui.TableSetColumnIndex(xx (it_index+2));
                    material, found := table_find(*materials_storage, it);

                    if found
                    {
                        mat_count := 
                        ifx ilv_index >= 0
                        then material[ilv_index] 
                        else 0;

                        ImGui.Text(tprint("%", mat_count));
                        materials_total[it_index] += mat_count;
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
            daily_gold: [MATERIAL_LIST_STRINGS.count] float;
            for materials_total
            {
                mat_price: float;
                found: bool;
                mat_price, found = table_find(*items_prices[Item_Category.honing_materials], MATERIAL_LIST_STRINGS[it_index]);
                if !found then mat_price, found = table_find(*items_prices[Item_Category.additional_honing_materials], MATERIAL_LIST_STRINGS[it_index]);

                ImGui.TableSetColumnIndex(total_row_column_index);
                if found 
                {
                    if MATERIAL_LIST_STRINGS[it_index] == 
                    {
                        case "Crystallized Guardian Stone"; #through;
                        case "Crystallized Destruction Stone"; #through;
                        case "Protection Stone"; #through;
                        case "Obliteration Stone";
                        {
                            mat_price /= 10;
                        }
                    }
                    gold := it * mat_price;
                    ImGui.Text("%g", round_real_to_int(gold));
                    daily_gold[it_index] = gold;
                    total_material_daily_gold += gold;
                }
                
                total_row_column_index += 1;
            }

            ImGui.TableNextRow(TABLE_ROW_FLAGS.None, 24);
            ImGui.TableSetColumnIndex(1);
            ImGui.Text("Weekly gold income");
            total_row_column_index = 2;
            for MATERIAL_LIST_STRINGS
            {
                ImGui.TableSetColumnIndex(total_row_column_index);
                ImGui.Text("%g", round_real_to_int(daily_gold[it_index]) * 7);
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

            ImGui.TableSetupScrollFreeze(1, 1);
            for column_headers 
            {
                ImGui.TableSetupColumn(temp_c_string(it), TABLE_COLUMN_FLAGS.DefaultSort);
            }
            ImGui.TableHeadersRow();
            ImGui.TableNextRow();
            checkbox_id: s32 = 0;
            row_index := 0;
            total_raid_gold = 0;
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
                                buy_chest_label := temp_c_string(tprint("box? - (%g)##%", gate.chest_cost, checkbox_id));
                                is_skipping_label := temp_c_string(tprint("skip?##%", checkbox_id));
                                if ImGui.Checkbox(buy_chest_label, *c.is_purchasing_box[row_index]) then set_unsaved();
                                ImGui.SameLine();
                                if ImGui.Checkbox(is_skipping_label, *c.is_skipping[row_index]) then set_unsaved();

                                if !c.is_skipping[row_index]
                                {
                                    total_raid_income[column_index-1] += gate.gold_income;
                                    if c.is_purchasing_box[row_index]
                                    {
                                        total_raid_income[column_index-1] -= gate.chest_cost;
                                    }
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
                total_raid_gold += total_raid_income[it-1];
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