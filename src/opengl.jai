#import "stb_image";

VERTEX_SOURCE :: #string DONE
#version 330 core

layout (location = 0) in vec3 in_pos;
layout (location = 1) in vec3 in_tex;

uniform mat4 model;
uniform mat4 view;
uniform mat4 projection;

void main()
{
    gl_Position = projection * view * model * vec4(in_pos, 1.0);
}

DONE

FRAGMENT_SOURCE :: #string DONE
#version 330 core

out vec4 out_frag_color;

uniform vec4 color;

void main ()
{
    out_frag_color = color;
}
DONE

compile_shader :: (type: GLenum, source: string) -> u32
{
	shader := glCreateShader(type);
	length: GLint = xx source.count;
	glShaderSource(shader, 1, *source.data, *length);
	glCompileShader(shader);
	
	shader_compile_success: s32;
	info_log: [512] u8;
	
	glGetShaderiv(shader, GL_COMPILE_STATUS, *shader_compile_success);
	if !shader_compile_success
	{
		len := 512;
		glGetShaderInfoLog(shader, xx len, xx *len, info_log.data);
		print("% shader compilation failed: %\n", type, info_log);
	}
	
	return shader;
}

create_shader :: (vertex_source: string, fragment_source: string) -> u32
{
	vertex_shader := compile_shader(GL_VERTEX_SHADER, vertex_source);
	fragment_shader := compile_shader(GL_FRAGMENT_SHADER, fragment_source);
	
	program := glCreateProgram();
	glAttachShader(program, vertex_shader);
	glAttachShader(program, fragment_shader);
	glLinkProgram(program);
	
	linking_success: s32;
	glGetProgramiv(program, GL_LINK_STATUS, *linking_success);
	info_log: [512] u8;
	
	if !linking_success
	{
		len := 512;
		glGetProgramInfoLog(program, xx len, xx *len, info_log.data);
		print("Linking failed: %\n", info_log);
	}
	
	glDeleteShader(vertex_shader);
	glDeleteShader(fragment_shader);  
	
	return program;
}

create_shader :: (path: string) -> u32 {
    
	compile_shader :: (type: GLenum, source: string) -> u32 
	{
		v := glCreateShader(type);

		VERTEX_DEFINE :: "#define VERTEX_SHADER\n";
		FRAGMENT_DEFINE :: "#define FRAGMENT_SHADER\n";

		sources : [3] *u8;
		lengths : [3] GLint;

		sources[0] = "#version 330 core\n";
		lengths[0] = xx strlen(sources[0]);

		if type == GL_VERTEX_SHADER
		{
			sources[1] = VERTEX_DEFINE.data;
			lengths[1] = xx strlen(VERTEX_DEFINE.data);
		}
		else if type == GL_FRAGMENT_SHADER
		{
			sources[1] = FRAGMENT_DEFINE.data;
			lengths[1] = xx strlen(FRAGMENT_DEFINE.data);
		}
		else
		{
			assert(false);
		}

		a := to_c_string(source);
		defer free(a);

		sources[2] = a;
		lengths[2] = xx strlen(a);

		glShaderSource(v, 3, xx sources.data, lengths.data);
		glCompileShader(v);

		status: GLint;
		glGetShaderiv(v, GL_COMPILE_STATUS, *status);
		if (status == 0) {
			len: GLint;
			glGetShaderiv(v, GL_INFO_LOG_LENGTH, *len);
			buf := cast(*u8) alloc(len);
			glGetShaderInfoLog(v, xx len, xx *len, buf);
			print("ERROR: %\n", to_string(buf));
			free(buf);

			glDeleteShader(v);
			return 0;
		}

		return v;
	}
	
	source, success := read_entire_file(path);
	
	if success
	{
		vert := compile_shader(GL_VERTEX_SHADER, source);
		frag := compile_shader(GL_FRAGMENT_SHADER, source);

		program := glCreateProgram();

		glAttachShader(program, vert);
		glAttachShader(program, frag);

		glLinkProgram(program);

		status: GLint;
		glGetProgramiv(program, GL_LINK_STATUS, *status);
		if (status == 0) {
			len: GLint;
			glGetProgramiv(program, GL_INFO_LOG_LENGTH, *len);
			buf := cast(*u8) alloc(len);
			glGetProgramInfoLog(program, xx len, xx *len, buf);
			print("ERROR: %\n", to_string(buf));
			free(buf);

			glDeleteProgram(program);
			glDeleteShader(vert);
			glDeleteShader(frag);
			return 0;
		}

		glDetachShader(program, vert);
		glDetachShader(program, frag);

		glValidateProgram(program);
		return program;
	}
	else
	{
		print("Reading file failed!\n");
		return 0;
	}
}

