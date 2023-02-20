extends SubViewport



# Declare member variables here. Examples:
var viewportTexture
var frame = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	frame = frame + 1
	if(frame == 2):
		viewportTexture = get_texture()
		viewportTexture.get_image().save_png("textures/prototype_ex2_galaxy.png")
