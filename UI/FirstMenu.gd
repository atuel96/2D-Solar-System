extends MarginContainer

onready var save_path = str(get_tree().get_root().get_node("GravitySandbox").save_path)

func _ready():
	show()



func _on_NewSystem_pressed():
	get_tree().call_group("Sandbox", "start_fase0")



