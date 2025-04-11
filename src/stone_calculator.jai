Effect :: enum 
{
    GOOD_1;
    GOOD_2;
    BAD;
}

Node :: struct 
{
    succeeded: bool;

    // Maybe will need this?
    effect: Effect;
    index: int;
}

Calculator_State :: struct 
{
    current_probability: float = 0.75;  // Starting at 75%
    nodes: [3][10]Node;                 // 3 effects, 10 nodes each
    successes: [3]int;                  // Track successes for each effect
}

update_probability :: (success: bool, current_prob: float) -> float 
{
    new_prob := current_prob;
    if success then
        new_prob -= 0.10;
    else
        new_prob += 0.10;
    
    // Clamp between 25% and 75%
    return clamp(new_prob, 0.25, 0.75);
}

calculate_success_probability :: (state: Calculator_State, target: [3]int) -> float 
{
    //*NOTE: Calculate probability of reaching target from current state
    //TODO: This is a simplified version, might want to use dynamic programming for a more accurate calculation, idk
    remaining_attempts := 0;
    for effect: 0..2 
    {
        remaining_attempts += abs(target[effect] - state.successes[effect]);
    }
    
    return pow(state.current_probability, cast(float)remaining_attempts);
}

find_best_node :: (state: Calculator_State, target: [3]int) -> Node 
{
    best_node: Node;
    best_value := -1.0;
    
    // Try each nontapped node
    for effect: 0..2 
    {
        if state.successes[effect] >= target[effect] continue;
        
        for node_idx: 0..9 
        {
            if state.nodes[effect][node_idx].succeeded continue;
            
            // Simulate tapping this node
            success_prob := state.current_probability;
            failure_prob := 1.0 - success_prob;
            
            // Calculate expected value
            success_value := calculate_success_probability
            (
                state_after_success(state, effect, node_idx), 
                target
            );
            failure_value := calculate_success_probability
            (
                state_after_failure(state, effect, node_idx), 
                target
            );
            
            expected_value := success_prob * success_value + failure_prob * failure_value;
            
            if expected_value > best_value 
            {
                best_value = expected_value;
                best_node = state.nodes[effect][node_idx];
            }
        }
    }
    
    return best_node;
}

state_after_success :: (state: Calculator_State, effect: int, node_idx: int) -> Calculator_State 
{
    new_state := state;
    new_state.nodes[effect][node_idx].succeeded = true;
    new_state.successes[effect] += 1;
    new_state.current_probability = update_probability(true, state.current_probability);
    return new_state;
}

state_after_failure :: (state: Calculator_State, effect: int, node_idx: int) -> Calculator_State 
{
    new_state := state;
    new_state.nodes[effect][node_idx].succeeded = true;
    new_state.current_probability = update_probability(false, state.current_probability);
    return new_state;
}
