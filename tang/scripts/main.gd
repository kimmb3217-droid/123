extends Node2D

@onready var player: Node2D = $Player
@onready var hud: CanvasLayer = $HUD

var bat_scene: PackedScene = preload("res://scenes/bat_enemy.tscn")

var game_time: float = 0.0
var spawn_timer: float = 0.0
var swarm_event_timer: float = 60.0
var is_game_over: bool = false

# 3분(180초) 직전 500마리 대규모 잡몹 러시 및 장군 특별 웨이브 발동 체크
var triggered_pre_boss_rush_3m: bool = false
var triggered_boss_wave_3m: bool = false
var triggered_boss_wave_4m: bool = false

func _ready() -> void:
	get_tree().paused = false
	
	player.connect("health_changed", Callable(hud, "update_health"))
	player.connect("exp_changed", Callable(hud, "update_exp"))
	player.connect("control_mode_changed", Callable(hud, "update_control_mode"))
	player.connect("auto_attack_toggled", Callable(hud, "update_auto_attack"))
	player.connect("level_up_triggered", Callable(self, "_on_player_level_up"))
	player.connect("skill_points_changed", Callable(hud, "update_skill_points"))
	player.connect("kill_count_changed", Callable(hud, "update_kills"))
	player.connect("player_died", Callable(self, "_on_player_died"))
	
	if hud.has_node("SkillTreeModal"):
		var skill_modal = hud.get_node("SkillTreeModal")
		if skill_modal.has_method("set_player_ref"):
			skill_modal.set_player_ref(player)
	
	hud.connect("upgrade_selected", Callable(player, "apply_upgrade"))
	hud.connect("restart_requested", Callable(self, "_restart_game"))
	
	hud.call("update_health", player.get("current_hp"), player.get("max_hp"))
	hud.call("update_exp", player.get("current_exp"), player.get("exp_to_next"), player.get("level"))
	if player.has_method("get_control_mode_name"):
		hud.call("update_control_mode", player.call("get_control_mode_name"))
	else:
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
		
	# 3분(180초) 직전 (2분 40초 ~ 3분 00초): 오크 장군 절대 미등장 & 잡몹 500마리 폭풍 대공세
	if not triggered_pre_boss_rush_3m and game_time >= 160.0:
		triggered_pre_boss_rush_3m = true
		_trigger_pre_boss_minion_storm(500)
		
	# 3분(180초) 정각: 잡몹 500마리 공세 이후 오크 장군과 호위 부대 동시 돌격
	if not triggered_boss_wave_3m and game_time >= 180.0:
		triggered_boss_wave_3m = true
		_trigger_orc_rider_wave(4, 25) # 오크 라이더 4마리 + 호위병 100마리
		
	# 4분(240초) 도달 시 오크 장군 강화 대규모 웨이브 발동
	if not triggered_boss_wave_4m and game_time >= 240.0:
		triggered_boss_wave_4m = true
		_trigger_orc_rider_wave(6, 30) # 오크 라이더 6마리 + 호위병 180마리
		
	swarm_event_timer -= delta
	if swarm_event_timer <= 0.0:
		swarm_event_timer = 60.0
		_trigger_minion_swarm(50)

func _get_active_orc_rider_count() -> int:
	var count: int = 0
	var riders: Array[Node] = get_tree().get_nodes_in_group("orc_rider")
	for r in riders:
		if is_instance_valid(r) and not r.get("is_dead") and r.is_inside_tree() and r.visible:
			count += 1
	return count

