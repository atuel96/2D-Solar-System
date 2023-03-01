extends PopupMenu


var pos :Vector2


func _ready():
	add_item('Add Celestial Body')
	add_item('Start Simulation')
	add_item('Cancel')
	#add_item('item c')
	
func _physics_process(_delta):
	if Input.is_action_just_pressed("right_click"):
		rect_position = get_global_mouse_position()
		pos = get_global_mouse_position()
		popup()


func _on_AddCelestialMenu_id_pressed(id):
	if id == 0:
		get_tree().call_group("Sandbox", "set_planets", pos)
	print(get_item_text(id))
	
	

