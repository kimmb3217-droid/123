extends Node2D

const SpriteHelperScript = preload("res://scripts/sprite_helper.gd")

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

var damage: float = 25.0
var knockback_force: float = 320.0
var stun_duration: float = 1.3
var range_distance: float = 160.0
var max_cone_angle: float = deg_to_rad(55.0) # 전방 좌우 55도 (총 110도 부채꼴)
var facing_dir: Vector2 = Vector2.RIGHT

func _ready() -> void:
	animated_sprite.sprite_frames = SpriteHelperScript.get_wind_gust_frames()
	animated_sprite.play("gust")
	animated_sprite.animation_finished.connect(func():
		queue_free()
	)

func setup(pos: Vector2, dir: Vector2, dmg: float = 25.0, kb_force: float = 320.0, stun_time: float = 1.3, r_dist: float = 160.0) -> void:
	global_position = pos
	facing_dir = dir.normalized()
	damage = dmg
	knockback_force = kb_force
	stun_duration = stun_time
	range_distance = r_dist
	
	# 이펙트 이미지가 기본적으로 왼쪽(-X)을 향하므로, +X 방향을 기준으로 회전 맞추기 위해 PI 더함
	rotation = facing_dir.angle() + PI
	
	# 스프라이트가 발사 원점에서 앞쪽으로 뻗어나가도록 배치
	animated_sprite.position = Vector2(-48.0, 0.0)
	
	# setup으로 좌표, 방향, 사거리가 모두 주입된 뒤 판정 실행!
	_apply_gust_effect()

func _apply_gust_effect() -> void:
	var enemies: Array[Node] = get_tree().get_nodes_in_group("enemy")
	var range_sq: float = range_distance * range_distance
	var min_cos: float = cos(max_cone_angle)
	
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		var enemy_node: Node2D = enemy as Node2D
		if enemy_node.get("is_dead"):
			continue
		
		var diff: Vector2 = enemy_node.global_position - global_position
		var dist_sq: float = diff.length_squared()
		
		# 사거리 내에 있는지 확인
		if dist_sq <= range_sq:
			# 초근접한 적은 각도 상관없이 무조건 밀려남 (0~45px)
			var is_close: bool = (dist_sq <= 45.0 * 45.0)
			
			var to_enemy_dir: Vector2 = diff.normalized() if dist_sq > 0.01 else facing_dir
			var dot: float = facing_dir.dot(to_enemy_dir)
			
			# 전방 부채꼴 각도 내에 있거나 초근접 상태일 때
			if is_close or dot >= min_cos:
				# 전방 조준 방향 + 적 방향을 합성하여 시원하게 밀려나도록 설정
				var push_dir: Vector2 = (facing_dir * 0.85 + to_enemy_dir * 0.15).normalized()
				var kb_vector: Vector2 = push_dir * knockback_force
				
				# 데미지 및 강화된 넉백 적용
				if enemy_node.has_method("take_damage"):
					enemy_node.take_damage(damage, kb_vector)
				
				# 기절 적용
				if enemy_node.has_method("apply_stun"):
					enemy_node.apply_stun(stun_duration)
