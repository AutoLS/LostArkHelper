Tile_Status :: enum u32
{
    Empty;
    White;
}

Bingo_Tile :: struct
{
    status: Tile_Status;
    dead_tile: bool;
    position: Vector2; //Center position of the tile
    rect: Rectf;
}

N_TILE :: 5;

SCORE_MULTIPLIER_BOARD :: [N_TILE] float.[
    float.[  1,  5,   5,   5,   5  ],
    float.[  1,  5,  25,  50,   5  ],
    float.[  1,  5,  15,  25,   5  ],
    float.[  1,  5,   5,   5,   5  ],
    float.[  1,  1,   1,   1,   1]
];

Bingo_Board :: struct
{
    tiles: Grid(N_TILE, N_TILE, Bingo_Tile);
    tile_dim: Vector2;
    board_size: float;
    turn: int;
    score_board: [N_TILE][N_TILE] float = SCORE_MULTIPLIER_BOARD;
    total_score: float; 

    placement_indices: [..] Vec2(int);
    board_state: [..] Grid(N_TILE, N_TILE, Bingo_Tile);
}

init_bingo_board :: (using board: *Bingo_Board)
{
    using lost_ark_helper;
    turn = -1;
    offset: float = 25;
    tile_dim = Vector2.{50, 50};
    board_size = tile_dim.x * N_TILE;
    start_x := window_dimension.x*0.5 - board_size*0.5 + tile_dim.x*0.5 - 10;
    start_y := window_dimension.y*0.5 - board_size*0.5 + tile_dim.y*0.5 - 10;
    pos := Vector2.{start_x, start_y};
    for tiles
    {
        it.position = pos;
        it.rect.pos = pos - tile_dim*0.5;
        it.rect.dim = tile_dim;

        pos.x += tile_dim.x + (offset/N_TILE);

        if it_index.x == N_TILE-1
        {
            pos.y += (tile_dim.y + (offset/N_TILE));
            pos.x = start_x;
        }

    }

    array_add(*board_state, tiles);
}

do_tile_logic :: (using tile: *Bingo_Tile)
{
    if tile
    {
        if !tile.dead_tile
        {
            if tile.status == 
            {
                case .Empty;
                {
                    tile.status = .White;
                }
                case .White;
                {
                    tile.status = .Empty;
                }
            }
        }
    }
}

check_bingo :: (tiles: *Grid(N_TILE, N_TILE, Bingo_Tile)) -> bool
{
    bingo := false;
    all_dead: bool = true;
    //Check rows and columns
    for 0 .. N_TILE-1
    {
        all_dead = tiles.values[it*N_TILE + 0].dead_tile &&
                   tiles.values[it*N_TILE + 1].dead_tile &&
                   tiles.values[it*N_TILE + 2].dead_tile &&
                   tiles.values[it*N_TILE + 3].dead_tile &&
                   tiles.values[it*N_TILE + 4].dead_tile;
        
        if  tiles.values[it*N_TILE + 0].status == .White &&
            tiles.values[it*N_TILE + 1].status == .White &&
            tiles.values[it*N_TILE + 2].status == .White &&
            tiles.values[it*N_TILE + 3].status == .White &&
            tiles.values[it*N_TILE + 4].status == .White && 
            !all_dead
        {
            for x : 0 .. N_TILE-1 tiles.values[it*N_TILE + x].dead_tile = true;
            bingo = true;
        }

        all_dead = tiles.values[0*N_TILE + it].dead_tile &&
                   tiles.values[1*N_TILE + it].dead_tile &&
                   tiles.values[2*N_TILE + it].dead_tile &&
                   tiles.values[3*N_TILE + it].dead_tile &&
                   tiles.values[4*N_TILE + it].dead_tile;

        if  tiles.values[0*N_TILE + it].status == .White &&
            tiles.values[1*N_TILE + it].status == .White &&
            tiles.values[2*N_TILE + it].status == .White &&
            tiles.values[3*N_TILE + it].status == .White &&
            tiles.values[4*N_TILE + it].status == .White && 
            !all_dead
        {
            for y : 0 .. N_TILE-1 tiles.values[y*N_TILE + it].dead_tile = true;
            bingo = true;
        }
    }

    //Check diagonals
    all_dead = tiles.values[0*N_TILE + 0].dead_tile &&
               tiles.values[1*N_TILE + 1].dead_tile &&
               tiles.values[2*N_TILE + 2].dead_tile &&
               tiles.values[3*N_TILE + 3].dead_tile &&
               tiles.values[4*N_TILE + 4].dead_tile;

    if  tiles.values[0*N_TILE + 0].status == .White &&
        tiles.values[1*N_TILE + 1].status == .White &&
        tiles.values[2*N_TILE + 2].status == .White &&
        tiles.values[3*N_TILE + 3].status == .White &&
        tiles.values[4*N_TILE + 4].status == .White &&
        !all_dead
    {
        for 0 .. N_TILE-1 tiles.values[it*N_TILE + it].dead_tile = true;
        bingo = true;
    }
    
    all_dead = 
    tiles.values[0*N_TILE + 4].dead_tile && 
    tiles.values[1*N_TILE + 3].dead_tile &&
    tiles.values[2*N_TILE + 2].dead_tile &&
    tiles.values[3*N_TILE + 1].dead_tile &&
    tiles.values[4*N_TILE + 0].dead_tile;

    if  tiles.values[0*N_TILE + 4].status == .White &&
        tiles.values[1*N_TILE + 3].status == .White &&
        tiles.values[2*N_TILE + 2].status == .White &&
        tiles.values[3*N_TILE + 1].status == .White &&
        tiles.values[4*N_TILE + 0].status == .White &&
        !all_dead
    {
        tiles.values[0*N_TILE + 4].dead_tile = true;
        tiles.values[1*N_TILE + 3].dead_tile = true;
        tiles.values[2*N_TILE + 2].dead_tile = true;
        tiles.values[3*N_TILE + 1].dead_tile = true;
        tiles.values[4*N_TILE + 0].dead_tile = true;
        bingo = true;
    }

    return bingo;
}

