extends Node3D

@onready var multimesher = $"MultiMesher"
@onready var medium = $"Galaxy Medium"
@onready var texturer = $"Galaxy Texture Generation"
@onready var ui_control_list = $"Galaxy_Control_UI".get_child(0).get_child(0).get_child(0)
@onready var ui_control_color = $"Galaxy_Control_UI".get_child(0).get_child(0).get_child(2)

var frame = 0
var regenframes = 5

var current_parameters = []

# Called when the node enters the scene tree for the first time.
func _ready():
	check_regen()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	frame = min(1000, frame + 1)
	if(frame > 5):
		check_regen()
	
	multimesher.set_size(ui_control_list.galaxy_size)

func regenerate():
	regenframes = 5

func check_regen():
	if(regenframes == 0):
		pass
	#FRAME 0
	if(regenframes == 5):
		current_parameters = ui_control_list.parameters.duplicate()
		print("Regenerating Galaxy...")
		texturer.set_uniform_parameters(ui_control_list.parameters)
	#FRAME 1, FRAME 2
	if(regenframes == 4):
		print("		Generating textures, processing them...")
		texturer.regenerate()
	#FRAME 3
	if(regenframes == 2):
		print("		Setting textures...")
		multimesher.setTextures(texturer.texture3D_1, texturer.texture3D_2)
		medium.get_child(0).mesh.material.set_shader_parameter("viewportTexture_1", texturer.texture3D_1)
		medium.get_child(0).mesh.material.set_shader_parameter("viewportTexture_2", texturer.texture3D_2)
		var clr = ui_control_color.color
		texturer.set_color(Vector3(clr.r, clr.g, clr.b))
		medium.get_child(0).mesh.material.set_shader_parameter("spiralColor", texturer.spiralColor)
		medium.get_child(0).mesh.material.set_shader_parameter("galaxyRadius", multimesher.galactic_radius)
		medium.get_child(0).mesh.size = 2.0*multimesher.galactic_radius*Vector3(1.0, 1.0, 1.0)
	#FRAME 4
	if(regenframes == 1):
		print("		Setting positions...")
		multimesher.refresh_galaxy_positions()
	regenframes = max(0, regenframes - 1)
