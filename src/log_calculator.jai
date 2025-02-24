Log_Calculator_Data :: struct
{
    normal_mat: s32;
    uncommon_mat: s32;
    rare_mat: s32;

    n: s32;
    np_exchange: s32;
    up_exchange: s32;

    status: Status_Code = .NONE;
}

update_log_calculator :: ()
{
    using lost_ark_helper.log_calculator_data;

    ImGui.Text("Log Convert Calculator");
    ImGui.PushItemWidth(150);
    ImGui.InputInt("Normal Material", *normal_mat);
    ImGui.InputInt("Uncommon Material", *uncommon_mat);
    ImGui.InputInt("Rare Material", *rare_mat);
    ImGui.PopItemWidth();

    if ImGui.Button("Calculate") 
    {
        n = 0;
        while normal_mat >= 86 * n && uncommon_mat >= 45 * n
        {
            shortfall: s32 = xx max(0, 33 * n - rare_mat);
            powder_needed: s32 = shortfall * 10;

            np: s32 = (normal_mat - 86 * n) / 100 * 80;
            up: s32 = (uncommon_mat - 45 * n) / 50 * 80;
            powder_available :=  np + up;
            
            if powder_available < powder_needed 
            {
                n -= 1;
                break;
            }

            n += 1;
        }

        np_exchange = (normal_mat - (86 * n)) / 100;
        up_exchange = (uncommon_mat - (45 * n)) / 50;

        status = .OK;
    }

    if status == .OK 
    {
        ImGui.Text("Maximum craftable: % Abidos", n * 10);
        ImGui.Text("# of Powder exchange for normal log: %x", np_exchange);
        ImGui.Text("# of Powder exchange for uncommon log: %x", up_exchange);
    }

}