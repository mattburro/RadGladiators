class_name Grid extends Node

## The grid's size in rows and columns
@export var size := Vector2i(10, 10)
## The size of a tile in world units (aka position)
## Gonna keep it easy and say a tile is as big as 1 world unit (1m x 1m) 
@export var tile_size := Vector2(1.0, 1.0)

# Helper var to avoid doing this everywhere
var half_tile_size := tile_size / 2


## Returns the position of a tile's center
func calculate_tile_position(tile_coordinates: Vector2) -> Vector2:
	return (tile_coordinates * tile_size) + half_tile_size


## Returns the coordinates of a tile given its position
func calculate_tile_coordinates(tile_position: Vector2) -> Vector2:
	return (tile_position / tile_size).floor()


## Returns whether a tile's coordinates are within the grid
func is_within_bounds(tile_coordinates: Vector2) -> bool:
	var is_in_x_bounds := tile_coordinates.x >= 0 and tile_coordinates.x < size.x
	var is_in_y_bounds := tile_coordinates.y >= 0 and tile_coordinates.y < size.y
	return is_in_x_bounds and is_in_y_bounds


## Given a tile's coordinates, calculates its index in a 1D array
#
#      0    1    2    3    4
#     ---  ---  ---  ---  ---
# 0 | [0]  [1]  [2]  [3]  [4]
# 1 | [5]  [6]  [7]  [8]  [9]
# 2 | [10] [11] [12] [13] [14]
# 3 | [15] [16] [17] [18] [19]
# 4 | [20] [21] [22] [23] [24]
#
func as_index(tile_coordinates: Vector2) -> int:
	# We go over (x) and then down (y)
	return int(tile_coordinates.x + (size.y * tile_coordinates.y))
