extends Popup


var my_index : int = 0
#var format_string = "Celestial Body %s"
#
func _ready():
	$Index.text = "Celestial Body %s" % str(my_index)
#	$Index.text = format_string % str(my_index)
	
func _process(_delta):
	if int($Panel/MassContainer/Mass.text) > 65535:
		$Panel/MassContainer/Mass.text = '65535'
		

func _on_Finish_pressed():
	get_tree().call_group("Sandbox", "planet_setted")
	hide()


func _on_text_changed(_new_text):
	get_tree().call_group("Sandbox", "update_initial_conditions")


func _on_SmallBox_pressed():
	$Panel/SizeContainer/BigBox.pressed = false
	$Panel/SizeContainer/MediumBox.pressed = false
	get_tree().call_group("Sandbox", "update_size", "small", my_index)

func _on_MediumBox_pressed():
	$Panel/SizeContainer/SmallBox.pressed = false
	$Panel/SizeContainer/BigBox.pressed = false
	get_tree().call_group("Sandbox", "update_size", "medium", my_index)

func _on_BigBox_pressed():
	$Panel/SizeContainer/SmallBox.pressed = false
	$Panel/SizeContainer/MediumBox.pressed = false
	get_tree().call_group("Sandbox", "update_size", "big", my_index)


func _on_Cancel_pressed():
	get_tree().call_group("Sandbox", "cancel_planet", my_index)


func _on_PlanetSetter_about_to_show():
	yield(get_tree().create_timer(0.1), "timeout")
	get_tree().call_group("Sandbox", "setter_visible")


func _on_PlanetSetter_popup_hide():
	get_tree().call_group("Sandbox", "setter_invisible")


func _on_Pos_text_changed(new_text):
	pass # Replace with function body.
