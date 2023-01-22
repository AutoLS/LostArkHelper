#load "imgui_sdl_gl.jai";
IMGUI_WINDOW_FLAGS :: ImGui.WindowFlags;
IMGUI_INPUT_TEXT_FLAGS :: ImGui.InputTextFlags;
TAB_BAR_FLAGS :: ImGui.TabBarFlags;
TAB_ITEM_FLAGS :: ImGui.TabItemFlags;
TABLE_FLAGS :: ImGui.TableFlags;
TABLE_COLUMN_FLAGS :: ImGui.TableColumnFlags;
TABLE_ROW_FLAGS :: ImGui.TableRowFlags;
DType :: ImGui.DataType;
STYLE_VAR :: ImGui.StyleVar;


label :: (text: string)
{
    ImGui.Text(text);
    ImGui.SameLine();
}

reset_checklist :: (data: *bool, count: int)
{
    for index: 0 .. count-1
    {
        data[index] = false;
    }
}

checkall_checklist :: (data: *bool, count: int)
{
    for index: 0 .. count-1
    {
        data[index] = true;
    }
}

check_list :: (name: string, items: [] string, data: *bool) -> bool
{
    changed := false;
    ImGui.Text(name);
    if ImGui.Button("Check all")
    {
        changed = true;
        checkall_checklist(data, items.count);
    }
    ImGui.SameLine();
    if ImGui.Button("Reset")
    {
        changed = true;
        reset_checklist(data, items.count);
    }
    for items
    {
        if ImGui.Checkbox(temp_c_string(it), *data[it_index])
        {
            changed = true;
        }
    }

    return changed;
}

combo_box :: (label: *u8, items: [] *u8, selected: *s32)
{
    if ImGui.BeginCombo(label, items[<< selected])
    {
        defer ImGui.EndCombo();
        for items
        {
            is_selected := << selected == it_index;
            if ImGui.Selectable(it, is_selected) then << selected = xx it_index;

            if is_selected then ImGui.SetItemDefaultFocus();
        }
    }
}
