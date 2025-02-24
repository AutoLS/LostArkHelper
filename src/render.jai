Simple_Renderer :: struct
{
    shader: u32;
    rect: GL_Shape_Data;

    projection: Matrix4;
    view: Matrix4;
}

create_simple_renderer :: () -> Simple_Renderer
{
    using renderer: Simple_Renderer;

    shader = create_shader(VERTEX_SOURCE, FRAGMENT_SOURCE);
	
	rect_vertices :: Vector3.[
		Vector3.{0.5, 0.5, 0},   //Top Right		
		Vector3.{0.5, -0.5, 0},  //Bottom Right
		Vector3.{-0.5, -0.5, 0}, //Bottom Let
		Vector3.{-0.5, -0.5, 0}, //Bottom Let
		Vector3.{-0.5, 0.5, 0},  //Top Let
		Vector3.{0.5, 0.5, 0}    //Top Right	
	];
	
	rect = gl_gen_shape(rect_vertices.data, 6, size_of(Vector3)*6);
	gl_upload_shape_data(*rect);
	gl_set_attrib_pointer(*rect, 0, 3, 0, 0);

    projection = orthographic_projection_matrix(0, 1280, 720, 0, -1, 1); //NOTE: This is in screen space which means y coord starts from the top instead of bottom.
    view = identity_of(Matrix4);

    gl_set_projection_view_matrix(shader, *projection, *view);
	
	return renderer;
}

default_projection_view :: (using renderer: *Simple_Renderer)
{
    projection = orthographic_projection_matrix(0, 1280, 720, 0, -1, 1);
    view = identity_of(Matrix4);
    gl_set_projection_view_matrix(shader, *projection, *view);
}

rotate_projection :: (using renderer: *Simple_Renderer)
{
    using lost_ark_helper;
    view = translate(identity_of(Matrix4), Vector3.{window_dimension.x * 0.5, window_dimension.y*0.5, 0}) * make_rotation_matrix(.{0, 0, 1}, radians(-45.0));
    view = translate(view, Vector3.{-window_dimension.x * 0.5, -window_dimension.y*0.5, 0});
    gl_set_projection_view_matrix(shader, *projection, *view);
}

draw_rect :: (using renderer: *Simple_Renderer, pos: Vector2, dim: Vector2, color: Vector4, axis: Vector3 = .{}, angle: float = 0)
{
    glUseProgram(shader);
	glUniform4f(glGetUniformLocation(shader, "color"), color.x, color.y, color.z, color.w);
	
	rotation := identity_of(Matrix4);
	if angle then rotation = make_rotation_matrix(axis, angle);
	
	model := scale(translate(identity_of(Matrix4), Vector3.{pos.x, pos.y, 0}) * rotation, Vector3.{dim.x, dim.y, 0});
	model_loc := glGetUniformLocation(shader, "model");
	glUniformMatrix4fv(model_loc, 1, true, xx *model);
	
	glEnable(GL_BLEND);
	glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
	
	glBindVertexArray(rect.vao);
	glDrawArrays(GL_TRIANGLES, 0, rect.n_vertices);
	
	glDisable(GL_BLEND);
	glBindVertexArray(0);
	glUseProgram(0);
}