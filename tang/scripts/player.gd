extends CharacterBody2D

const SpriteHelperScript = preload("res://scripts/sprite_helper.gd")
const arrow_scene = preload("res://scenes/arrow.tscn")
const wind_gust_scene = preload("res://scenes/wind_gust.tscn")
const wind_typhoon_scene = preload("res://scenes/wind_typhoon.tscn")

signal health_changed(current: float, max_val: float)
signal exp_changed(current: int, max_val: int, level: int)
signal auto_attack_toggled(is_enabled: bool)
signal level_up_triggered(level: int)
signal kill_count_changed(kills: int)
signal player_died()

@export var max_hp: float = 100.0
var current_hp: float = 100.0
@export var speed: float = 145.0

var base_damage: float = 30.0
var damage_multiplier: float = 1.0
var attack_cooldown: float = 0.5
var cooldown_timer: float = 0.0
var arrow_count: int = 1
var pierce_count: int = 1
var magnet_radius: float = 20.0

# 우클릭 특수 공격 (돌풍 및 차징 대폭풍) 관련 변수
var rmb_pressed_time: float = 0.0
var rmb_is_down: bool = false
const RMB_SHORT_CLICK_THRESHOLD: float = 0.28  # 0.28초 미만 클릭 시 짧은 클릭 판정
const RMB_CHARGE_COMPLETE_TIME: float = 0.85   # 0.85초 이상 모으면 최대 차징
var gust_cooldown: float = 3.5                 # 3.5초 쿨다운
var gust_cooldown_timer: float = 0.0
var typhoon_cooldown: float = 6.0              # 대폭풍 6초 쿨다운
var typhoon_cooldown_timer: float = 0.0
var is_charge_ready: bool = false

var auto_attack_enabled: bool = true
var target_enemy: Node2D = null

var level: int = 1
var current_exp: int = 0
var exp_to_next: int = 5
var kill_count: int = 0

var is_invulnerable: bool = false
var invuln_timer: float = 0.0
var is_dead: bool = false

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var shoot_point: Marker2D = $ShootPoint

func _ready() -> void:
	add_to_group("player")
	collision_layer = 1
	collision_mask = 0
	
	animated_sprite.sprite_frames = SpriteHelperScript.get_archer_frames()
	animated_sprite.play("idle")
	
	current_hp = max_hp
	emit_signal("health_changed", current_hp, max_hp)
	emit_signal("exp_changed", current_exp, exp_to_next, level)
	emit_signal("auto_attack_toggled", auto_attack_enabled)

func _unhandled_input(event: InputEvent) -> void:
	if is_dead:
		return
		
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_CAPSLOCK or event.physical_keycode == KEY_CAPSLOCK:
			toggle_auto_attack()

func toggle_auto_attack() -> void:
	auto_attack_enabled = not auto_attack_enabled
	emit_signal("auto_attack_toggled", auto_attack_enabled)

func _physics_process(delta: float) -> void:
	if is_dead:
		return
		
	_handle_movement(delta)
	_handle_combat(delta)
	_handle_invulnerability(delta)

func _handle_movement(_delta: float) -> void:
	var input_dir: Vector2 = Vector2.ZERO
	
	if Input.is_key_pressed(KEY_W): input_dir.y -= 1.0
	if Input.is_key_pressed(KEY_S): input_dir.y += 1.0
	if Input.is_key_pressed(KEY_A): input_dir.x -= 1.0
	if Input.is_key_pressed(KEY_D): input_dir.x += 1.0
	
	input_dir = input_dir.normalized()
	velocity = input_dir * speed
	move_and_slide()
	
	var aim_dir: Vector2 = (get_global_mouse_position() - global_position)
	if auto_attack_enabled and is_instance_valid(target_enemy):
		aim_dir = (target_enemy.global_position - global_position)
	elif input_dir != Vector2.ZERO and not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		aim_dir = input_dir
		
	if abs(aim_dir.x) > 0.05:
		animated_sprite.flip_h = (aim_dir.x < 0)
		
	if animated_sprite.animation != "attack" and animated_sprite.animation != "hurt":
		if velocity.length() > 5.0:
			if animated_sprite.animation != "walk":
				animated_sprite.play("walk")
		else:
			if animated_sprite.animation != "idle":
				animated_sprite.play("idle")

