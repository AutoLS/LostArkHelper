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

DEFAULT_SCORE_BOARD :: [N_TILE] float.[
    float.[  0.5,  2,   2,   2,   2  ],
    float.[  0.5,  2,  10,   20,  2  ],
    float.[  0.5,  2,   7,   10,  2  ],
    float.[  0.5,  2,   2,   2,   2  ],
    float.[  0.5,  0.5, 0.5, 0.5, 0.5]
];

Bingo_Board :: struct
{
    tiles: Grid(N_TILE, N_TILE, Bingo_Tile);
    tile_dim: Vector2;
    board_size: float;
    turn: int;
    score_board: [N_TILE][N_TILE] float = DEFAULT_SCORE_BOARD;
    total_score: float; 

    board_state: [..] Grid(N_TILE, N_TILE, Bingo_Tile);
}

init_bingo_board :: (using board: *Bingo_Board)
{
    using lost_ark_helper;
    turn = -2;
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
        if tile.status == 
        {
            case .Empty;
            {
                tile.status = .White;
            }
            case .White;
            {
                if !tile.dead_tile
                    tile.status = .Empty;
            }
        }
    }
}

check_bingo :: (tiles: *Grid(N_TILE, N_TILE, Bingo_Tile)) -> bool
{
    bingo := false;
    //Check rows and columns
    for 0 .. N_TILE-1
    {
        if  tiles.values[it*N_TILE + 0].status == .White &&
            tiles.values[it*N_TILE + 1].status == .White &&
            tiles.values[it*N_TILE + 2].status == .White &&
            tiles.values[it*N_TILE + 3].status == .White &&
            tiles.values[it*N_TILE + 4].status == .White
        {
            for x : 0 .. N_TILE-1 tiles.values[it*N_TILE + x].dead_tile = true;
            bingo = true;
        }

        if  tiles.values[0*N_TILE + it].status == .White &&
            tiles.values[1*N_TILE + it].status == .White &&
            tiles.values[2*N_TILE + it].status == .White &&
            tiles.values[3*N_TILE + it].status == .White &&
            tiles.values[4*N_TILE + it].status == .White
        {
            for y : 0 .. N_TILE-1 tiles.values[y*N_TILE + it].dead_tile = true;
            bingo = true;
        }
    }

    //Check diagonals
    if  tiles.values[0*N_TILE + 0].status == .White &&
        tiles.values[1*N_TILE + 1].status == .White &&
        tiles.values[2*N_TILE + 2].status == .White &&
        tiles.values[3*N_TILE + 3].status == .White &&
        tiles.values[4*N_TILE + 4].status == .White 
    {
        for 0 .. N_TILE-1 tiles.values[it*N_TILE + it].dead_tile = true;
        bingo = true;
    }

    if  tiles.values[0*N_TILE + 4].status == .White &&
        tiles.values[1*N_TILE + 3].status == .White &&
        tiles.values[2*N_TILE + 2].status == .White &&
        tiles.values[3*N_TILE + 1].status == .White &&
        tiles.values[4*N_TILE + 0].status == .White 
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

    check_bingo(tiles);
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

update_score_board :: (using board: *Bingo_Board)
{
    total_score = 0;
    for tiles
    {
        if it.status == .White then score_board[it_index.y][it_index.x] = 10;
        else score_board[it_index.y][it_index.x] = DEFAULT_SCORE_BOARD[it_index.y][it_index.x];
        
        if it.dead_tile then score_board[it_index.y][it_index.x] = 20;
    }

    total_score = calculate_total_score(score_board);
    print("Total score: %\n", total_score);
}

calculate_best_placements :: (using board: *Bingo_Board)
{
    /*  Rules:
        1. Remove white skulls if possible
        2. Avoid center tiles if possible 
        3. Bingo must be possible every 3 turns
        4. Avoid placing on white/red skulls
    */
    min := 500;

}

reset_board :: (using board: *Bingo_Board)
{
    for tiles
    {
        it.status = .Empty;
        it.dead_tile = false;
    }
    total_score = 0;
    score_board = DEFAULT_SCORE_BOARD;
    array_reset(*board_state);
    array_add(*board_state, tiles);
    turn = -2;
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
                if turn >= 0 
                {
                    place_bomb(*tiles, it_index.x, it_index.y);
                    update_score_board(board);
                    array_add(*board_state, tiles);
                    turn += 1;
                }
                else 
                {
                    if tile.status == .Empty 
                    {
                        tile.status = .White;
                        array_add(*board_state, tiles);
                        turn += 1;
                        update_score_board(board);
                    }
                }
            }
        }
    }
    
}