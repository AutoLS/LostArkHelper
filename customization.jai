Customization_Converter_Status :: enum u32
{
    NONE;
    OK;
    ERR;
}

Customization_Converter_Data :: struct 
{
    file_name_ptr: *u8;
    file_name: string;
    file_data: string;
    opened: bool;
    loaded: bool;
    status: Customization_Converter_Status = .NONE;
}

update_customization_converter_menu :: (using cus_converter_data: *Customization_Converter_Data)
{
    ImGui.Text("Open customization(.cus) file to convert. Currently only supports KR > Global");
    if ImGui.Button("Open..")
    {
        file_dialogue := get_open_file_name("Customization files (*.cus)\0*.cus\0\0", "cus", file_name_ptr);

        if GetOpenFileNameA(*file_dialogue)
        {
            status = .NONE;
            loaded = false;
            opened = true;
            file_name = to_string(file_dialogue.lpstrFile, file_dialogue.nMaxFile);
        }
    }

    if opened && !loaded
    {
        file_data, loaded = read_entire_file(file_name);
    }

    if loaded 
    {
        ImGui.SameLine();
        ImGui.Text(file_name);
        if ImGui.Button("Convert")
        {
            converted, occurrence := replace(file_data, "KOR", "USA");
            if occurrence == 1
            {
                write_entire_file(file_name, converted);
                status = .OK;
            }
            else
            {
                status = .ERR;
            }
        }
    }

    if status == 
    {
        case .OK; ImGui.Text("Successfully converted customization preset file.");
        case .ERR; ImGui.Text("ERROR: Cannot convert customization preset file.");
    }
}