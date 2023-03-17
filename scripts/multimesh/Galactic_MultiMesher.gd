extends Node3D

var gT1 = load("textures/galaxy/distribution_1.png") #galaxyMediumTexture
var gT2 = load("textures/galaxy/distribution_2.png") #galaxyDetailTexture
#var gT1 = load("textures/prototype_high_res.png")
#var gT2 = load("textures/high_res_2.png")

var n_of_instances = 1000000
var galactic_radius = 30

var mains = []
var giants = []
var dwarfs = []
var neb_emi = []
var neb_ref = []
var neb_abs = []

@onready var mm_main_stars = $"Systems/Stars/MM_Main_Stars"
@onready var mm_giant_stars = $"Systems/Stars/MM_Giant_Stars"
@onready var mm_dwarf_stars = $"Systems/Stars/MM_Dwarf_Stars"
@onready var mm_emissive_nebulae = $"Nebulae/Diffuse/MM_Emissive"
@onready var mm_reflective_nebulae = $"Nebulae/Diffuse/MM_Reflective"
@onready var mm_multimeshes = [mm_main_stars, mm_giant_stars, mm_dwarf_stars,
					mm_emissive_nebulae, mm_reflective_nebulae]
@onready var mm_instances = [mains, giants, dwarfs,
					neb_emi, neb_ref]
@onready var mm_intended = [ceil(0.8*0.7871*n_of_instances), ceil(0.8*0.0272*n_of_instances), ceil(0.8*0.1856*n_of_instances),
					4*galactic_radius, 4*galactic_radius, ceil(0.2*n_of_instances)]

var normal_giants = 0
var super_giants = 0
var white_dwarfs = 0
var brown_dwarfs = 0

var frame = 0

func _ready():
	pass

func _process(_delta):
	#frame = min(1000, frame + 1)
	#if(frame == 4):
	#	refresh_galaxy_positions()
	pass

func set_size(n):
	n_of_instances = n
	galactic_radius = galactic_mass_radius(n/1000)

func setTextures(tex1, tex2):
	gT1 = tex1
	gT2 = tex2

