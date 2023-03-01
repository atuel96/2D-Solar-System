extends CanvasLayer


func _ready():
	$Principal.hide()
	$Principal/CameraOptions.add_item("Free Camera")
	$Principal/CameraOptions.add_item("Follow body")
	

	$G/GValue.text = str(get_tree().get_root().get_node("GravitySandbox").g)

func _process(_delta):
	$G.visible = $Principal.visible
