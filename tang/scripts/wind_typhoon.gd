extends Node2D

const SpriteHelperScript = preload("res://scripts/sprite_helper.gd")

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

var damage: float = 65.0
var knockback_force: float = 600.0
var stun_duration: float = 2.6
var radius: float = 210.0

func _ready() -> void:
	animated_sprite.sprite_frames = SpriteHelperScript.get_typhoon_frames()
	animated_sprite.play("typhoon")
	animated_sprite.scale = Vector2(1.8, 1.8) # 360도 거대 회오리 연출
	animated_sprite.animation_finished.connect(func():
		queue_free()
	)

func setup(pos: Vector2, dmg: float = 65.0, kb_force: float = 600.0, stun_time: float = 2.6, rad: float = 210.0) -> void:
	global_position = pos
	damage = dmg
	knockback_force = kb_force
	stun_duration = stun_time
	radius = rad
	
	_apply_typhoon_effect()

func _apply_typhoon_effect() -> void:
	var enemies: Array[Node] = get_tree().get_nodes_in_group("enemy")
	var rad_sq: float = radius * radius
	
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		var enemy_node: Node2D = enemy as Node2D
		if enemy_node.get("is_dead"):
			continue
			
		var diff: Vector2 = enemy_node.global_position - global_position
		var dist_sq: float = diff.length_squared()
		
		# 360도 전방위 반경 내의 모든 적
		if dist_sq <= rad_sq:
			var push_dir: Vector2 = diff.normalized() if dist_sq > 0.01 else Vector2.RIGHT.rotated(randf() * TAU)
			var kb_vector: Vector2 = push_dir * knockback_force
			
			# 고위력 피해 및 넉백
			if enemy_node.has_method("take_damage"):
				enemy_node.take_damage(damage, kb_vector)
				
			# 장시간(2.6초) 강력 기절 부여
			if enemy_node.has_method("apply_stun"):
				enemy_node.apply_stun(stun_duration)
