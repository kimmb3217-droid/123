extends CharacterBody2D

const SpriteHelperScript = preload("res://scripts/sprite_helper.gd")
const DamageNumberScript = preload("res://scripts/damage_number.gd")
const exp_gem_scene = preload("res://scenes/exp_gem.tscn")

@export var max_hp: float = 35.0
var current_hp: float = 35.0
@export var speed: float = 90.0
@export var damage: float = 8.0

var player: Node2D = null
var is_dead: bool = false
var knockback: Vector2 = Vector2.ZERO

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	add_to_group("enemy")
	collision_layer = 2
	collision_mask = 1 | 2
	
	animated_sprite.sprite_frames = SpriteHelperScript.get_bat_frames()
	animated_sprite.play("fly")
	
	current_hp = max_hp
	
	var players: Array[Node] = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0] as Node2D

func setup_stats(hp_mult: float, speed_mult: float) -> void:
	max_hp = 35.0 * hp_mult
	current_hp = max_hp
	speed = 90.0 * speed_mult

func _physics_process(delta: float) -> void:
	if is_dead:
		return
		
	if player == null:
		var players: Array[Node] = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			player = players[0] as Node2D
		return
		
	var to_player: Vector2 = (player.global_position - global_position)
	var move_dir: Vector2 = to_player.normalized()
	
	var separation: Vector2 = Vector2.ZERO
	var enemies: Array[Node] = get_tree().get_nodes_in_group("enemy")
	for other in enemies:
		if other != self and is_instance_valid(other):
			var other_node: Node2D = other as Node2D
			var dist: float = global_position.distance_to(other_node.global_position)
			if dist < 22.0 and dist > 0.1:
				separation += (global_position - other_node.global_position).normalized() * (22.0 - dist)
				
	var final_dir: Vector2 = (move_dir * 1.0 + separation.normalized() * 0.5).normalized()
	
	knockback = knockback.move_toward(Vector2.ZERO, 350.0 * delta)
	
	velocity = final_dir * speed + knockback
	move_and_slide()
	
	if abs(final_dir.x) > 0.05:
		animated_sprite.flip_h = (final_dir.x < 0)
		
	for i in range(get_slide_collision_count()):
		var col: KinematicCollision2D = get_slide_collision(i)
		var collider: Object = col.get_collider()
		if collider != null and collider.is_in_group("player") and collider.has_method("take_damage"):
			collider.take_damage(damage)

func take_damage(amount: float, kb: Vector2 = Vector2.ZERO) -> void:
	if is_dead:
		return
		
	current_hp -= amount
	knockback = kb
	
	DamageNumberScript.spawn(get_parent(), global_position, amount)
	
	var tween: Tween = create_tween()
	animated_sprite.modulate = Color(2.5, 2.5, 2.5)
	tween.tween_property(animated_sprite, "modulate", Color(1, 1, 1), 0.12)
	
	if current_hp <= 0:
		die()
	else:
		if animated_sprite.animation != "attack":
			animated_sprite.play("hurt")
			animated_sprite.animation_finished.connect(func():
				if not is_dead and animated_sprite.animation == "hurt":
					animated_sprite.play("fly")
			, CONNECT_ONE_SHOT)

func die() -> void:
	if is_dead:
		return
	is_dead = true
	set_physics_process(false)
	collision_shape.set_deferred("disabled", true)
	
	if player != null and player.has_method("add_kill"):
		player.add_kill()
		
	var gem: Node2D = exp_gem_scene.instantiate() as Node2D
	gem.global_position = global_position
	get_parent().call_deferred("add_child", gem)
	
	if animated_sprite.sprite_frames.has_animation("death"):
		animated_sprite.play("death")
		animated_sprite.animation_finished.connect(func():
			var fade: Tween = create_tween()
			fade.tween_property(animated_sprite, "modulate:a", 0.0, 0.2)
			fade.tween_callback(queue_free)
		)
	else:
		queue_free()
