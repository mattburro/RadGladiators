extends CharacterBody3D

const ANIM_IDLE := &"idle"
const ANIM_CROUCH := &"crouch"
const ANIM_WALK := &"walk"
const ANIM_RUN := &"sprint"
const ANIM_JUMP := &"jump"
const ANIM_ATTACK := &"attack-melee-right"
const ANIM_DIE := &"die"
const ANIM_INTERACT := &"interact-left"
const ANIM_PICK_UP := &"pick-up"

enum CharacterState {
	 IDLE, MOVE
}
var state: CharacterState = CharacterState.IDLE

@export var nav_region: NavigationRegion3D
@export var is_activated: bool = false
@export var move_speed: float = 3.0
@export var rotation_speed: float = 6.0

var current_target_position: Vector3

@onready var body_mesh: MeshInstance3D = %"body-mesh"
var body_original_material: StandardMaterial3D
var body_hover_material: StandardMaterial3D
@onready var head_mesh: MeshInstance3D = %"head-mesh"
var head_original_material: StandardMaterial3D
var head_hover_material: StandardMaterial3D

@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var character_model: Node3D = %"character-soldier"
@onready var static_collision: StaticBody3D = $StaticCollision
@onready var turn_indicator: MeshInstance3D = %TurnIndicator


func _ready() -> void:
	head_original_material = head_mesh.get_active_material(0)
	
	if is_activated:
		start_turn()


func _unhandled_input(event: InputEvent) -> void:
	if not is_activated:
		return
	
	# Check for click
	if event is InputEventMouseButton and event.pressed:
		var click_position = get_click_position_on_floor(event)
		print("Clicked at %s" % click_position)
		if click_position == Vector3.INF:
			push_warning("NO CLICK COLLSION WITH FLOOR")
			return
		
		# Move to click point
		move_to_position(click_position)


func _process(delta: float) -> void:
	pass


func _physics_process(delta: float) -> void:
	# Always face target position
	current_target_position = nav_agent.get_next_path_position()
	var target_direction = global_position.direction_to(current_target_position)
	
	# Smoothly rotate toward destination
	if target_direction.length() > 0.01:
		var target_angle = atan2(target_direction.x, target_direction.z)
		character_model.rotation.y = lerp_angle(character_model.rotation.y, target_angle, rotation_speed * delta)
	
	match state:
		CharacterState.IDLE:
			animation_player.play(ANIM_IDLE, 0.3)
		CharacterState.MOVE:
			velocity = target_direction * move_speed
			animation_player.play(ANIM_WALK)
	
	move_and_slide()


func start_turn():
	is_activated = true
	turn_indicator.show()
	bake_nav_mesh_without_me()


func end_turn():
	turn_indicator.hide()
	is_activated = false


func move_to_position(target_position: Vector3):
	var nav_map = nav_agent.get_navigation_map()
	var closest_target_position = NavigationServer3D.map_get_closest_point(nav_map, target_position)
	print("%s moving to %s" % [name, closest_target_position])
	nav_agent.target_position = closest_target_position
	
	# DEBUG
	nav_agent.debug_enabled = true
	
	state = CharacterState.MOVE


func bake_nav_mesh_without_me():
	# Temporarily remove this character's collision
	static_collision.collision_layer = 0
	
	# Rebake
	nav_region.bake_navigation_mesh()
	
	# Restore collision
	static_collision.collision_layer = 2 # Characters


func become_idle():
	# "Cease all motors functions"
	current_target_position = Vector3.ZERO
	velocity = Vector3.ZERO
	
	# DEBUG
	nav_agent.debug_enabled = false
	
	state = CharacterState.IDLE


#func rotate_to_face_position(target_pos: Vector3, duration: float = 0.2):
	#print("%s is turning to face at %s" % [name, target_pos])
	#
	## Get the angle to the target
	#var direction = target_pos - global_position
	#var target_angle = atan2(direction.x, direction.z)
	#
	## Get the current angle
	#var start_angle = rotation.y
	#
	## Calculate shortest angular distance
	#var angle_diff = angle_difference(rotation.y, target_angle)
	#var final_angle = rotation.y + angle_diff
	#
	## Create rotation tween
	#var tween = create_tween()
	#tween.tween_method(
		#func(progress: float):
			#rotation.y = lerp_angle(start_angle, final_angle, progress),
		#0.0,
		#1.0,
		#duration
	#)
	#tween.set_trans(Tween.TRANS_CUBIC)
	#tween.set_ease(Tween.EASE_OUT)


## Gets the 3d world position of where the floor was clicked. Returns Vector3.INF for no collision.
func get_click_position_on_floor(event: InputEventMouseButton) -> Vector3:
	var camera = get_viewport().get_camera_3d()
	var mouse_pos = event.position
	
	# Create ray from camera through mouse position
	var from = camera.project_ray_origin(mouse_pos)
	var to = from + camera.project_ray_normal(mouse_pos) * 1000
	
	# Perform raycast
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = 1 # Only check the floor
	var result = space_state.intersect_ray(query)
	
	if result:
		return result.position
	else:
		return Vector3.INF


func _on_nav_agent_target_reached() -> void:
	print("%s reached their target position at %s" % [name, nav_agent.target_position])
	become_idle()


func _on_nav_agent_waypoint_reached(details: Dictionary) -> void:
	print("%s reached a waypoint at %s" % [name, details.position])


func _on_hover_detection_area_mouse_entered() -> void:
	print("Mouse hovered over %s" % name)


func _on_hover_detection_area_mouse_exited() -> void:
	print("Mouse no longer hovered over %s" % name)


func _on_enemy_detection_area_body_entered(body: Node3D) -> void:
	var parent_body = get_parent_character_body(body)
	if parent_body != null:
		print("%s entered %s's enemy detection area" % [parent_body.name, name])


func _on_enemy_detection_area_body_exited(body: Node3D) -> void:
	var parent_body = get_parent_character_body(body)
	if parent_body != null:
		print("%s exited %s's enemy detection area" % [parent_body.name, name])


func get_parent_character_body(body_to_check: Node3D, max_level: int = 3):
	var current_body: Node3D = body_to_check
	var current_level := 1
	while current_level <= max_level and current_body != null and current_body is not CharacterBody3D:
		current_body = current_body.get_parent_node_3d()
		current_level += 1
	
	return current_body
