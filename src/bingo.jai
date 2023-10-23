Tile_Status :: enum u32
{
    Empty;
    White;
    Red;
}

Bingo_Tile :: struct
{
    status: Tile_Status;
    dead_tile: bool;
    position: Vector2; //Center position of the tile
    rect: Rectf;
}

N_TILE :: 5;

Bingo_Board :: struct
{
    tiles: [N_TILE][N_TILE] Bingo_Tile;
    tile_dim: Vector2;
    board_size: float;
    turn: int;
    is_bingo: bool;

    board_state: [..][N_TILE][N_TILE] Bingo_Tile;
}

init_bingo_board :: (using board: *Bingo_Board)
{
    using lost_ark_helper;
    offset: float = 25;
    tile_dim = Vector2.{50, 50};
    board_size = tile_dim.x * N_TILE;
    start_x := window_dimension.x*0.5 - board_size*0.5 + tile_dim.x*0.5 - 10;
    start_y := window_dimension.y*0.5 - board_size*0.5 + tile_dim.y*0.5 - 10;
    pos := Vector2.{start_x, start_y};
    for y : 0 .. N_TILE-1
    {
        for x : 0 .. N_TILE-1
        {
            tiles[y][x].position = pos;
            tiles[y][x].rect.pos = pos - tile_dim*0.5;
            tiles[y][x].rect.dim = tile_dim;

            pos.x += tile_dim.x + (offset/N_TILE);
        }
        pos.y += (tile_dim.y + (offset/N_TILE));
        pos.x = start_x;
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

check_bingo :: (using board: *Bingo_Board) -> bool
{
    bingo := false;
    //Check rows and columns
    for 0 .. N_TILE-1
    {
        if  tiles[it][0].status == .White &&
            tiles[it][1].status == .White &&
            tiles[it][2].status == .White &&
            tiles[it][3].status == .White &&
            tiles[it][4].status == .White
        {
            for x : 0 .. N_TILE-1 tiles[it][x].dead_tile = true;
            bingo = true;
        }

        if  tiles[0][it].status == .White &&
            tiles[1][it].status == .White &&
            tiles[2][it].status == .White &&
            tiles[3][it].status == .White &&
            tiles[4][it].status == .White
        {
            for y : 0 .. N_TILE-1 tiles[y][it].dead_tile = true;
            bingo = true;
        }
    }

    //Check diagonals
    if  tiles[0][0].status == .White &&
        tiles[1][1].status == .White &&
        tiles[2][2].status == .White &&
        tiles[3][3].status == .White &&
        tiles[4][4].status == .White 
    {
        for 0 .. N_TILE-1 tiles[it][it].dead_tile = true;
        bingo = true;
    }

    if  tiles[0][4].status == .White &&
        tiles[1][3].status == .White &&
        tiles[2][2].status == .White &&
        tiles[3][1].status == .White &&
        tiles[4][0].status == .White 
    {
        tiles[0][4].dead_tile = true;
        tiles[1][3].dead_tile = true;
        tiles[2][2].dead_tile = true;
        tiles[3][1].dead_tile = true;
        tiles[4][0].dead_tile = true;
        bingo = true;
    }

    return bingo;
}

drop_bomb_on_tile :: (using board: *Bingo_Board, x: int, y: int)
{
    left := ifx x-1 >= 0 then *tiles[y][x-1] else null;
    right := ifx x+1 < 5 then *tiles[y][x+1] else null;
    up := ifx y-1 >= 0 then *tiles[y-1][x] else null;
    bottom := ifx y+1 < 5 then *tiles[y+1][x] else null;

    do_tile_logic(*tiles[y][x]);
    do_tile_logic(left);
    do_tile_logic(right);
    do_tile_logic(up);
    do_tile_logic(bottom);

    check_bingo(board);
}

draw_board :: (using board: *Bingo_Board)
{
    using lost_ark_helper;
    rotate_projection(*simple_renderer);
    for y : 0 .. N_TILE-1
    {
        for x : 0 .. N_TILE-1
        {
            tile := *tiles[y][x];
            color: Vector4;
            if tile.status ==
            {
                case .Empty; color = .{0, 0, 1, 1};
                case .White; color = .{1, 1, 1, 1};
            }
            if tile.dead_tile then color = .{1, 0, 0, 1};
            draw_rect(*simple_renderer, tile.position, tile.rect.dim, color);
        }
    }
    default_projection_view(*simple_renderer);
}

update_board :: (using board: *Bingo_Board)
{
    using lost_ark_helper;

    if ImGui.Button("Reset Bingo")
    {
        for y : 0 .. N_TILE-1
        {
            for x : 0 .. N_TILE-1
            {
                tiles[y][x].status = .Empty;
                tiles[y][x].dead_tile = false;
            }
        }
        array_reset(*board_state);
        array_add(*board_state, tiles);
    }

    if ImGui.Button("Undo")
    {
        if board_state.count > 1
        {
            pop(*board_state);
            tiles = peek(board_state);
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
        for y : 0 .. N_TILE-1
        {
            for x : 0 .. N_TILE-1
            {
                if point_in_rect(mouse_pos, tiles[y][x].rect)
                {
                    drop_bomb_on_tile(board, x, y);
                    array_add(*board_state, tiles);
                }
            }
        }
    }
    
}