extends Node3D

@onready var tt_shape = $"Shape Texture Viewport"
@onready var tt_detail = $"Detail Texture Viewport"
@onready var tt_hd_shape = $"Shape High Res"
@onready var tt_hd_detail = $"Detail High Res"

var texture3D_1
var texture3D_2
var texture3D_3
var texture3D_4
var spiralColor = Vector3(0.0, 0.0, 1.0)

var x = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	#set_uniform_parameters()
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	refresh_textures()

func regenerate():
	x = 1

func refresh_textures():
	if(x == 1):
		refresh_textures_step_1()
		x += 1
	elif(x == 2):
		refresh_textures_step_2()
		x = 0

func refresh_textures_step_1():
	tt_shape.set_update_mode(1)
	tt_detail.set_update_mode(1)
	tt_hd_shape.set_update_mode(1)
	tt_hd_detail.set_update_mode(1)

func refresh_textures_step_2():
	
	var imagedata = []
	var viewportTexture_1 = tt_shape.get_texture().get_image()
	viewportTexture_1.save_png("textures/galaxy/distribution_1.png")
	for i in range(128):
		for j in range(1):
			imagedata.append(viewportTexture_1.get_region(Rect2i(Vector2(j, i*128), Vector2(128, 128))))
	texture3D_1 = ImageTexture3D.new()
	texture3D_1.create(viewportTexture_1.get_format(), 128, 128, 128, false, imagedata)
	
	imagedata = []
	var viewportTexture_2 = tt_detail.get_texture().get_image()
	viewportTexture_2.save_png("textures/galaxy/distribution_2.png")
	for i in range(128):
		for j in range(1):
			imagedata.append(viewportTexture_2.get_region(Rect2i(Vector2(j, i*128), Vector2(128, 128))))
	texture3D_2 = ImageTexture3D.new()
	texture3D_2.create(viewportTexture_2.get_format(), 128, 128, 128, false, imagedata)
	
	"""
	imagedata = []
	var viewportTexture_3 = tt_hd_shape.get_texture().get_image()
	viewportTexture_3.save_png("textures/galaxy/hd_1.png")
	for i in range(16):
		for j in range(16):
			imagedata.append(viewportTexture_3.get_region(Rect2i(Vector2(j*256, i*256), Vector2(256, 256))))
	texture3D_3 = ImageTexture3D.new()
	texture3D_3.create(viewportTexture_3.get_format(), 256, 256, 256, false, imagedata)
	var x : int = 0
	var images = texture3D_3.get_data()
	for i in imagedata:
		i.save_png("debug/" + str(x) + ".png")
		x += 1
	
	imagedata = []
	var viewportTexture_4 = tt_hd_detail.get_texture().get_image()
	viewportTexture_4.save_png("textures/galaxy/hd_2.png")
	for i in range(16):
		for j in range(16):
			imagedata.append(viewportTexture_4.get_region(Rect2i(Vector2(j*256, i*256), Vector2(256, 256))))
	texture3D_4 = ImageTexture3D.new()
	texture3D_4.create(viewportTexture_4.get_format(), 256, 256, 256, false, imagedata)
	"""

func set_color(clr : Vector3):
	spiralColor = clr

func set_uniform_parameters(parameters):
	#spiralColor = Vector3(0.0, 1.0, 0.0)
	#0 = Distribution 1 - Shape
	#1 = Distribution 2 - Detail
	#2 = High Res 1		- Shape
	#3 = High Res 2		- Detail
	for i in range(4):
		#GENERAL PARAMETERS
		get_child(i).get_child(0).material.set_shader_parameter("galaxy_type", parameters[0])
		get_child(i).get_child(0).material.set_shader_parameter("galaxy_shape_displacement", parameters[1])
		get_child(i).get_child(0).material.set_shader_parameter("galaxy_spin", parameters[2])
		get_child(i).get_child(0).material.set_shader_parameter("noisiness", parameters[3])
		#ROTATION TWIST PARAMETERS
		get_child(i).get_child(0).material.set_shader_parameter("rotation_noise", parameters[4])
		get_child(i).get_child(0).material.set_shader_parameter("rotation_noise_detail", parameters[5])
		get_child(i).get_child(0).material.set_shader_parameter("rotation_amount", parameters[6])
		#SPIRAL PARAMETERS
		get_child(i).get_child(0).material.set_shader_parameter("arms_amount", parameters[7])
		get_child(i).get_child(0).material.set_shader_parameter("arms_twist", parameters[8])
		get_child(i).get_child(0).material.set_shader_parameter("arms_flocculence", parameters[9])
		#DISC PARAMETERS
		get_child(i).get_child(0).material.set_shader_parameter("medium_size", parameters[10])
		get_child(i).get_child(0).material.set_shader_parameter("medium_noise", parameters[11])
		get_child(i).get_child(0).material.set_shader_parameter("medium_power", parameters[12])
		#BULGE PARAMETERS
		get_child(i).get_child(0).material.set_shader_parameter("bulge_size", parameters[13])
		get_child(i).get_child(0).material.set_shader_parameter("bulge_barness", parameters[14])
		#NOISE MAP PARAMETERS
		get_child(i).get_child(0).material.set_shader_parameter("noise_mapping", parameters[15])
		get_child(i).get_child(0).material.set_shader_parameter("noise_map_x", parameters[16])
		get_child(i).get_child(0).material.set_shader_parameter("noise_map_y", parameters[17])
		
