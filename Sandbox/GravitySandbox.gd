extends Node

export var g: float = 1000
var planets_moving := 0
var game_ready: bool = false
var setting_planet : bool = false
var cm := Vector2()
var total_mass :float = 0
var initial_conditions : Array = [] # [mass, velocity, position, size]
var predicted_conditions : Array  = [] # [mass, velocity, position]
var Planet = preload("res://Actors/Planet.tscn")
var PlanetSetter = preload("res://API/NodeSet.tscn")
var Trajectory = preload("res://Trajectories/Trajectory.tscn")
var ic_changed = true
var cam_vel : Vector2
var drawing = false
var pos1 : Vector2
var pos2 : Vector2
var celestial_body_index : int = 0
var first_menu := true
var save_path = "user://"


func _ready():
	add_to_group("Sandbox")
	Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED) # El mouse no puede salir de la pantalla.
	
	
func _process(_delta):
	# Camera movement
	cam_vel = Vector2()
	
	if !setting_planet:
		cam_vel.x = Input.get_action_strength("right") - Input.get_action_strength("left")
		cam_vel.y = Input.get_action_strength("down") - Input.get_action_strength("up")
	
	cam_vel = cam_vel.normalized() * 30
	$MovingCamera.position += cam_vel
	
	
	# Menu
	if Input.is_action_just_pressed("escape") and first_menu == false:
		$Menu/Principal.visible = !$Menu/Principal.visible
#	
	
# ............this is new ------------
# a planet is moving
func body_moving():
	planets_moving += 1
	
	
func body_released():
	planets_moving -= 1
#-----------------------------

func _physics_process(_delta):
	

	if game_ready and drawing:
		update_force()
		draw_trajectories()
		change_view()
		
	
	elif first_menu == false:
		
		load_state()
		set_planets()
		if ic_changed == false:
			predict_orbits()
		
		if $Planets.get_child_count() != 0:
			$HUD/Ready.disabled = false
		else:
			$HUD/Ready.disabled = true


#---------------- Camera Motion with mouse --------------


	
func _input(event):
	# Moving Camera Zoom
	if event is InputEventMouseButton and event.pressed and $MovingCamera.current == true:
		if event.button_index == BUTTON_WHEEL_UP and $MovingCamera.zoom > Vector2(0.5, 0.5):
			$MovingCamera.zoom *= 0.95
		if event.button_index == BUTTON_WHEEL_DOWN and $MovingCamera.zoom < Vector2(5, 5):
			$MovingCamera.zoom *= 1.05
	
		

# -------------- Stage 0 ----------------------

func start_fase0():
	first_menu = false
	$StartMenu/FirstMenu.hide()
	$HUD/Ready.show()
	$HUD/Message.show()


# -------------- First stage --------------------------
func setter_visible():
	setting_planet = true
	
func setter_invisible():
	setting_planet = false
# [mass, velocity, position, size]
var system_loaded = false
func load_state():
	if initial_conditions.size() > 0 and system_loaded == false:
		$HUD/Message.hide()
		for i in range(initial_conditions.size()):
			var planet = Planet.instance()
			planet.position = initial_conditions[i][2]
			planet.my_index = celestial_body_index
			#planet.mass = initial_conditions[i][0]
			$Planets.add_child(planet)
			planet.get_node("AnimationPlayer").play(initial_conditions[i][3])
			
			
			var setter = PlanetSetter.instance()
			setter.get_node("PlanetSetter").my_index = celestial_body_index
			setter.get_node("PlanetSetter/Panel/MassContainer/Mass").text = str(initial_conditions[i][0])
			setter.get_node("PlanetSetter/Panel/VelContainer/VelX").text = str(initial_conditions[i][1].x)
			setter.get_node("PlanetSetter/Panel/VelContainer/VelY").text = str(initial_conditions[i][1].y)
			setter.get_node("PlanetSetter/Panel/PosContainer/PosX").text = str(initial_conditions[i][2].x)
			setter.get_node("PlanetSetter/Panel/PosContainer/PosY").text = str(initial_conditions[i][2].y)
			$Setters.add_child(setter)
#			setter.get_node("PlanetSetter").popup()
			
			var trajectory = Trajectory.instance()
			$Trajectories.add_child(trajectory)
			
			celestial_body_index += 1
		update_initial_conditions()
	system_loaded = true

# set the planets at the begin of the program
func set_planets():
	if Input.is_action_just_pressed("right_click") and $Menu/Principal.visible == false:

		$HUD/Message.hide()
		
		var planet = Planet.instance()
		planet.position = $Camera2D.get_global_mouse_position()
		planet.my_index = celestial_body_index
		planet.set_mode(3)
		$Planets.add_child(planet)
		
		var setter = PlanetSetter.instance()
		setter.get_node("PlanetSetter").my_index = celestial_body_index
		setter.get_node("PlanetSetter/Panel/PosContainer/PosX").text =  "%.3f" % planet.position.x
		setter.get_node("PlanetSetter/Panel/PosContainer/PosY").text = "%.3f" % planet.position.y
		$Setters.add_child(setter)
		setter.get_node("PlanetSetter").popup()
		
		var trajectory = Trajectory.instance()
		$Trajectories.add_child(trajectory)
		
		celestial_body_index += 1
		
		initial_conditions.append([])
		update_initial_conditions()
		


