extends MultiMeshInstance3D

var galaxyTexture = load("textures/prototype_ex1_galaxy.png")
var n_of_instances = 1000000

func _ready():
	#texture_setup()
	#classic_setup()
	pass

func texture_setup():
	multimesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = $"StarQuad_Mold".mesh.duplicate()
	
	multimesh.use_custom_data = true
	
	
	var size = 30
	size = 2 * size
	
	var galaxySlices = galaxyTexture.get_data()
	var pixel_resolution = galaxyTexture.get_width()
	
	var stars = []
	var full_s = 0.0
	
	for z in range(pixel_resolution):
		var slice = galaxySlices[z]
		for x in range(pixel_resolution):
			for y in range(pixel_resolution):
				var pixel = slice.get_pixel(x, y)
				var s = Vector3(pixel.r, pixel.g, pixel.b).length()
				full_s += s
	
	for z in range(pixel_resolution):
		var slice = galaxySlices[z]
		for x in range(pixel_resolution):
			for y in range(pixel_resolution):
				var pixel = slice.get_pixel(x, y)
				var s = Vector3(pixel.r, pixel.g, pixel.b).length()
				var stars_for_this_pixel = (s/full_s) * n_of_instances
				stars_for_this_pixel = max(0, round(stars_for_this_pixel + randi_range(-stars_for_this_pixel*.15, stars_for_this_pixel*.15)))
				
				for star in range(stars_for_this_pixel):
					var pr = pixel_resolution/2.0
					var uv3D = Vector3((x - pr + .5)/(2*pr), (y - pr + .5)/(2*pr), (z - pr + .5)/(2*pr))
					var coord = size * (uv3D + (1.0/pixel_resolution) * Vector3(randf()-.5, randf()-.5, randf()-.5))
					var randtemp = old_ist(randf())
					var tw_infl = randf()*0.3+1.5;
					var tw_peri = randf()*4.0+1.0;
					var instance = [Transform3D(Basis(), coord).rotated(Vector3.RIGHT, PI/2.0), Color(randtemp,tw_peri,tw_infl,0.0)]
					stars.append(instance)
	
	print("Main Sequence = ", stars.size()," Intended = ", n_of_instances)
	multimesh.instance_count = stars.size()
	
	for i in range(stars.size()):
		var tf = stars[i][0]
		var clr = stars[i][1]
		multimesh.set_instance_custom_data(i, clr)
		multimesh.set_instance_transform(i, tf)
	
func randsphere(R):
	var pi = 3.14159265
	var phi = randf()*2*pi
	var costheta = randf()*2 - 1
	var u = randf()
	var theta = acos( costheta )
	var r = R * pow(u , 0.33)
	
	var x = r * sin(theta) * cos(phi)
	var y = r * sin(theta) * sin(phi)
	var z = r * cos(theta)
	
	return Vector3(x,y,z)

func old_ist(t):
	#kuzeyist return 0.5+sin(t*PI*4)/5;
	#realist
	var d = 12.0*sqrt(t);
	var x = t + (sin(t*PI*2.0))/d;
	return max(0.0, pow(x, 2.0));

func classic_setup():
	multimesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = $"StarQuad_Mold".mesh.duplicate()
	
	multimesh.use_custom_data = true
	
	multimesh.instance_count = n_of_instances
	for i in range(n_of_instances):
		var radius = max(0.05, 30.0 * pow((i*1.0)/(n_of_instances*1.0), 0.7))
		var randcoord = randsphere(radius)
		var randtemp = old_ist(randf())
		var tw_infl = randf()*0.3+1.5;
		var tw_peri = randf()*4.0+1.0;
		multimesh.set_instance_custom_data(i, Color(randtemp,tw_peri,tw_infl,0.0))
		multimesh.set_instance_transform(i, Transform3D(Basis(), randcoord))

