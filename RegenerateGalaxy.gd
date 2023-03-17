extends Button

@onready var galactic_root = get_parent().get_parent().get_parent().get_parent()
# Called when the node enters the scene tree for the first time.
func _ready():
	pressed.connect(self._button_pressed)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

func _button_pressed():
	galactic_root.regenerate()
	
