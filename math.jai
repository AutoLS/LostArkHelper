Rectf :: struct
{
    x: float;
    y: float;
    w: float;
    h: float;

#place x;
    pos: Vector2 = ---;
#place w;
    dim: Vector2 = ---;
}

rectf :: (x: float, y: float, w: float, h: float) -> Rectf
{
    rect: Rectf;
    rect.x = x;
    rect.y = y;
    rect.w = w;
    rect.h = h;

    return rect;
}

make_ImVec2 :: (x: float, y: float) -> ImGui.ImVec2
{
    ret: ImGui.ImVec2;
    ret.x = x;
    ret.y = y;

    return ret;
}

round_real_to_int :: (x: float) -> int
{
    return cast(int)(x + 0.5);
}