Profit_Calculator_Data :: struct 
{
    timber_price: s32;
    tender_timber_price: s32;
    abidos_timber_price: s32;
    abidos_price: s32;

    total_crafting_cost_reduction: s32;
}

Log_Calculator_Data :: struct
{
    profit_calculator_data: Profit_Calculator_Data;

    normal_mat: s32;
    uncommon_mat: s32;
    rare_mat: s32;

    n: s32;
    u_n_exchange: s32;
    np_exchange: s32;
    up_exchange: s32;

    pu: s32;
    pr: s32;
    total_powder: s32;

    status: Status_Code = .NONE;
}

update_log_calculator :: ()
{
    using lost_ark_helper.log_calculator_data;
    using lost_ark_helper.log_calculator_data.profit_calculator_data;

    ImGui.Text("Profit calculator settings");
    ImGui.PushItemWidth(150);
    if ImGui.InputInt("Timber price", *timber_price) set_unsaved();
    if ImGui.InputInt("Tender Timber price", *tender_timber_price) set_unsaved();
    if ImGui.InputInt("Abidos Timber price", *abidos_timber_price) set_unsaved();
    if ImGui.InputInt("Abidos prices", *abidos_price) set_unsaved();
    if ImGui.InputInt("Total crafting cost reduction", *total_crafting_cost_reduction)
    {
        total_crafting_cost_reduction = abs(total_crafting_cost_reduction);
        set_unsaved();
    }
    ImGui.PopItemWidth();

    ImGui.NewLine();
    ImGui.Text("Log Convert Calculator");
    ImGui.PushItemWidth(150);
    ImGui.InputInt("Normal Material", *normal_mat);
    ImGui.InputInt("Uncommon Material", *uncommon_mat);
    ImGui.InputInt("Rare Material", *rare_mat);
    ImGui.PopItemWidth();

    if ImGui.Button("Calculate") 
    {
        n = 0;
        np_exchange = 0;
        up_exchange = 0;
        u_n_exchange = 0;
        total_powder = 0;
        
        required_normal: s32;
        required_uncommon: s32;
        required_rare: s32;
        
        excess_uncommon: s32;
        total_normal: s32;
        additional_normal: s32;
        total_uncommon: s32;

        p_normal: s32;
        p_uncommon: s32;

        while true
        {
            required_normal = 86 * (n+1);
            required_uncommon = 45 * (n+1);
            required_rare = 33 * (n+1);

            if uncommon_mat - required_uncommon > 0 
            {
                excess_uncommon = uncommon_mat - required_uncommon;
                u_n_exchange = excess_uncommon / 25;
                additional_normal = u_n_exchange * 50;
            }
            
            total_normal = normal_mat + additional_normal;
            total_uncommon: s32 = uncommon_mat - u_n_exchange * 25;

            if required_normal > total_normal
            {
                break;
            }

            uncommon_shortfall := ifx required_uncommon > total_uncommon 
                                  then required_uncommon - total_uncommon 
                                  else 0;
            rare_shortfall := ifx required_rare > rare_mat 
                              then required_rare - rare_mat 
                              else 0;

            pu =  cast(s32)ceil(uncommon_shortfall / 50.0) * 100;
            pr = cast(s32)ceil(rare_shortfall / 10.0) * 100;
            powder_needed := pu + pr;
            
            p_normal = ((total_normal - required_normal) / 100) * 80;
            p_normal = max(p_normal, 0);
            p_uncommon = ((total_uncommon - required_uncommon) / 50) * 80;
            p_uncommon = max(p_uncommon, 0);
            powder_available := p_normal + p_uncommon;

            if powder_available >= powder_needed
            {
                n += 1;
            }
            else
            {
                break;
            }
        }

        required_normal = 86 * n;
        required_uncommon = 45 * n;
        required_rare = 33 * n;
        additional_normal = 0;
        if uncommon_mat - required_uncommon > 0 
        {
            excess_uncommon = uncommon_mat - required_uncommon;
            u_n_exchange = excess_uncommon / 25;
            additional_normal = u_n_exchange * 50;
        }
    
        total_normal = normal_mat + additional_normal;
        total_uncommon = uncommon_mat - u_n_exchange * 25;

        uncommon_shortfall := ifx required_uncommon > total_uncommon 
                                  then required_uncommon - total_uncommon 
                                  else 0;
        rare_shortfall := ifx required_rare > rare_mat 
                            then required_rare - rare_mat 
                            else 0;

        pu =  cast(s32)ceil(uncommon_shortfall / 50.0) * 100;
        pr = cast(s32)ceil(rare_shortfall / 10.0) * 100;

        p_normal = ((total_normal - required_normal) / 100) * 80;
        p_normal = max(p_normal, 0);
        p_uncommon = ((total_uncommon - required_uncommon) / 50) * 80;
        p_uncommon = max(p_uncommon, 0);
        total_powder = p_normal + p_uncommon;
        np_exchange = max(p_normal / 80, 0);
        up_exchange = max(p_uncommon / 80, 0);

        status = .OK;
    }

    if status == .OK 
    {
        max_craft := n * 10;
        ImGui.Text("Maximum craftable: % Abidos", max_craft);
        ImGui.Text("# of Uncommon to Normal exchanges: %x", u_n_exchange);
        ImGui.Text("# of Normal to Powder exchanges: %x", np_exchange);
        ImGui.Text("# of Uncommon to Powder exchanges: %x", up_exchange);
        ImGui.Text("Powder available after exchange: %", total_powder);
        ImGui.Text("Powder needed for uncommon: % (%x exchange)", pu, pu/100);
        ImGui.Text("Powder needed for rare: % (%x exchange)", pr, pr/100);

        ImGui.NewLine();
        ImGui.Separator();

        base_cost: float = 401;
        crafting_cost: float = n * (base_cost - (base_cost * (total_crafting_cost_reduction/100.0)));
        materials_cost: float = (n * 86 * timber_price * 0.01) + (n * 45 * tender_timber_price * 0.01) + (n * 33 * abidos_timber_price * 0.01);

        profit: float = cast(float)(abidos_price * max_craft);
        tax: float = profit * 0.05;
        total_profit: float = profit - tax - crafting_cost;

        ImGui.Text("Crafting cost: %g", cast(int)crafting_cost);
        ImGui.Text("Materials cost: %g", cast(int)materials_cost);
        ImGui.Text("Tax: %g", cast(int)tax);
        ImGui.Text("Raw profit from abidos: %g", cast(int)profit);
        ImGui.Text("Profit: %g", cast(int)total_profit);
        ImGui.Text("Profit if you buy trade mats: %g", cast(int)(total_profit - materials_cost));
    }

}