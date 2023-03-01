extends Node

export var g: float = 10000
var game_ready: bool = false
var setting_planet : bool = false
var cm := Vector2()
var total_mass :float = 0
var initial_conditions : Array = [] # [mass, velocity, position]
var predicted_conditions : Array  = [] # [mass, velocity, position]
var Planet = preload("res://Actors/Planet.tscn")
var PlanetSetter = preload("res://API/PlanetSetter.tscn")
var Trajectory = preload("res://Trajectories/Trajectory.tscn")
var ic_changed = false

func _ready():
	add_to_group("Sandbox")
	

func _physics_process(delta):
	
	if game_ready == false:
		set_planets()
		if ic_changed == false:
			predict_orbits()
	
	if game_ready:
		update_force()

# set the planets at the begin of the program
func set_planets():
	if Input.is_action_just_pressed("Click") and setting_planet == false:
		setting_planet = true
		var planet = Planet.instance()
		planet.position = $Camera2D.get_global_mouse_position()
		$Planets.add_child(planet)
		var setter = PlanetSetter.instance()
		$Setters.add_child(setter)
		setter.popup()
		var trajectory = Trajectory.instance()
		$Trajectories.add_child(trajectory)
		

# pop_up setter "finish" button pressed
func planet_setted():
	setting_planet = false
	ic_changed = true
	$ResetTrajectories.start()
	var last_popup = $Setters.get_child($Setters.get_child_count() - 1)
	last_popup.hide()
	var mass = last_popup.find_node("Mass", true, true).text
	var vx0 = last_popup.find_node("VelX", true, true).text
	var vy0 = last_popup.find_node("VelY", true, true).text
	var pos = $Planets.get_child($Planets.get_child_count() - 1).position
	initial_conditions.append( [float(mass), Vector2(float(vx0), float(vy0)), pos ])
	predicted_conditions = initial_conditions.duplicate(true)
	for pc in predicted_conditions:
		pc[1] = pc[1] * 2
	
	for trajectory in $Trajectories.get_children():
		trajectory.clear_points()
		
	#update_predictions()
	

# Set initial conditions
func set_initial_conditions():
	for i in range($Planets.get_child_count() - 1):
		$Planets.get_child(i).mass = initial_conditions[i][0]
		$Planets.get_child(i).linear_velocity = initial_conditions[i][1]
		
	
	
# predict the orbits
func predict_orbits():
	# Midpoint method:
	for i in range(predicted_conditions.size()):
		if $Trajectories.get_child(i).get_point_count() < 100:
			var pos :Vector2 = predicted_conditions[i][2] 
			var new_pos : Vector2 = pos
			var current_velocity : Vector2 = predicted_conditions[i][1] 
			var new_velocity : Vector2 = current_velocity
			var pos_med := pos  + 0.5 * current_velocity *get_physics_process_delta_time() # For the midpoint method
			for j in (predicted_conditions.size()):
				if predicted_conditions[i] != predicted_conditions[j]:
					var force_dir: Vector2 = (predicted_conditions[j][2] - pos_med).normalized()
					var quad_dist : float = (predicted_conditions[j][2] - pos_med).length_squared()
					var aceleration_med =  4 * g  * predicted_conditions[j][0]*force_dir/quad_dist
					new_velocity +=  aceleration_med * get_physics_process_delta_time()
			new_pos += 0.5 *  (current_velocity + new_velocity) * get_physics_process_delta_time()
			predicted_conditions[i][2] = new_pos
			predicted_conditions[i][1] = new_velocity
			$Trajectories.get_child(i).add_point(new_pos)
			
# Euler Method:
#	for i in range(predicted_conditions.size()):
#		if $Trajectories.get_child(i).get_point_count() < 500:
#			var pos :Vector2 = predicted_conditions[i][2] 
#			var current_velocity : Vector2 = predicted_conditions[i][1] 
#			for j in (predicted_conditions.size()):
#				if predicted_conditions[i] != predicted_conditions[j]:
#					var force_dir: Vector2 = (predicted_conditions[j][2] - pos).normalized()
#					var quad_dist : float = (predicted_conditions[j][2] - pos).length_squared()
#					var aceleration =  4 * g * predicted_conditions[j][0]*force_dir/quad_dist
#					current_velocity +=  aceleration * get_physics_process_delta_time()
#			pos += current_velocity * get_physics_process_delta_time()
#			predicted_conditions[i][2] = pos
#			predicted_conditions[i][1] = current_velocity
#			$Trajectories.get_child(i).add_point(pos)

#			-------------------------------------------------------------

# I have to work in this!!! maybe update the initial conditions instead.
#func update_predictions():
#	if initial_conditions.size() > 0:
#		for trajectory in $Trajectories.get_children():
#			trajectory.clear_points()
#
#		for i in range($Setters.get_child_count()):
#			var setter = $Setters.get_child(i)
#			var mass = setter.find_node("Mass", true, true).text
#			var vx0 = setter.find_node("VelX", true, true).text
#			var vy0 = setter.find_node("VelY", true, true).text
#			var planet = [float(mass), Vector2(float(vx0), float(vy0)), $Planets.get_child(i).position ]
#			predicted_conditions[i] = planet
		
# Update the force foreach planet every physics frame
func update_force():
	for planet1 in $Planets.get_children():
		var force := Vector2()
		for planet2 in $Planets.get_children():
			if planet1 != planet2:
				var force_dir: Vector2 = (planet2.position - planet1.position).normalized()
				var quad_dist : float = (planet2.position - planet1.position).length_squared()
				force += g*planet1.mass*planet2.mass*force_dir/quad_dist
		planet1.set_applied_force(force)
	
		

# The player has finished setting the planets
func _on_Ready_pressed():
	game_ready = true
	$HUD/Ready.hide()
	$Planets.get_child($Planets.get_child_count() - 1).queue_free()
	$Setters.get_child($Setters.get_child_count() - 1).queue_free()
	
	set_initial_conditions()
	#$Trajectories.queue_free()

func _on_ResetTrajectories_timeout():
	ic_changed = false
	print("ic", initial_conditions)
	print("predicted", predicted_conditions)
