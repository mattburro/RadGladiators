class_name Unit extends Path3D

@export var grid: Grid
## Distance the unit can move in tiles.
@export var move_range := 5
@export var move_speed: float = 2.0
@export var model: Node3D
@export var model_anim_player: AnimationPlayer

## Coordinates of the grid tile the units is on.
var coordinates := Vector2i.ZERO
var is_selected := false:
	get:
		return is_selected
	set(value):
		is_selected = value
		if is_selected:
			unit_animation_player.play("selected")
		else:
			unit_animation_player.play("idle")
var is_walking := false:
	get:
		return is_walking
	set(value):
		is_walking = value
		set_process(is_walking)

@onready var unit_animation_player: AnimationPlayer = %UnitAnimationPlayer
@onready var path: PathFollow3D = $"."