func update_size(size, index):
	var to_edit_planet = $Planets.get_child(0)# The planet to edit
	for planet in $Planets.get_children():
		if planet.my_index == index:
			to_edit_planet = planet
			
			break
	if size == 'big':
		to_edit_planet.get_node("AnimationPlayer").play('Big')
	elif size == 'small':
		to_edit_planet.get_node("AnimationPlayer").play('Small')
	else:
		to_edit_planet.get_node("AnimationPlayer").play('Medium')
	update_initial_conditions()


func update_initial_conditions():
	ic_changed = true 
	$ResetTrajectories.start()

	for i in range(initial_conditions.size()):
		var mass = $Setters.get_child(i).find_node("Mass", true, true).text
		var vx0 = $Setters.get_child(i).find_node("VelX", true, true).text
		var vy0 = $Setters.get_child(i).find_node("VelY", true, true).text
#		var pos = $Planets.get_child(i).position
		var posx = $Setters.get_child(i).find_node("PosX", true, true).text
		var posy = $Setters.get_child(i).find_node("PosY", true, true).text
		var size = $Planets.get_child(i).get_node("AnimationPlayer").get_current_animation()

		initial_conditions[i] = [float(mass), Vector2(float(vx0), float(vy0)), Vector2(float(posx), float(posy)), size]
	
		$Planets.get_child(i).position = initial_conditions[i][2]

	
	predicted_conditions = initial_conditions.duplicate(true)
	for pc in predicted_conditions:
		pc[1] = pc[1] * 3	# duplicate the velocity for the simulation  !
	
	for trajectory in $Trajectories.get_children():
		trajectory.clear_points()
	#print(initial_conditions)

# update the position in the seters every time a body is moved
func update_position():
	for i in range($Planets.get_child_count()):
		$Setters.get_child(i).get_node("PlanetSetter/Panel/PosContainer/PosX").text = "%.3f" % $Planets.get_child(i).position.x
		$Setters.get_child(i).get_node("PlanetSetter/Panel/PosContainer/PosY").text = "%.3f" % $Planets.get_child(i).position.y
	update_initial_conditions()


	
# Delete planet with setter   (REVISARR) Parece que ya no la uso
func cancel_planet(index):
	var i = 0
	for planet in $Planets.get_children():
		if planet.my_index == index:
			planet.queue_free()
			$Trajectories.get_child(i).queue_free()
			$Setters.get_child(i).queue_free()
			predicted_conditions.remove(i)
			initial_conditions.remove(i)
			update_initial_conditions()
			return
		i += 1
	

# predict the orbits
func predict_orbits():
	# Midpoint method:
	for i in range(predicted_conditions.size()):
		if $Trajectories.get_child(i).get_point_count() < 2000:
			var pos :Vector2 = predicted_conditions[i][2] 
			var new_pos : Vector2 = pos
			var current_velocity : Vector2 = predicted_conditions[i][1] 
			var new_velocity : Vector2 = current_velocity
			var pos_med := pos  + 0.5 * current_velocity *get_physics_process_delta_time()/2 # For the midpoint method
			for j in (predicted_conditions.size()):
				if predicted_conditions[i] != predicted_conditions[j]:
					var force_dir: Vector2 = (predicted_conditions[j][2] - pos_med).normalized()
					var quad_dist : float = (predicted_conditions[j][2] - pos_med).length_squared()
					var aceleration_med = 9 *  g  * predicted_conditions[j][0]*force_dir/quad_dist
					new_velocity +=  aceleration_med * get_physics_process_delta_time()/2
			new_pos += 0.5 *  (current_velocity + new_velocity) * get_physics_process_delta_time()/2
			predicted_conditions[i][2] = new_pos
			predicted_conditions[i][1] = new_velocity
			$Trajectories.get_child(i).add_point(new_pos)
			
			
# initial_conditions : Array = [] # [mass, velocity, position, size]
# predicted_conditions : Array  = [] # [mass, velocity, position]
func to_test_predict_orbits():
	var n = $Planets.get_child_count()
	var step = 1/60
	#Euler
	for i in range(n):
		if $Trajectories.get_child(i).get_point_count() < 2000:
			var pos = predicted_conditions[i][2] # pos
			var mass = predicted_conditions[i][0] # mass
			var vel = predicted_conditions[i][1] # vel
			for j in range(n):
				if i != j:
					var force_dir = (predicted_conditions[j][2] - pos).normalized()
					var quad_dist = (predicted_conditions[j][2] - pos).length_squared()
					var accel = g * force_dir * mass / quad_dist
					vel += accel * step
			pos += vel * step
			predicted_conditions[i][2] = pos
			predicted_conditions[i][1] = vel
			$Trajectories.get_child(i).add_point(pos)

		
		
			
