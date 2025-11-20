extends Node3D

var characters: Array[CharacterBody3D] = []
var active_char_idx: int = -1


func _ready() -> void:
	# Register characters
	characters.assign(get_tree().get_nodes_in_group("characters"))
	
	# Make the first one active
	activate_next_char()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.is_pressed():
		var key_event = event as InputEventKey
		if key_event.keycode == KEY_ENTER:
			activate_next_char()


func activate_next_char():
	# First activation
	if active_char_idx == -1:
		active_char_idx = 0
		characters[active_char_idx].start_turn()
	else:
		characters[active_char_idx].end_turn()
		active_char_idx += 1
		active_char_idx = wrap(active_char_idx, 0, characters.size())
		characters[active_char_idx].start_turn()
	
	print("Character %s activated" % active_char_idx)
