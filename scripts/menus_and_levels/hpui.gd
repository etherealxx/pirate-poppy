extends TextureRect

@export var texture_list : Array[CompressedTexture2D]

func empty_heart():
	set_texture(texture_list[1])
	
func filled_heart():
	set_texture(texture_list[0])