place_bomb :: (tiles: *Grid(N_TILE, N_TILE, Bingo_Tile), x: int, y: int)
{
    left := ifx x-1 >= 0 then *tiles.values[y*N_TILE + (x-1)] else null;
    right := ifx x+1 < 5 then *tiles.values[y*N_TILE + (x+1)] else null;
    up := ifx y-1 >= 0 then *tiles.values[((y-1)*N_TILE) + x] else null;
    bottom := ifx y+1 < 5 then *tiles.values[((y+1)*N_TILE) + x] else null;

    do_tile_logic(*tiles.values[y*N_TILE + x]);
    do_tile_logic(left);
    do_tile_logic(right);
    do_tile_logic(up);
    do_tile_logic(bottom);
}

calculate_total_score :: (score_board: [N_TILE][N_TILE] float) -> float
{
    total_score: float;
    for y : 0 .. N_TILE-1
    {
        for x : 0 .. N_TILE-1
        {
            total_score += score_board[y][x];
        }
    }
    return total_score;
}

calculate_placement_score :: (x: int, y: int, turn: int, tiles: *Grid(N_TILE, N_TILE, Bingo_Tile)) -> float
{
    score: float;
    tile_value := 5.0;
    white_skull_value := 25.0;
    tile_to_place := tiles.values[y*N_TILE + x];
    if tile_to_place.dead_tile then score += tile_value * 50;
    else if tile_to_place.status == 
    {
        case .White;
        {
            score += tile_value * SCORE_MULTIPLIER_BOARD[y][x] * white_skull_value;
        }
        case .Empty;
        {
            score += tile_value * SCORE_MULTIPLIER_BOARD[y][x];
        }
    }

    tiles_affected: [..] *Bingo_Tile;
    sim_tiles := << tiles;
    left := ifx x-1 >= 0 then *sim_tiles.values[y*N_TILE + (x-1)] else null;
    right := ifx x+1 < 5 then *sim_tiles.values[y*N_TILE + (x+1)] else null;
    up := ifx y-1 >= 0 then *sim_tiles.values[((y-1)*N_TILE) + x] else null;
    bottom := ifx y+1 < 5 then *sim_tiles.values[((y+1)*N_TILE) + x] else null;
    array_add(*tiles_affected, left);
    array_add(*tiles_affected, right);
    array_add(*tiles_affected, up);
    array_add(*tiles_affected, bottom);
    for tiles_affected
    {
        do_tile_logic(it);
        if it
        {
            if it.status == .White
            {
                score += tile_value * SCORE_MULTIPLIER_BOARD[y][x] * white_skull_value;
            }
        }
    }

    bingo := check_bingo(*sim_tiles);
    if turn % 3 == 0 && !bingo then return -1;
    if turn % 3 != 0 && bingo
    {
        score += tile_value * 1000;
    }

    return score;
}

