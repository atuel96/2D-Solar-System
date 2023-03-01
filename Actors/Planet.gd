extends RigidBody2D


var my_index : int
onready var simulation_ready = false
onready var planets_moving = get_tree().get_root().get_node("GravitySandbox").planets_moving
var drag_enabled := false
export var rad := 19
var n := 0



func _ready():
	add_to_group('Planets')
	$AnimationPlayer.play("Medium")
	#print($AnimationPlayer.get_current_animation() )
	
func _physics_process(_delta):
	if simulation_ready == false:
		var dist = abs((get_global_mouse_position() - position).length())
#		if Input.get_action_strength("right_click") and dist < rad:
		if Input.is_action_just_pressed("left_click") and dist < rad:
			drag_enabled = true
			set_planet_moving()
			get_tree().call_group("Sandbox", "body_moving")
		elif Input.get_action_strength("left_click") == 0:
			drag_enabled = false
			n = 0
			get_tree().call_group("Sandbox", "body_released")

		if drag_enabled and n < 1:
			position = get_global_mouse_position()
			get_tree().call_group("Sandbox", "update_position")
			get_tree().call_group("Sandbox", "update_celestial_body", my_index)
			
func set_planet_moving():
	n = planets_moving

func game_started():
	simulation_ready = true