# 시간대별 가중치 테이블(Weighted Table) 데이터
# 0~1분: 박쥐 전용 (60초까지 오크/늑대/장군 미등장)
# 1분(60초): 오크 등장 시작
# 2분(120초): 늑대 등장 시작
# 3분(180초): 오크 장군 등장 시작
const SPAWN_TIMELINE: Array[Dictionary] = [
	{
		"time": 0.0,
		"weights": { "bat_enemy": 100.0, "orc_enemy": 0.0, "werewolf_enemy": 0.0, "orc_rider_enemy": 0.0 }
	},
	{
		"time": 60.0, # 1분: 오크 등장 시작 직전 (여기까지는 박쥐 100%)
		"weights": { "bat_enemy": 100.0, "orc_enemy": 0.0, "werewolf_enemy": 0.0, "orc_rider_enemy": 0.0 }
	},
	{
		"time": 120.0, # 2분: 오크 비중 상승 및 늑대 등장 시작 직전
		"weights": { "bat_enemy": 65.0, "orc_enemy": 35.0, "werewolf_enemy": 0.0, "orc_rider_enemy": 0.0 }
	},
	{
		"time": 180.0, # 3분: 늑대 활성화 및 오크 장군 등장 시작 직전
		"weights": { "bat_enemy": 40.0, "orc_enemy": 40.0, "werewolf_enemy": 20.0, "orc_rider_enemy": 0.0 }
	},
	{
		"time": 300.0, # 5분: 오크 장군/늑대 안착
		"weights": { "bat_enemy": 20.0, "orc_enemy": 35.0, "werewolf_enemy": 35.0, "orc_rider_enemy": 10.0 }
	},
	{
		"time": 480.0, # 8분 이후: 후반부 고난도 구성
		"weights": { "bat_enemy": 10.0, "orc_enemy": 30.0, "werewolf_enemy": 45.0, "orc_rider_enemy": 15.0 }
	}
]

# 시간 경과에 따라 가중치를 부드럽게 선형 보간(Lerp)하여 단절 없는 스폰 구현
func _get_current_spawn_weights() -> Dictionary:
	var result: Dictionary = { "bat_enemy": 100.0, "orc_enemy": 0.0, "werewolf_enemy": 0.0, "orc_rider_enemy": 0.0 }
	
	if game_time <= SPAWN_TIMELINE[0]["time"]:
		return SPAWN_TIMELINE[0]["weights"].duplicate()
		
	var last_idx: int = SPAWN_TIMELINE.size() - 1
	if game_time >= SPAWN_TIMELINE[last_idx]["time"]:
		result = SPAWN_TIMELINE[last_idx]["weights"].duplicate()
	else:
		for i in range(last_idx):
			var cur_point = SPAWN_TIMELINE[i]
			var next_point = SPAWN_TIMELINE[i + 1]
			if game_time >= cur_point["time"] and game_time < next_point["time"]:
				var t: float = (game_time - cur_point["time"]) / (next_point["time"] - cur_point["time"])
				for key in cur_point["weights"].keys():
					var w_start: float = float(cur_point["weights"][key])
					var w_end: float = float(next_point["weights"][key])
					result[key] = lerpf(w_start, w_end, t)
				break

	# 3분(180초) 이전에는 오크 라이더가 절대 스폰되지 않도록 엄격 차단
	if game_time < 180.0 or _get_active_orc_rider_count() >= 4:
		result["orc_rider_enemy"] = 0.0
		
	return result

func _select_enemy_by_weight() -> String:
	var weights: Dictionary = _get_current_spawn_weights()
	var total_weight: float = 0.0
	for w in weights.values():
		total_weight += float(w)
		
	if total_weight <= 0.0:
		return "bat_enemy"
		
	var roll: float = randf() * total_weight
	var cumulative: float = 0.0
	for enemy_name in weights.keys():
		cumulative += float(weights[enemy_name])
		if roll <= cumulative:
			return enemy_name
			
	return "bat_enemy"

func _spawn_enemy() -> void:
	if not is_instance_valid(player) or bool(player.get("is_dead")):
		return
		
	var angle: float = randf() * TAU
	var spawn_dist: float = randf_range(420.0, 520.0)
	var spawn_pos: Vector2 = player.global_position + Vector2.RIGHT.rotated(angle) * spawn_dist
	
	var enemy_type: String = _select_enemy_by_weight()
	
	# 시간 경과에 따른 완만한 스탯 배율 (HP: 분당 10% 증가, 속도: 분당 2% 증가 - 최대 25% 상한)
	var minutes: float = game_time / 60.0
	var hp_mult: float = 1.0 + (minutes * 0.10)
	var speed_mult: float = clamp(1.0 + (minutes * 0.02), 1.0, 1.25)
	
	var enemy: Node2D = PoolManager.spawn(enemy_type, self) as Node2D
	enemy.global_position = spawn_pos
	enemy.call("setup_stats", hp_mult, speed_mult)