func refresh_galaxy_positions():
	var size = galactic_radius * 2
	
	mains.clear()
	giants.clear()
	dwarfs.clear()
	neb_emi.clear()
	neb_ref.clear()
	neb_abs.clear()
	
	var gT1_slices = gT1.get_data()
	var gT2_slices = gT2.get_data()
	var pixel_resolution = gT1_slices[0].get_width()
	
	var full_tex_s = 0.0
	var full_emi_s = 0.0
	var full_ref_s = 0.0
	var full_tex_colors = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
	var first_index
	var first_index_unset = true
	
	#Irrespective of objects, assesses volume of textures at each pixel
	for z in range(pixel_resolution):
		var slice_gT1 = gT1_slices[z]
		var slice_gT2 = gT2_slices[z]
		for x in range(pixel_resolution):
			for y in range(pixel_resolution):
				var pixel_gT1 = slice_gT1.get_pixel(x, y)
				var pixel_gT2 = slice_gT2.get_pixel(x, y)
				var pixel_s = Vector3(pixel_gT1.r, pixel_gT1.g, pixel_gT1.b).length()
				if (pixel_s > 0.01):
					if(first_index_unset):
						first_index_unset = false
						first_index = Vector3(x, y, z)
					full_tex_s += pixel_s
					full_emi_s += pixel_gT2.r*max(pixel_gT1.r, pixel_gT1.g)
					full_ref_s += pixel_gT2.b*max(pixel_gT1.r, pixel_gT1.g)
					var colors = [pixel_gT1.r, pixel_gT1.g, pixel_gT1.b, pixel_gT2.r, pixel_gT2.g, pixel_gT2.b]
					for i in range(colors.size()):
						full_tex_colors[i] += colors[i]
	
	#Goes through each texture pixel and plants stars accordingly
	for z in range(first_index.z, pixel_resolution - first_index.z + 1):
		var slice_gT1 = gT1_slices[z]
		var slice_gT2 = gT2_slices[z]
		for x in range(pixel_resolution):
			for y in range(pixel_resolution):
				
				var pixel_gT1 = slice_gT1.get_pixel(x, y)
				var pixel_gT2 = slice_gT2.get_pixel(x, y)
				var s = Vector3(pixel_gT1.r, pixel_gT1.g, pixel_gT1.b).length()
				var colors = [pixel_gT1.r, pixel_gT1.g, pixel_gT1.b, pixel_gT2.r, pixel_gT2.g, pixel_gT2.b]
				
			#MULTIPLE-STAR SYSTEMS
				var inst_for_this_pixel = (s/full_tex_s) * mm_intended[-1]
				if (randf() < inst_for_this_pixel - floor(inst_for_this_pixel)):
					inst_for_this_pixel = ceil(inst_for_this_pixel)
				else:
					inst_for_this_pixel = floor(inst_for_this_pixel)
				for system in range(inst_for_this_pixel):
					#var primary = get_main(pixel_resolution/2.0, x, y, z, size)
					#var secondary = get_main(pixel_resolution/2.0, x, y, z, size)
					#get_binary([primary], [secondary])
					#mains.append(primary)
					#mains.append(secondary)
					var bary = get_coord(pixel_resolution/2.0, x, y, z, size)
					
					var primary_list = []
					var secondary_list = []
					var insts_list = []
					
					if(randf() < 0.15):
						var type1 = randf()
						var type2 = randf()
						var primary = get_system(bary, type1)
						var secondary = get_system(bary, type2)
						get_binary([primary], [secondary], 2.0)
						primary_list.append(primary)
						primary_list.append(secondary)
						insts_list.append(get_type(type1))
						insts_list.append(get_type(type2))
					else:
						var type = randf()
						var primary = get_system(bary, type)
						primary_list.append(primary)
						insts_list.append(get_type(type))
					
					if(randf() < 0.15):
						var type1 = randf()
						var type2 = randf()
						var primary = get_system(bary, type1)
						var secondary = get_system(bary, type2)
						get_binary([primary], [secondary], 2.0)
						secondary_list.append(primary)
						secondary_list.append(secondary)
						insts_list.append(get_type(type1))
						insts_list.append(get_type(type2))
					else:
						var type = randf()
						var primary = get_system(bary, type)
						primary_list.append(primary)
						insts_list.append(get_type(type))
					
					var bary_transform = Transform3D(Basis(), bary).rotated(Vector3.RIGHT, PI/2.0)
					get_binary(primary_list, secondary_list, 1.5)
					
					var insts = 0
					for i in primary_list:
						mm_instances[insts_list[insts]].append(i)
						insts += 1
					for i in secondary_list:
						mm_instances[insts_list[insts]].append(i)
						insts += 1
				
			#MAIN STARS
				inst_for_this_pixel = (s/full_tex_s) * mm_intended[0]
				inst_for_this_pixel = max(0, round(inst_for_this_pixel + randi_range(-inst_for_this_pixel*.15, inst_for_this_pixel*.15)))
				if (randf() < inst_for_this_pixel - floor(inst_for_this_pixel)):
					inst_for_this_pixel = ceil(inst_for_this_pixel)
				else:
					inst_for_this_pixel = floor(inst_for_this_pixel)
				
				for star in range(inst_for_this_pixel):
					var instance = get_main(get_coord(pixel_resolution/2.0, x, y, z, size))
					mains.append(instance)
			#GIANT STARS
				inst_for_this_pixel = (s/full_tex_s) * mm_intended[1]
				if (randf() < inst_for_this_pixel - floor(inst_for_this_pixel)):
					inst_for_this_pixel = ceil(inst_for_this_pixel)
				else:
					inst_for_this_pixel = floor(inst_for_this_pixel)
				
				for giant in range(inst_for_this_pixel):
					var instance = get_giant(get_coord(pixel_resolution/2.0, x, y, z, size))
					giants.append(instance)
			#DWARF STARS
				inst_for_this_pixel = (s/full_tex_s) * mm_intended[2]
				#stars_for_this_pixel = max(0, round(stars_for_this_pixel))
				if (randf() < inst_for_this_pixel - floor(inst_for_this_pixel)):
					inst_for_this_pixel = ceil(inst_for_this_pixel)
				else:
					inst_for_this_pixel = floor(inst_for_this_pixel)
				
				for dwarf in range(inst_for_this_pixel):
					var instance = get_dwarf(get_coord(pixel_resolution/2.0, x, y, z, size))
					dwarfs.append(instance)
			#EMISSIVE NEBULAE		
				inst_for_this_pixel = (colors[3]/full_emi_s*max(pixel_gT1.r, pixel_gT1.g)) * mm_intended[3]
				
				if(randf() < inst_for_this_pixel):
					var pr = pixel_resolution/2.0
					var uv3D = Vector3((x - pr + .5)/(2*pr), (y - pr + .5)/(2*pr), (z - pr + .5)/(2*pr))
					var coord = size * (uv3D + (1.0/pixel_resolution) * Vector3(randf()-.5, randf()-.5, randf()-.5))
					var rot_coord = coord.rotated(Vector3.RIGHT, PI/2.0)
					var realcoord = Transform3D(Basis(), rot_coord)
					var custom_data = Color(rot_coord.x,rot_coord.y,rot_coord.z,randf())
					var custom_color = Color(randf(), randf(), randf(), randf())
					var instance = [realcoord, custom_data, custom_color]
					neb_emi.append(instance)
			#REFLECTIVE NEBULAE		
				inst_for_this_pixel = (colors[4]/full_ref_s*max(pixel_gT1.r, pixel_gT1.g)) * mm_intended[4]
				
				if(randf() < inst_for_this_pixel):
					var pr = pixel_resolution/2.0
					var uv3D = Vector3((x - pr + .5)/(2*pr), (y - pr + .5)/(2*pr), (z - pr + .5)/(2*pr))
					var coord = size * (uv3D + (1.0/pixel_resolution) * Vector3(randf()-.5, randf()-.5, randf()-.5))
					var rot_coord = coord.rotated(Vector3.RIGHT, PI/2.0)
					var realcoord = Transform3D(Basis(), rot_coord)
					var custom_data = Color(rot_coord.x,rot_coord.y,rot_coord.z,randf())
					var custom_color = Color(randf(), randf(), randf(), randf())
					var instance = [realcoord, custom_data, custom_color]
					neb_ref.append(instance)
	
	print_count()
	
	for i in range(mm_multimeshes.size()):
		mm_creation(mm_multimeshes[i], mm_instances[i])

