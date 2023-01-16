#import "stb_image";

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