// TODO: This is currently not an ideal solution, but it's the best one that I came up with my smol brain atm.. 
calculate_best_placements :: (using board: *Bingo_Board)
{
    /*  Rules:
        1. Remove white skulls if possible
        2. Avoid center tiles if possible 
        3. Bingo must be possible every 3 turns
        4. Avoid placing on white/red skulls
    */
    simulation_min := FLOAT64_MAX;
    score: float;

    array_reset(*placement_indices);

    for tiles
    {  
        sim := tiles;
        score = calculate_placement_score(it_index.x, it_index.y, turn, *tiles);
        place_bomb(*sim, it_index.x, it_index.y);
        is_bingo := check_bingo(*sim);

        if turn % 3 == 0 && !is_bingo then continue;

        has_bingo := true;
        if (turn+1) % 3 == 0
        {
            has_bingo = false;
            for sim
            {
                test_bingo := sim;
                test_score := calculate_placement_score(it_index.x, it_index.y, turn+1, *test_bingo);
                place_bomb(*test_bingo, it_index.x, it_index.y);
                bingo := check_bingo(*test_bingo);

                if !bingo then continue;

                has_bingo = true;
                score += test_score;
            }
        }

        if !has_bingo then continue;

        if score <= simulation_min 
        {
            simulation_min = score;
            array_add(*placement_indices, it_index);
        }
    }

    print("Round: %\n", turn);
    for placement_indices
    {
        print("Index: (%, %)\n", it.x, it.y);
    }
    print("\n");
}

reset_board :: (using board: *Bingo_Board)
{
    for tiles
    {
        it.status = .Empty;
        it.dead_tile = false;
    }
    total_score = 0;
    score_board = SCORE_MULTIPLIER_BOARD;
    array_reset(*board_state);
    array_reset(*placement_indices);
    array_add(*board_state, tiles);
    turn = -1;
}

draw_board :: (using board: *Bingo_Board)
{
    using lost_ark_helper;
    rotate_projection(*simple_renderer);
    for tiles
    {
        color: Vector4;
        if it.status ==
        {
            case .Empty; color = .{0, 0, 1, 1};
            case .White; color = .{1, 1, 1, 1};
        }
        if it.dead_tile then color = .{1, 0, 0, 1};
        draw_rect(*simple_renderer, it.position, it.rect.dim, color);
    }

    for placement_indices
    {
        tile := tiles.values[it.y*N_TILE + it.x];
        draw_rect(*simple_renderer, tile.position, tile.rect.dim*0.5, .{0, 1, 0, 1});
    }
    default_projection_view(*simple_renderer);
}

update_board :: (using board: *Bingo_Board)
{
    using lost_ark_helper;

    if ImGui.Button("Reset Bingo")
    {
        reset_board(board);
    }

    if ImGui.Button("Undo")
    {
        if board_state.count > 1
        {
            pop(*board_state);
            tiles = peek(board_state);
            turn -= 1;
        }
        if turn > 0 calculate_best_placements(board);
    }

    mouse_pos := make_vector2(xx input.mouse_state.x, xx input.mouse_state.y);
    rotation_angle := 45.0;
    rotate_point_around_center(*mouse_pos, window_dimension*0.5, rotation_angle);

/*  NOTE: These are for debug purposes
    rotate_projection(*simple_renderer);
    draw_rect(*simple_renderer, mouse_pos, .{10, 10}, .{1, 0, 0, 1});
    original := make_vector2(xx input.mouse_state.x, xx input.mouse_state.y);
    rotate_point_around_center(*original, window_dimension*0.5, 90);
    draw_rect(*simple_renderer, original, .{10, 10}, .{0, 1, 1, 1});
    default_projection_view(*simple_renderer);
*/
    if button_clicked(*input.left_button)
    {
        for tile : tiles
        {
            if point_in_rect(mouse_pos, tile.rect)
            {
                if turn > 0 
                {
                    place_bomb(*tiles, it_index.x, it_index.y);
                    check_bingo(*tiles);
                    turn += 1;
                    calculate_best_placements(board);
                    array_add(*board_state, tiles);
                }
                else 
                {
                    if tile.status == .Empty 
                    {
                        tile.status = .White;
                        array_add(*board_state, tiles);
                        turn += 1;
                        if turn > 0 calculate_best_placements(board);
                    }
                }
            }
        }
    }
    
}