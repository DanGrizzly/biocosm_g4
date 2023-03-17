extends SubViewport



# Declare member variables here. Examples:
var viewportTexture
var frame = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	#var loadedTex = load("textures/prototype_high_res.png")
	#print(loadedTex.get_depth())
	#var images = loadedTex.get_data()
	#for i in range((images.size())):
	#	var path = "debug/"+str(i)+".png"
	#	images[i].save_png(path)
		#print(path)
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass
	#frame = frame + 1
	#if(frame == 1):
		#viewportTexture = get_texture()
		#viewportTexture.get_image().save_png("textures/EXR_high_res_1.png")