# 3분 직전(2분 40초)에 발동하는 잡몹 500마리 폭풍 대공세
# 프레임 드랍(스파이크) 없이 화면을 가득 메우도록 약 12초에 걸쳐 고밀도로 분할 소환
func _trigger_pre_boss_minion_storm(total_count: int) -> void:
	if not is_instance_valid(player) or bool(player.get("is_dead")):
		return
		
	var batch_count: int = 25
	var batches: int = int(ceil(float(total_count) / float(batch_count)))
	
	for b in range(batches):
		var delay: float = float(b) * 0.45 # 0.45초 간격으로 25마리씩 분할 스폰 (약 9초 동안 지속)
		get_tree().create_timer(delay).timeout.connect(func():
			if not is_instance_valid(player) or bool(player.get("is_dead")):
				return
			for i in range(batch_count):
				var angle: float = randf() * TAU
				var dist: float = randf_range(420.0, 560.0)
				var pos: Vector2 = player.global_position + Vector2.RIGHT.rotated(angle) * dist
				
				# 잡몹 구성: 박쥐 50%, 일반 오크 35%, 늑대 15% (오크 장군은 일절 없음)
				var roll := randf()
				var m_type: String = "bat_enemy"
				if roll < 0.50:
					m_type = "bat_enemy"
				elif roll < 0.85:
					m_type = "orc_enemy"
				else:
					m_type = "werewolf_enemy"
					
				var enemy: Node2D = PoolManager.spawn(m_type, self) as Node2D
				enemy.global_position = pos
				enemy.call("setup_stats", 1.0, 1.0)
		)

# 3분, 4분에 대규모로 쏟아지는 오크 장군(Orc Rider) 특별 웨이브
func _trigger_orc_rider_wave(rider_count: int, minion_per_rider: int) -> void:
	if not is_instance_valid(player) or bool(player.get("is_dead")):
		return
		
	var minutes: float = game_time / 60.0
	var hp_mult: float = 1.0 + (minutes * 0.10)
	var speed_mult: float = clamp(1.0 + (minutes * 0.02), 1.0, 1.25)
	
	for r_idx in range(rider_count):
		var rider_angle: float = (float(r_idx) / float(rider_count)) * TAU + randf_range(-0.1, 0.1)
		var rider_pos: Vector2 = player.global_position + Vector2.RIGHT.rotated(rider_angle) * 480.0
		
		# 오크 장군 스폰
		var rider: Node2D = PoolManager.spawn("orc_rider_enemy", self) as Node2D
		rider.global_position = rider_pos
		rider.call("setup_stats", hp_mult, speed_mult)
		
		# 오크 장군을 호위하는 돌격 호위대 (늑대와 오크 중심)
		for m_idx in range(minion_per_rider):
			var offset_angle: float = randf() * TAU
			var offset_dist: float = randf_range(15.0, 80.0)
			var minion_pos: Vector2 = rider_pos + Vector2.RIGHT.rotated(offset_angle) * offset_dist
			
			var minion_type: String = "bat_enemy"
			if game_time >= 120.0:
				if m_idx % 3 == 0:
					minion_type = "werewolf_enemy"
				elif m_idx % 3 == 1:
					minion_type = "orc_enemy"
			else:
				minion_type = "orc_enemy" if (m_idx % 2 == 0) else "bat_enemy"
				
			var minion: Node2D = PoolManager.spawn(minion_type, self) as Node2D
			minion.global_position = minion_pos
			minion.call("setup_stats", hp_mult, speed_mult)

# 주기적 일반 서지(Surge) 스폰
func _trigger_minion_swarm(count: int) -> void:
	if not is_instance_valid(player) or bool(player.get("is_dead")):
		return
		
	var angle_base: float = randf() * TAU
	for i in range(count):
		var angle: float = angle_base + randf_range(-0.4, 0.4)
		var dist: float = randf_range(440.0, 520.0)
		var pos: Vector2 = player.global_position + Vector2.RIGHT.rotated(angle) * dist
		var m_type: String = "bat_enemy"
		if game_time >= 120.0 and i % 3 == 0:
			m_type = "werewolf_enemy"
		elif game_time >= 60.0 and i % 2 == 0:
			m_type = "orc_enemy"
			
		var enemy: Node2D = PoolManager.spawn(m_type, self) as Node2D
		enemy.global_position = pos
		enemy.call("setup_stats", 1.0, 1.0)

func _on_player_level_up(_new_level: int) -> void:
	hud.call("show_level_up")

func _on_player_died() -> void:
	is_game_over = true
	hud.call("show_game_over", game_time, player.get("kill_count"))

func _restart_game() -> void:
	triggered_pre_boss_rush_3m = false
	triggered_boss_wave_3m = false
	triggered_boss_wave_4m = false
	PoolManager.clear_all()
	get_tree().paused = false
	get_tree().reload_current_scene()