func mm_creation(mm_inst, instances):
	mm_inst.multimesh = MultiMesh.new()
	mm_inst.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	mm_inst.multimesh.mesh = mm_inst.get_child(0).mesh.duplicate()
	mm_inst.multimesh.use_custom_data = true
	mm_inst.multimesh.use_colors = true
	mm_inst.multimesh.instance_count = instances.size()
	for i in range(instances.size()):
		var tf = instances[i][0]
		var ctm = instances[i][1]
		var clr = instances[i][2]
		mm_inst.multimesh.set_instance_transform(i, tf)
		mm_inst.multimesh.set_instance_custom_data(i, ctm)
		mm_inst.multimesh.set_instance_color(i, clr)
		
func refresh_galaxy_textures():
	pass

func galactic_mass_radius(x):
	#Inverse == y = exp(sqrt(x/2)
	#2.0*pow(log(x), 2.0)
	return 1.5*pow(log(x), 2.0)

func star_temp_distribution(t, type):
	match type:
		"general":
			var d = 12.0*sqrt(t);
			var x = t + (sin(t*PI*2.0))/d;
			return max(0.0, pow(x, 2.0));
		"open":
			return 0.0
		"globular":
			return 0.0

func print_count():
	print("Main Sequence = ", mains.size()," Intended = ", mm_intended[0])
	print("Giants = ", giants.size(), " Normal = ", normal_giants, " Super = ", super_giants, " Intended = ", mm_intended[1])
	print("Dwarves = ", dwarfs.size(), " White = ", white_dwarfs, " Brown = ", brown_dwarfs, " Intended = ", mm_intended[2])
	print("Emmissive Nebulae = ", neb_emi.size()," Intended = ", mm_intended[3])
	print("Reflective Nebulae = ", neb_ref.size()," Intended = ", mm_intended[4])