GL_Shape_Data :: struct 
{
	vao, vbo, ebo: u32;
	vertices: *Vector3;
	indices: *u32;
	
	n_vertices, n_vertices_total, n_indices: u32;
	usage: GLenum;
}

gl_gen_shape :: (vertices: *Vector3, count: u32, total_count: u32, 
				  indices: *u32 = null, indices_count: u32 = 0, usage: GLenum = GL_STATIC_DRAW) 
				  -> GL_Shape_Data
{
	shape: GL_Shape_Data;
	glGenVertexArrays(1, *shape.vao);
	glGenBuffers(1, *shape.vbo);
	
	if indices
	{
		glGenBuffers(1, *shape.ebo);
		shape.indices = indices;
		shape.n_indices = indices_count;
	}
	
	shape.vertices = vertices;
	shape.n_vertices = count;
	shape.n_vertices_total = total_count;
	shape.usage = usage;
	
	return shape;
}

gl_upload_shape_data :: (shape: *GL_Shape_Data)
{
	glBindVertexArray(shape.vao);

	glBindBuffer(GL_ARRAY_BUFFER, shape.vbo);
	glBufferData(GL_ARRAY_BUFFER, size_of(Vector3) * shape.n_vertices_total, 
				 shape.vertices, shape.usage);
	
	if(shape.indices)
	{
		glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, shape.ebo);
		glBufferData(GL_ELEMENT_ARRAY_BUFFER, size_of(u32) * shape.n_indices, 
					 shape.indices, shape.usage);
	}

	glBindVertexArray(0);
}

gl_set_attrib_pointer :: (shape: *GL_Shape_Data, loc: u32, size: s32, stride: GLsizei, offset: s32)
{
	glBindVertexArray(shape.vao);
	glVertexAttribPointer(loc, size, GL_FLOAT, GL_FALSE, 
						  stride * size_of(float), xx (size_of(float)*offset));
	glEnableVertexAttribArray(loc);
	glBindVertexArray(0);
}

gl_load_texture :: (path: *u8, alpha: bool, flip: bool = false, n: s32 = 0) -> u32
{
	//TODO: Find a way to flip the image? Either implement yourself or do it in shader.
	//stbi_set_flip_vertically_on_load(flip);
	texture_id: u32;
	glGenTextures(1, *texture_id);
	
	width, height, components: s32;
	data := stbi_load(path, *width, *height, *components, n);
	if data
	{
		format: GLenum;
		if components == 1
            format = GL_RED;
		else if components == 3
            format = GL_RGB;
        else if components == 4
            format = GL_RGBA;
			
		glBindTexture(GL_TEXTURE_2D, texture_id);
        glTexImage2D(GL_TEXTURE_2D, 0, xx format, xx width, xx height, 0, format, GL_UNSIGNED_BYTE, data);
        glGenerateMipmap(GL_TEXTURE_2D);
        
		if(alpha)
		{
			glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
			glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
		}
		else
		{
			glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
			glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
		}
		
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
        stbi_image_free(data);
	}
	else
	{
		print("ERROR: cannot load texture!\n");
		stbi_image_free(data);
	}
	
	return texture_id;
}

gl_set_projection_view_matrix :: (shader: u32, projection: *Matrix4, view: *Matrix4)
{
	glUseProgram(shader);
	proj_loc := glGetUniformLocation(shader, "projection");
	view_loc := glGetUniformLocation(shader, "view");
	glUniformMatrix4fv(proj_loc, 1, true, xx projection);
	glUniformMatrix4fv(view_loc, 1, true, xx view);
	glUseProgram(0);
}