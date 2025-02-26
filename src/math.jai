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

Grid :: struct (count_x: s64, count_y: s64, T: Type) 
{
    NUM_SQUARES :: count_x*count_y;
    
    values:   [NUM_SQUARES] T;
}

for_expansion :: (grid: *Grid, body: Code, flags: For_Flags) #expand 
{
    for y: 0..grid.count_y-1 
    {
        for x: 0..grid.count_x-1 
        {
            index := y*grid.count_x + x;

            `it := *grid.values[index];
            
            `it_index: Vec2(int); 
            it_index.x = x;
            it_index.y = y;

            #insert body;
        }
    }
}

point_in_rect :: (p: Vector2, rect: Rectf) -> bool
{
	if(p.x < rect.x)
	{
		return false;
	}
	if(p.x > rect.x + rect.w)
	{
		return false;
	}
	if(p.y < rect.y)
	{
		return false;
	}
	if(p.y > rect.y + rect.h)
	{
		return false;
	}
	return true;
}

radians :: (theta: float) -> float
{
	return (theta * (PI/180.0));
}

Vec2 :: struct($T: Type)
{
    x: T;
    y: T;
}

make_vec2 :: (x: $T, y: T) -> Vec2
{
    v: Vec2(T);
    v.x = x;
    v.y = y;

    return v;
}

rotate_point_around_center :: (p: *Vector2, center: Vector2, theta: float)
{
    translated := << p - center;
    cos_angle := cos(radians(theta));
    sin_angle := sin(radians(theta));
    p.x = (cos_angle * translated.x - sin_angle * translated.y);
    p.y = (sin_angle * translated.x + cos_angle * translated.y);
    << p += center;
}

make_ImVec2 :: (x: float, y: float) -> ImGui.ImVec2
{
    ret: ImGui.ImVec2;
    ret.x = x;
    ret.y = y;

    return ret;
}

make_ImVec4 :: (x: float, y: float, z: float, w: float) -> ImGui.ImVec4
{
    ret: ImGui.ImVec4;
    ret.x = x;
    ret.y = y;
    ret.z = z;
    ret.w = w;

    return ret;
}

make_rotation_matrix :: (axis: Vector3, angle: float) -> Matrix4 
{
	q: Quaternion;
	set_from_axis_and_angle(*q, axis.x, axis.y, axis.z, angle);
	return rotation_matrix(Matrix4, q);
}

round_real_to_int :: (x: float) -> int
{
    return cast(int)(x + 0.5);
}

ceil_real_to_int :: (x: float) -> int
{
    result := cast(int)x;
    if x == cast(float)result
    {
        return result;
    }
    return result + 1;
}
