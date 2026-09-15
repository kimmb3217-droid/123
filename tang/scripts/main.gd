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
		_spawn_enemy()
		
	swarm_event_timer -= delta
	if swarm_event_timer <= 0.0:
		swarm_event_timer = 60.0
		_trigger_swarm_rush(12)

func _get_active_orc_rider_count() -> int:
	var count: int = 0
	var riders: Array[Node] = get_tree().get_nodes_in_group("orc_rider")
	for r in riders:
		if is_instance_valid(r) and not r.get("is_dead") and r.is_inside_tree() and r.visible:
			count += 1
	return count

func _spawn_enemy() -> void:
	if not is_instance_valid(player) or bool(player.get("is_dead")):
		return
		
	var angle: float = randf() * TAU
	var spawn_dist: float = randf_range(420.0, 520.0)
	var spawn_pos: Vector2 = player.global_position + Vector2.RIGHT.rotated(angle) * spawn_dist
	
	var p_level: int = int(player.get("level"))
	var active_riders: int = _get_active_orc_rider_count()
	
	var enemy_type: String = "bat_enemy"
	
	# 10레벨 이상일 때: 기본 평소 스폰에 오크 라이더 등장 (필드 최대 3마리 제한)
	if p_level >= 10 and active_riders < 3 and randf() < 0.25:
		enemy_type = "orc_rider_enemy"
	else:
		# 게임 시작 15초 후부터 오크 등장 확률 점진적 증가 (최대 50%)
		var orc_chance: float = clamp((game_time - 15.0) / 60.0 * 0.45, 0.0, 0.5)
		enemy_type = "orc_enemy" if (randf() < orc_chance) else "bat_enemy"
	
	var enemy: Node2D = PoolManager.spawn(enemy_type, self) as Node2D
	enemy.global_position = spawn_pos
	enemy.call("setup_stats", 1.0, 1.0)

func _trigger_swarm_rush(_count: int) -> void:
	if not is_instance_valid(player) or bool(player.get("is_dead")):
		return
		
	# 웨이브 시 오크 라이더 4마리를 중심으로, 각 오크 라이더 주변에 호위 몬스터 30마리씩(총 120마리) 동시 돌격
	var rider_count: int = 4
	var minion_per_rider: int = 30
	
	for r_idx in range(rider_count):
		var rider_angle: float = (float(r_idx) / float(rider_count)) * TAU + randf_range(-0.1, 0.1)
		var rider_pos: Vector2 = player.global_position + Vector2.RIGHT.rotated(rider_angle) * 480.0
		
		# 오크 라이더 스폰
		var rider: Node2D = PoolManager.spawn("orc_rider_enemy", self) as Node2D
		rider.global_position = rider_pos
		rider.call("setup_stats", 1.0, 1.0)
		
		# 오크 라이더 1마리당 주변 30마리 호위 몬스터 (박쥐 및 일반 오크 무리)
		for m_idx in range(minion_per_rider):
			var offset_angle: float = randf() * TAU
			var offset_dist: float = randf_range(15.0, 75.0)
			var minion_pos: Vector2 = rider_pos + Vector2.RIGHT.rotated(offset_angle) * offset_dist
			
			var minion_type: String = "orc_enemy" if (m_idx % 4 == 0) else "bat_enemy"
			var minion: Node2D = PoolManager.spawn(minion_type, self) as Node2D
			minion.global_position = minion_pos
			minion.call("setup_stats", 1.0, 1.0)

func _on_player_level_up(_new_level: int) -> void:
	hud.call("show_level_up")

func _on_player_died() -> void:
	is_game_over = true
	hud.call("show_game_over", game_time, player.get("kill_count"))

func _restart_game() -> void:
	PoolManager.clear_all()
	get_tree().paused = false
	get_tree().reload_current_scene()
