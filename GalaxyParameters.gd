extends ItemList

@onready var galactic_root = get_parent().get_parent().get_parent().get_parent()

#									 <--rotation-->  <---arms---->  <--medium---> <-bulge-> <--noisemap-->
var parameters = [1.0, 0.2, 1.0, 0.0, 1.0, 1.0, 5.0, 3.0, 1.0, 0.5, 0.5, 1.3, 0.7, 4.0, 0.0, 0.1, 0.2, 0.2]

var galaxy_size = 1000*1000
#Should have a value for galaxy size in amount of stars
#Should have a value for galaxy size in radius (slightly increases/decreases radius from expected)
#Should have a value for last few seed bits.
#Possibly a value for quality? -> Gas shaders

var sliders = []
var labels = []
var buttons = []

func _ready():
	add_item("galaxy_type", null, false)
	add_item("galaxy_shape_displacement", null, false)
	add_item("galaxy_spin", null, false)
	add_item("noisiness", null, false)
	
	add_item("rotation_noise", null, false)
	add_item("rotation_noise_detail", null, false)
	add_item("rotation_amount", null, false)
	
	add_item("arms_amount", null, false)
	add_item("arms_twist", null, false)
	add_item("arms_flocculence", null, false)
	
	add_item("medium_size", null, false)
	add_item("medium_noise", null, false)
	add_item("medium_power", null, false)
	
	add_item("bulge_size", null, false)
	add_item("bulge_barness", null, false)
	
	add_item("noise_mapping", null, false)
	add_item("noise_map_x", null, false)
	add_item("noise_map_y", null, false)
	
	for i in range(parameters.size()):
		var slider_width = 180
		var hs = HSlider.new()
		hs.min_value = -15.0
		hs.max_value = 15.0
		hs.step = 0.02
		hs.value = parameters[i]
		hs.size = Vector2(slider_width, 20)
		hs.editable = true
		hs.scrollable = true
		var pos = Vector2(330, 7 + 27*i)
		hs.set_global_position(pos, false)
		sliders.append(hs)
		add_child.call_deferred(hs)
		
		var label = Label.new()
		label.set_global_position(pos - Vector2(60, 0))
		labels.append(label)
		#add_child.call_deferred(hs)
		add_child(label)
		
		var button = Button.new()
		button.size = Vector2(20, 20)
		button.set_global_position(pos - Vector2(90, 0))
		buttons.append(button)
		add_child(button)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	for i in range(parameters.size()):
		parameters[i] = sliders[i].value
		labels[i].text = str(parameters[i])
		if(buttons[i].is_pressed()):
			sliders[i].value = galactic_root.current_parameters[i]