func get_binary(primary, secondary, strength):
	var r1 = randf()/(strength*100.0)
	var r2 = randf()/(strength*100.0)
	var dir = Vector3(randf(), randf(), randf()).normalized()
	for i in range(len(primary)):
		primary[i][0] = primary[i][0].translated(r1*dir)
	for i in range(len(secondary)):
		secondary[i][0] = secondary[i][0].translated(-r2*dir)

func get_system(coord, type):
	#ceil(0.8*0.7871*n_of_instances), ceil(0.8*0.0272*n_of_instances), ceil(0.8*0.1856*n_of_instances
	var system
	if(type < 0.0272):
		system = get_giant(coord)
	elif(type < 0.1856):
		system = get_dwarf(coord)
	else:
		system = get_main(coord)
	return system

func get_coord(pr, x, y, z, size):
	var uv3D = Vector3((x - pr + .5)/(2*pr), (y - pr + .5)/(2*pr), (z - pr + .5)/(2*pr))
	var coord = size * (uv3D + (0.5/pr) * Vector3(randf()-.5, randf()-.5, randf()-.5))
	return coord

func get_type(f):
	if(f < 0.0272):
		return 2
	elif(f < 0.1856):
		return 1
	else:
		return 0

func get_main(coord):
	#var pr = pixel_resolution/2.0
	#var uv3D = Vector3((x - pr + .5)/(2*pr), (y - pr + .5)/(2*pr), (z - pr + .5)/(2*pr))
	#var coord = size * (uv3D + (0.5/pr) * Vector3(randf()-.5, randf()-.5, randf()-.5))
	var randtemp = star_temp_distribution(randf(), "general")
	var tw_infl = randf()*0.3+1.5;
	var tw_peri = randf()*4.0+1.0;
	var realcoord = Transform3D(Basis(), coord).rotated(Vector3.RIGHT, PI/2.0)
	var custom_data = Color(randtemp,tw_peri,tw_infl,0.0)
	var custom_color = Color(0.0,0.0,0.0,0.0)
	var instance = [realcoord, custom_data, custom_color]
	return instance

func get_giant(coord):
	#var uv3D = Vector3((x - pr + .5)/(2*pr), (y - pr + .5)/(2*pr), (z - pr + .5)/(2*pr))
	#var coord = size * (uv3D + (0.5/pr) * Vector3(randf()-.5, randf()-.5, randf()-.5))
	var randtemp = star_temp_distribution(randf(), "general")
	var tw_infl = randf()*0.3+1.5
	var tw_peri = randf()*4.0+1.0
	var giantness = round(randf())
	if(giantness == 0):
		normal_giants += 1
	else:
		super_giants += 1
	var realcoord = Transform3D(Basis(), coord).rotated(Vector3.RIGHT, PI/2.0)
	var custom_data = Color(randtemp,tw_peri,tw_infl,giantness)
	var custom_color = Color(0.0,0.0,0.0,0.0)
	var instance = [realcoord, custom_data, custom_color]
	return instance

func get_dwarf(coord):
	#var uv3D = Vector3((x - pr + .5)/(2*pr), (y - pr + .5)/(2*pr), (z - pr + .5)/(2*pr))
	#var coord = size * (uv3D + (0.5/pr) * Vector3(randf()-.5, randf()-.5, randf()-.5))
	var dwarfness = randf()
	if(dwarfness >= 0.3):
		white_dwarfs += 1
	else:
		brown_dwarfs += 1
	var realcoord = Transform3D(Basis(), coord).rotated(Vector3.RIGHT, PI/2.0)
	var custom_data = Color(dwarfness,0.0,0.0,0.0)
	var custom_color = Color(0.0,0.0,0.0,0.0)
	var instance = [realcoord, custom_data, custom_color]
	return instance

func get_remnant():
	return []

