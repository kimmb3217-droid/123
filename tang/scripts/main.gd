extends Node2D

@onready var player: Node2D = $Player
@onready var hud: CanvasLayer = $HUD

var bat_scene: PackedScene = preload("res://scenes/bat_enemy.tscn")

var game_time: float = 0.0
var spawn_timer: float = 0.0
var swarm_event_timer: float = 60.0
var is_game_over: bool = false

func _ready() -> void:
	get_tree().paused = false
	
	player.connect("health_changed", Callable(hud, "update_health"))
	player.connect("exp_changed", Callable(hud, "update_exp"))
	player.connect("auto_attack_toggled", Callable(hud, "update_auto_attack"))
	player.connect("level_up_triggered", Callable(self, "_on_player_level_up"))
	player.connect("kill_count_changed", Callable(hud, "update_kills"))
	player.connect("player_died", Callable(self, "_on_player_died"))
	
	hud.connect("upgrade_selected", Callable(player, "apply_upgrade"))
	hud.connect("restart_requested", Callable(self, "_restart_game"))
	
	hud.call("update_health", player.get("current_hp"), player.get("max_hp"))
	hud.call("update_exp", player.get("current_exp"), player.get("exp_to_next"), player.get("level"))
	hud.call("update_auto_attack", player.get("auto_attack_enabled"))
	hud.call("update_kills", 0)
	hud.call("update_timer", 0.0)

func _process(delta: float) -> void:
	if is_game_over:
		return
		
	game_time += delta
	hud.call("update_timer", game_time)
	
	_handle_spawning(delta)

func _handle_spawning(delta: float) -> void:
	spawn_timer -= delta
	
	var current_interval: float = max(0.25, 1.2 - (game_time / 180.0) * 0.8)
	
	if spawn_timer <= 0.0:
		spawn_timer = current_interval
		_spawn_bat()
		
	swarm_event_timer -= delta
	if swarm_event_timer <= 0.0:
		swarm_event_timer = 60.0
		_trigger_swarm_rush(12)

func _spawn_bat() -> void:
	if not is_instance_valid(player) or bool(player.get("is_dead")):
		return
		
	var angle: float = randf() * TAU
	var spawn_dist: float = randf_range(420.0, 520.0)
	var spawn_pos: Vector2 = player.global_position + Vector2.RIGHT.rotated(angle) * spawn_dist
	
	var bat: Node2D = bat_scene.instantiate() as Node2D
	bat.global_position = spawn_pos
	
	var hp_mult: float = 1.0 + (game_time / 120.0) * 0.8
	var speed_mult: float = min(1.4, 1.0 + (game_time / 240.0) * 0.3)
	bat.call("setup_stats", hp_mult, speed_mult)
	
	add_child(bat)

func _trigger_swarm_rush(count: int) -> void:
	if not is_instance_valid(player) or bool(player.get("is_dead")):
		return
		
	for i in range(count):
		var angle: float = (float(i) / float(count)) * TAU
		var spawn_pos: Vector2 = player.global_position + Vector2.RIGHT.rotated(angle) * 450.0
		var bat: Node2D = bat_scene.instantiate() as Node2D
		bat.global_position = spawn_pos
		add_child(bat)

func _on_player_level_up(_new_level: int) -> void:
	hud.call("show_level_up")

func _on_player_died() -> void:
	is_game_over = true
	hud.call("show_game_over", game_time, player.get("kill_count"))

func _restart_game() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()
