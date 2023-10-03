Gate_Info :: struct
{
    gold_income: s32;
    chest_cost: s32;
    ilv_requirement: s32;
}

Raid :: struct 
{
    name: string;
    n_gates: s32;
    gate_info: [..] Gate_Info;
}

Raids_Settings_Menu :: struct 
{
    raids: [..] Raid;
    template: Raid;
    template_name: *u8;
    selected_raid: s32;
    total_gates: s32;
}

get_total_gates :: (raids: [..] Raid) -> s32
{
    n: s32;
    for raids { n += it.n_gates; }
    return n;
}

add_new_gate :: (using raid: *Raid)
{
    new_gate: Gate_Info;
    array_add(*gate_info, new_gate);
    n_gates += 1;
}

remove_gate :: (using raid: *Raid, index: int)
{
    if gate_info.count > 0
    {
        array_ordered_remove_by_index(*gate_info, index);
        n_gates -= 1;
    }
}

update_raids_settings_menu :: ()
{
    using lost_ark_helper.raids_settings;
    if ImGui.Button("Create New")
    {
        if template_name
        {
            free(template_name);
        }
        template_name = alloc(32);
        memset(template_name, 0, 32);

        ImGui.OpenPopup("Create New Raid");
    }

    if ImGui.BeginPopupModal("Create New Raid", null, IMGUI_WINDOW_FLAGS.AlwaysAutoResize)
    {
        if ImGui.BeginChild("CreateNewRaid", make_ImVec2(400, 400))
        {
            ImGui.InputText("Name", template_name, 32);
            ImGui.InputInt("Gates Count", *template.n_gates, 0);

            if (template.n_gates > template.gate_info.count)
            {
                array_reset(*template.gate_info);
                array_resize(*template.gate_info, template.n_gates);
            }
            ImGui.NewLine();
            for gate : 0 .. template.n_gates-1
            {
                gold_label := temp_c_string(tprint("Gold##%", gate));
                chest_label := temp_c_string(tprint("Chest Cost##%", gate));
                ilv_label := temp_c_string(tprint("Ilv Requirement##%", gate));
                ImGui.Text(tprint("Gate %", gate+1));
                ImGui.InputInt(gold_label, *template.gate_info[gate].gold_income);
                ImGui.InputInt(chest_label, *template.gate_info[gate].chest_cost);
                ImGui.InputInt(ilv_label, *template.gate_info[gate].ilv_requirement);
            }

            if ImGui.Button("Create")
            {
                template.name = copy_string(to_string(template_name));
                array_add(*raids, template);
                total_gates += template.n_gates;
                for lost_ark_helper.character_page.characters
                {
                    array_resize(*it.is_purchasing_box, total_gates);
                    array_resize(*it.is_skipping, total_gates);
                }
                selected_raid = xx (raids.count-1);
                set_unsaved();
                template = .{};
                ImGui.CloseCurrentPopup();
            }
            ImGui.SameLine();
            if ImGui.Button("Cancel")
            {
                template = .{};
                ImGui.CloseCurrentPopup();
            }

            ImGui.EndChild();
        }

        ImGui.EndPopup();
    }

    if raids.count == 0
    {
        ImGui.Text("There is no raid added at the moment, click the create new button to create a raid.");
    }
    else 
    {
        raid_names: [..] *u8;
        raid_names.allocator = temp;

        for raids array_add(*raid_names, temp_c_string(it.name));

        ImGui.SameLine();
        ImGui.SetNextItemWidth(150);
        combo_box("Raids Select", raid_names, *selected_raid);

        if ImGui.Button("Add gate")
        {
            add_new_gate(*raids[selected_raid]);
        }

        for raids[selected_raid].gate_info
        {
            gold_label := temp_c_string(tprint("Gold##%", it_index));
            chest_label := temp_c_string(tprint("Chest Cost##%", it_index));
            ilv_label := temp_c_string(tprint("Ilv Requirement##%", it_index));
            ImGui.Text(tprint("Gate %", it_index+1));
            ImGui.PushItemWidth(200);
            ImGui.InputInt(gold_label, *it.gold_income);
            ImGui.InputInt(chest_label, *it.chest_cost);
            ImGui.InputInt(ilv_label, *it.ilv_requirement);
            ImGui.PopItemWidth();
            remove_label := temp_c_string(tprint("Remove##%_%", raid_names[selected_raid], it_index));
            if ImGui.Button(remove_label)
            {
                remove_gate(*raids[selected_raid], it_index);
            }
        }
    }
}