# reset trajectories (maybe this is useless)
func _on_ResetTrajectories_timeout():
	ic_changed = false
#	print("ic", initial_conditions)
#	print("predicted", predicted_conditions)
#	print("ic_changed", ic_changed)


# popup the set options for the selected body
func update_celestial_body(index):
	for set in $Setters.get_children():
		if set.get_node("PlanetSetter").my_index == index:
			set.get_node("PlanetSetter").popup()

#---------------------------------------------------------------


# --------------- Simulation started ---------------------------
# The player has finished setting the planets
func _on_Ready_pressed():
	game_ready = true
	$HUD/Ready.hide()
	#$Planets.get_child($Planets.get_child_count() - 1).queue_free()
	#$Setters.get_child($Setters.get_child_count() - 1).queue_free()
	set_initial_conditions()
	
	for trajectory in $Trajectories.get_children():
		trajectory.clear_points()
		
	$StartDrawing.start()
	
	$Menu/Principal/CameraOptions.disabled = false
	
# Set initial conditions to the planets.
func set_initial_conditions():
	#print('set initial')
	for planet in $Planets.get_children():
		planet.queue_free()
	for i in range((initial_conditions).size()):
		var planet = Planet.instance()
		planet.mass = initial_conditions[i][0]
		planet.linear_velocity = initial_conditions[i][1]
		planet.position = initial_conditions[i][2]
		planet.set_mode(0)
#		planet.find_node("AnimationPlayer", false, true).set_current_animation(initial_conditions[i][3])
		$Planets.add_child(planet)
		planet.get_node("AnimationPlayer").play(initial_conditions[i][3])
		
	get_tree().call_group('Planets', 'game_started')
#	for i in range($Planets.get_child_count() - 1):
#		$Planets.get_child(i).mass = initial_conditions[i][0]
#		$Planets.get_child(i).linear_velocity = initial_conditions[i][1]
#		$Planets.get_child(i).position = initial_conditions[i][2]

	
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
	

	
		
func draw_trajectories():
	if can_draw:
		var maxlen = 10000/$Planets.get_child_count() if $Planets.get_child_count() != 0 else 0
		for i in range($Planets.get_child_count()):
			
			if $Trajectories.get_child(i).get_point_count() > maxlen:
				$Trajectories.get_child(i).remove_point(0)
			
			if $FollowCamera.current == true:
				$Trajectories.get_child(i).position = $FollowCamera.position
				$Trajectories.get_child(i).add_point($Planets.get_child(i).position - $FollowCamera.position)
			else:
				$Trajectories.get_child(i).position = $Camera2D.position
				$Trajectories.get_child(i).add_point($Planets.get_child(i).position)


func _on_StartDrawing_timeout():
	for trajectory in $Trajectories.get_children():
		trajectory.clear_points()
	drawing = true


#---------------- Principal (not first) menu (pause) --------------------

func _on_Restart_pressed():
	get_tree().reload_current_scene()


func _on_Exit_pressed():
	get_tree().quit()


func _on_Continue_pressed():
	$Menu/Principal.hide()

#----------------------------

#--------- Camera ----------------
var following_body := 0
var can_draw = true

func change_view():
	$FollowCamera.position = $Planets.get_child(following_body).position
	if Input.is_action_just_pressed("change_cam"):
		can_draw = false
		if following_body < $Planets.get_child_count() - 1:
			following_body += 1
		else:
			following_body = 0
		reset_trajectories()


func _on_CameraOptions_item_selected(index):
	can_draw = false
	if index == 0:
		$MovingCamera.current = true
	elif index == 1:
		$FollowCamera.current = true
	reset_trajectories()

func reset_trajectories():
	yield(get_tree().create_timer(0.1),"timeout")
	can_draw = true
	for trajectory in $Trajectories.get_children():
		trajectory.clear_points()

#--------- save and load -----------

func _on_Save_pressed():
	$StartMenu/SaveMenu.popup_centered()

func _on_SaveMenu_index_pressed(index):
	var ic_file = File.new()
	var current_path = save_path + $StartMenu/SaveMenu.get_item_text(index) + ".dat"
	var error = ic_file.open(current_path, File.WRITE)
	if error == OK:
		ic_file.store_var(initial_conditions)
		ic_file.close()
		$HUD/SaveMessage.text = "data saved"
		$HUD/SaveMessage.show()
		yield(get_tree().create_timer(0.5), "timeout")
		$HUD/SaveMessage.hide()

		
		

func _on_Load_pressed():
	$StartMenu/LoadMenu.popup_centered()

func _on_LoadMenu_index_pressed(index):
	var ic_file = File.new()
	var current_path = save_path + $StartMenu/LoadMenu.get_item_text(index) + ".dat"
	if ic_file.file_exists(current_path):
		var error = ic_file.open(current_path, File.READ)
		if error == OK:
			initial_conditions = ic_file.get_var()
			ic_file.close()
			start_fase0()