func _handle_combat(delta: float) -> void:
	cooldown_timer -= delta
	_handle_special_attack(delta)
	
	target_enemy = _find_nearest_enemy(450.0)
	
	var can_shoot: bool = (cooldown_timer <= 0.0)
	if not can_shoot:
		return
		
	var should_shoot: bool = false
	var shoot_dir: Vector2 = Vector2.RIGHT
	
	if auto_attack_enabled:
		if is_instance_valid(target_enemy):
			should_shoot = true
			shoot_dir = (target_enemy.global_position - global_position).normalized()
		elif Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			should_shoot = true
			shoot_dir = (get_global_mouse_position() - global_position).normalized()
	else:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			should_shoot = true
			shoot_dir = (get_global_mouse_position() - global_position).normalized()
			
	if should_shoot and shoot_dir.length_squared() > 0.01:
		_shoot(shoot_dir)
		cooldown_timer = attack_cooldown

func _handle_special_attack(delta: float) -> void:
	if gust_cooldown_timer > 0.0:
		gust_cooldown_timer -= delta
	if typhoon_cooldown_timer > 0.0:
		typhoon_cooldown_timer -= delta

	if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		rmb_is_down = true
		rmb_pressed_time += delta
		
		# 차징 시각적 피드백 (0.28초 이상 누르고 있을 때부터 기 모으기 시작)
		if rmb_pressed_time >= RMB_SHORT_CLICK_THRESHOLD:
			if typhoon_cooldown_timer <= 0.0:
				if rmb_pressed_time >= RMB_CHARGE_COMPLETE_TIME:
					# 풀차징 완료 시 금빛/청록빛으로 강하게 발광
					animated_sprite.modulate = Color(1.5, 2.3, 3.0, 1.0)
				else:
					# 차징 중 깜빡임/파동
					var pulse := 1.0 + sin(rmb_pressed_time * 24.0) * 0.4
					animated_sprite.modulate = Color(pulse, pulse * 1.3, pulse * 1.8, 1.0)
	else:
		if rmb_is_down:
			# 버튼을 뗐을 때 일반 색상 복구
			if not is_invulnerable:
				animated_sprite.modulate = Color(1, 1, 1, 1)
				
			if rmb_pressed_time < RMB_SHORT_CLICK_THRESHOLD:
				# [짧게 클릭]: 전방 돌풍
				if gust_cooldown_timer <= 0.0:
					_execute_wind_gust()
			else:
				# [길게 차징 클릭]: 360도 대폭풍 (풀차징 완료 시)
				if rmb_pressed_time >= RMB_CHARGE_COMPLETE_TIME:
					if typhoon_cooldown_timer <= 0.0:
						_execute_wind_typhoon()
				else:
					# 차징을 채우지 못하고 도중에 뗐을 때 (일반 돌풍 발동 또는 취소)
					if gust_cooldown_timer <= 0.0:
						_execute_wind_gust()
						
			rmb_is_down = false
			rmb_pressed_time = 0.0

func _execute_wind_gust() -> void:
	gust_cooldown_timer = gust_cooldown
	
	var aim_dir: Vector2 = (get_global_mouse_position() - global_position).normalized()
	if aim_dir.length_squared() < 0.01:
		aim_dir = Vector2.RIGHT if not animated_sprite.flip_h else Vector2.LEFT
		
	# 캐릭터 시선 방향도 돌풍 방향에 맞춰 정렬
	animated_sprite.flip_h = (aim_dir.x < 0)
	
	# 돌풍 인스턴스 생성 및 배치
	var gust_node: Node2D = wind_gust_scene.instantiate() as Node2D
	get_parent().add_child(gust_node)
	
	# 기본 데미지 25 (플레이어 데미지 배율 적용), 적당한 넉백 320, 기절 1.3초, 전방 사거리 160px
	var gust_dmg: float = 25.0 * damage_multiplier
	gust_node.call("setup", global_position, aim_dir, gust_dmg, 320.0, 1.3, 160.0)
	
	# 플레이어 살짝 번쩍임 피드백
	var tween := create_tween()
	animated_sprite.modulate = Color(1.8, 2.2, 2.5)
	tween.tween_property(animated_sprite, "modulate", Color(1, 1, 1), 0.15)

