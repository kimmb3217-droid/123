extends Area2D

@export var exp_value: int = 1
var player: Node2D = null
var is_attracted: bool = false
var speed: float = 0.0
var max_speed: float = 550.0

@onready var visual: Node2D = $Visual

func _ready() -> void:
	add_to_group("exp_gem")
	var tween: Tween = create_tween().set_loops()
	tween.tween_property(visual, "scale", Vector2(1.2, 1.2), 0.4).set_trans(Tween.TRANS_SINE)
	tween.tween_property(visual, "scale", Vector2(0.9, 0.9), 0.4).set_trans(Tween.TRANS_SINE)

func setup(value: int = 1) -> void:
	exp_value = value

func _physics_process(delta: float) -> void:
	if player == null:
		var players: Array[Node] = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			player = players[0] as Node2D
		return
		
	var dist: float = global_position.distance_to(player.global_position)
	var magnet_range: float = 85.0
	if "magnet_radius" in player:
		magnet_range = float(player.get("magnet_radius"))
	
	if dist <= magnet_range:
		is_attracted = true
		
	if is_attracted:
		speed = move_toward(speed, max_speed, 1200.0 * delta)
		var dir: Vector2 = (player.global_position - global_position).normalized()
		global_position += dir * speed * delta
		
		if dist <= 16.0:
			if player.has_method("add_exp"):
				player.add_exp(exp_value)
			queue_free()
