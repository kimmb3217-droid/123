extends CharacterBody2D

const SpriteHelperScript = preload("res://scripts/sprite_helper.gd")
const arrow_scene = preload("res://scenes/arrow.tscn")

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
var magnet_radius: float = 85.0

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
	collision_mask = 2
	
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

func _shoot(base_dir: Vector2) -> void:
	animated_sprite.play("attack")
	animated_sprite.animation_finished.connect(func():
		if not is_dead and animated_sprite.animation == "attack":
			animated_sprite.play("idle" if velocity.length() < 5.0 else "walk")
	, CONNECT_ONE_SHOT)
	
	var final_dmg: float = base_damage * damage_multiplier
	var spread_angle: float = deg_to_rad(14.0)
	var start_angle: float = -(float(arrow_count) - 1.0) * 0.5 * spread_angle
	
	for i in range(arrow_count):
		var angle_offset: float = start_angle + float(i) * spread_angle
		var arrow_dir: Vector2 = base_dir.rotated(angle_offset).normalized()
		
		var arrow: Node2D = arrow_scene.instantiate() as Node2D
		arrow.global_position = shoot_point.global_position
		arrow.call("setup", arrow_dir, final_dmg, pierce_count)
		get_parent().add_child(arrow)

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
			magnet_radius += 45.0
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