func _execute_wind_typhoon() -> void:
	typhoon_cooldown_timer = typhoon_cooldown
	# 짧은 쿨다운도 함께 적용하여 동시 연속 발사 방지
	gust_cooldown_timer = max(gust_cooldown_timer, 1.5)
	
	# 360도 거대 회오리 인스턴스 생성 및 배치
	var typhoon_node: Node2D = wind_typhoon_scene.instantiate() as Node2D
	get_parent().add_child(typhoon_node)
	
	# 데미지 65 (2.6배 위력), 넉백 520, 기절 2.6초(2배 지속), 전방위 360도 반경 210px
	var typhoon_dmg: float = 65.0 * damage_multiplier
	typhoon_node.call("setup", global_position, typhoon_dmg, 520.0, 2.6, 210.0)
	
	# 강력한 시각/충격 피드백 (플레이어 플래시)
	var tween := create_tween()
	animated_sprite.modulate = Color(3.0, 3.0, 3.5)
	tween.tween_property(animated_sprite, "modulate", Color(1, 1, 1), 0.25)

func _shoot(base_dir: Vector2) -> void:
	animated_sprite.play("attack")
	animated_sprite.animation_finished.connect(func():
		if not is_dead and animated_sprite.animation == "attack":
			animated_sprite.play("idle" if velocity.length() < 5.0 else "walk")
	, CONNECT_ONE_SHOT)
	
	var final_dmg: float = base_damage * damage_multiplier
	var spread_angle: float = deg_to_rad(14.0)
	
	for i in range(arrow_count):
		var angle_offset: float = 0.0
		if arrow_count > 1:
			if i == 0:
				angle_offset = 0.0
			else:
				var side: float = 1.0 if (i % 2 == 1) else -1.0
				var step: float = ceil(float(i) / 2.0)
				angle_offset = side * step * spread_angle
		
		var arrow_dir: Vector2 = base_dir.rotated(angle_offset).normalized()
		
		var arrow: Node2D = PoolManager.spawn("arrow", get_parent()) as Node2D
		arrow.global_position = shoot_point.global_position
		arrow.call("setup", arrow_dir, final_dmg, pierce_count)

func _find_nearest_enemy(max_dist: float) -> Node2D:
	var enemies: Array[Node] = get_tree().get_nodes_in_group("enemy")
	var nearest: Node2D = null
	var min_dist: float = max_dist
	
	for enemy in enemies:
		if is_instance_valid(enemy):
			var enemy_node: Node2D = enemy as Node2D
			if not enemy_node.get("is_dead"):
				var d: float = global_position.distance_to(enemy_node.global_position)
				if d < min_dist:
					min_dist = d
					nearest = enemy_node
				
	return nearest

func take_damage(amount: float) -> void:
	if is_dead or is_invulnerable:
		return
		
	current_hp = max(0.0, current_hp - amount)
	emit_signal("health_changed", current_hp, max_hp)
	
	is_invulnerable = true
	invuln_timer = 0.5
	
	animated_sprite.modulate = Color(1.0, 0.3, 0.3, 0.8)
	
	if current_hp <= 0:
		die()

func _handle_invulnerability(delta: float) -> void:
	if is_invulnerable:
		invuln_timer -= delta
		animated_sprite.visible = (int(invuln_timer * 20.0) % 2 == 0)
		if invuln_timer <= 0.0:
			is_invulnerable = false
			animated_sprite.visible = true
			animated_sprite.modulate = Color(1, 1, 1, 1)

func add_exp(amount: int) -> void:
	if is_dead:
		return
	current_exp += amount
	if current_exp >= exp_to_next:
		current_exp -= exp_to_next
		level += 1
		exp_to_next = int(float(exp_to_next) * 1.5) + 3
		emit_signal("level_up_triggered", level)
		
	emit_signal("exp_changed", current_exp, exp_to_next, level)

func add_kill() -> void:
	kill_count += 1
	emit_signal("kill_count_changed", kill_count)

func apply_upgrade(upgrade_id: String) -> void:
	match upgrade_id:
		"arrow_count":
			arrow_count += 1
		"attack_speed":
			attack_cooldown = max(0.12, attack_cooldown * 0.8)
		"damage":
			damage_multiplier += 0.25
		"pierce":
			pierce_count += 1
		"speed":
			speed += 22.0
		"magnet":
			magnet_radius += 30.0
		"heal_hp":
			max_hp += 25.0
			current_hp = min(max_hp, current_hp + 40.0)
			emit_signal("health_changed", current_hp, max_hp)

func die() -> void:
	if is_dead:
		return
	is_dead = true
	set_physics_process(false)
	animated_sprite.play("death")
	emit_signal("player_died")
