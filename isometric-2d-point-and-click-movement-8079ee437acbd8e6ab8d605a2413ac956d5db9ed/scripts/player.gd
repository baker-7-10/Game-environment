extends Node2D

@export var move_speed: float = 100.0
@export var arrival_threshold: float = 1.0 # Smaller threshold for precise center alignment

var target_position: Vector2
var path: PackedVector2Array
var is_moving: bool = false

@onready var layer0: TileMapLayer = $"../Layer0"
@onready var layer1: TileMapLayer = $"../Layer1"

func _ready() -> void:
	# Snap initial position to tile center
	var current_tile = layer0.local_to_map(global_position)
	global_position = layer0.map_to_local(current_tile)
	print("Player initial position (snapped to center): ", global_position)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			var click_pos = get_global_mouse_position()
			print("\nNew movement requested")
			print("From: ", global_position)
			print("To: ", click_pos)
			
			var new_path = MovementUtils.get_path_to_tile(
				global_position,
				click_pos,
				layer0,
				layer1
			)
			
			if not new_path.is_empty():
				path = new_path
				is_moving = true
				target_position = path[0]
				print("Path accepted, first target: ", target_position)
				# Validate that target is different from current position
				if target_position.distance_to(global_position) < arrival_threshold:
					print("Warning: First target too close to current position!")
					_advance_to_next_target()
			else:
				print("Path was empty, movement cancelled")
			

func _process(delta: float) -> void:
	pass


func _physics_process(delta: float) -> void:
	# --------- التحكم عبر الكيبورد ---------
	var input_vector = Vector2.ZERO
	input_vector.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	input_vector.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")

	if input_vector != Vector2.ZERO:
		is_moving = false  # إيقاف أي حركة مبنية على المسار
		path.clear()

		input_vector = input_vector.normalized()
		var movement = input_vector * move_speed * delta
		global_position += movement
		# اختياري: اجعل الحركة تنتهي على مركز التايل
		# global_position = layer0.map_to_local(layer0.local_to_map(global_position))
		return

	# --------- الحركة بناءً على المسار (Pathfinding) ---------
	if not is_moving or path.is_empty():
		return

	var distance_to_target = global_position.distance_to(target_position)
	
	if distance_to_target < arrival_threshold:
		global_position = target_position
		_advance_to_next_target()
	else:
		var direction = (target_position - global_position).normalized()
		var movement = direction * move_speed * delta
		if movement.length() > distance_to_target:
			movement = direction * distance_to_target
		global_position += movement

func _advance_to_next_target() -> void:
	path.remove_at(0)
	print("Point reached, remaining points: ", path.size())
	
	if path.is_empty():
		print("Path completed")
		is_moving = false
		return
		
	target_position = path[0]
	if target_position.distance_to(global_position) < arrival_threshold:
		print("Next target too close, skipping")
		_advance_to_next_target()
	else:
		print("New target set: ", target_position)
