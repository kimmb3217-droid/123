extends CharacterBody2D

const SpriteHelperScript = preload("res://scripts/sprite_helper.gd")
const DamageNumberScript = preload("res://scripts/damage_number.gd")

# 오크 스탯: max_hp=52.5, speed=60.0, damage=12.0
# 오크 라이더 스탯: 오크의 2배 (max_hp=105.0, damage=24.0), 이동속도는 오크의 3배 (speed=180.0)
@export var max_hp: float = 105.0
var current_hp: float = 105.0
@export var speed: float = 180.0
@export var damage: float = 24.0

var player: Node2D = null
var is_dead: bool = false
var knockback: Vector2 = Vector2.ZERO

var is_attacking: bool = false
var attack_cooldown_timer: float = 0.0
const ATTACK_RANGE: float = 46.0
const ATTACK_COOLDOWN: float = 0.85

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	add_to_group("enemy")
	add_to_group("orc_rider")
	collision_layer = 2
	collision_mask = 2
	
	animated_sprite.sprite_frames = SpriteHelperScript.get_orc_rider_frames()
	animated_sprite.play("walk")
	
	current_hp = max_hp
	
	var players: Array[Node] = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0] as Node2D

func setup_stats(hp_mult: float = 1.0, speed_mult: float = 1.0) -> void:
	max_hp = 105.0 * hp_mult
	current_hp = max_hp
	speed = 180.0 * speed_mult
	is_dead = false
	is_attacking = false
	attack_cooldown_timer = 0.0
	knockback = Vector2.ZERO
	animated_sprite.modulate = Color(1, 1, 1, 1)
	animated_sprite.play("walk")
	if player == null or not is_instance_valid(player):
		var players: Array[Node] = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			player = players[0] as Node2D

func _physics_process(delta: float) -> void:
	if is_dead:
		return
		
	if attack_cooldown_timer > 0.0:
		attack_cooldown_timer -= delta
		
	if player == null or not is_instance_valid(player):
		var players: Array[Node] = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			player = players[0] as Node2D
		return
		
	var to_player: Vector2 = (player.global_position - global_position)
	var dist_to_player: float = to_player.length()
	var move_dir: Vector2 = to_player.normalized()
	
	if abs(to_player.x) > 0.05 and not is_attacking:
		animated_sprite.flip_h = (to_player.x < 0)
		
	var separation: Vector2 = Vector2.ZERO
	var enemies: Array[Node] = get_tree().get_nodes_in_group("enemy")
	for other in enemies:
		if other != self and is_instance_valid(other) and not other.get("is_dead"):
			var other_node: Node2D = other as Node2D
			var dist: float = global_position.distance_to(other_node.global_position)
			if dist < 28.0 and dist > 0.1:
				separation += (global_position - other_node.global_position).normalized() * (28.0 - dist)
				
	var final_dir: Vector2 = (move_dir * 1.0 + separation.normalized() * 0.4).normalized()
	knockback = knockback.move_toward(Vector2.ZERO, 400.0 * delta)
	
	# 돌진 공격 판정 (기마 창/무기 리치 46px)
	if dist_to_player <= ATTACK_RANGE and attack_cooldown_timer <= 0.0 and not is_attacking:
		_perform_attack()
		
	# 플레이어를 관통하여 스쳐 지나갈 때 확정 피해
	if dist_to_player <= 24.0:
		if player.has_method("take_damage"):
			player.take_damage(damage)
			
	if is_attacking:
		# 공격 중에도 기동성 살려서 약간의 관성 이동
		velocity = move_dir * (speed * 0.35) + knockback
	else:
		velocity = final_dir * speed + knockback
		if animated_sprite.animation != "walk" and animated_sprite.animation != "hurt":
			animated_sprite.play("walk")
			
	move_and_slide()

func _perform_attack() -> void:
	is_attacking = true
	attack_cooldown_timer = ATTACK_COOLDOWN
	
	# Attack01, Attack02, Attack03 중 랜덤 선택
	var rand_val: int = randi() % 3
	var anim_name: String = "attack"
	if rand_val == 1:
		anim_name = "attack02"
	elif rand_val == 2:
		anim_name = "attack03"
		
	animated_sprite.play(anim_name)
	
	# 공격 중간 타격 타이밍(약 0.2초 뒤)에 범위 내 공격 적용
	var hit_timer := get_tree().create_timer(0.2)
	hit_timer.timeout.connect(func():
		if not is_dead and is_instance_valid(player):
			var d := global_position.distance_to(player.global_position)
			if d <= ATTACK_RANGE + 14.0:
				if player.has_method("take_damage"):
					player.take_damage(damage)
	)
	
	animated_sprite.animation_finished.connect(func():
		if not is_dead:
			is_attacking = false
			animated_sprite.play("walk")
	, CONNECT_ONE_SHOT)

func take_damage(amount: float, kb: Vector2 = Vector2.ZERO) -> void:
	if is_dead:
		return
		
	current_hp -= amount
	knockback = kb * 0.6 # 기마 유닛이라 넉백 저항
	
	DamageNumberScript.spawn(get_parent(), global_position, amount)
	
	var tween: Tween = create_tween()
	animated_sprite.modulate = Color(2.5, 2.5, 2.5)
	tween.tween_property(animated_sprite, "modulate", Color(1, 1, 1), 0.12)
	
	if current_hp <= 0:
		die()
	else:
		if not is_attacking and animated_sprite.animation != "attack" and animated_sprite.animation != "attack02" and animated_sprite.animation != "attack03":
			animated_sprite.play("hurt")
			animated_sprite.animation_finished.connect(func():
				if not is_dead and not is_attacking and animated_sprite.animation == "hurt":
					animated_sprite.play("walk")
			, CONNECT_ONE_SHOT)

func die() -> void:
	if is_dead:
		return
	is_dead = true
	is_attacking = false
	set_physics_process(false)
	collision_shape.set_deferred("disabled", true)
	
	if player != null and player.has_method("add_kill"):
		player.add_kill()
		
	call_deferred("_spawn_exp_gem", global_position)
	
	if animated_sprite.sprite_frames.has_animation("death"):
		animated_sprite.play("death")
		animated_sprite.animation_finished.connect(func():
			var fade: Tween = create_tween()
			fade.tween_property(animated_sprite, "modulate:a", 0.0, 0.2)
			fade.tween_callback(func():
				PoolManager.recycle("orc_rider_enemy", self)
			)
		, CONNECT_ONE_SHOT)
	else:
		PoolManager.recycle("orc_rider_enemy", self)

func _spawn_exp_gem(pos: Vector2) -> void:
	var gem: Node2D = PoolManager.spawn("exp_gem", get_parent()) as Node2D
	if gem != null:
		gem.global_position = pos
		gem.call("setup", 4) # 강력한 기마 몬스터이므로 경험치 4 드랍
