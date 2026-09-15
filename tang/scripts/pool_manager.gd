class_name PoolManager
extends RefCounted

static var pools: Dictionary = {
	"arrow": [],
	"bat_enemy": [],
	"orc_enemy": [],
	"orc_rider_enemy": [],
	"exp_gem": [],
	"damage_number": []
}

static var scenes: Dictionary = {
	"arrow": "res://scenes/arrow.tscn",
	"bat_enemy": "res://scenes/bat_enemy.tscn",
	"orc_enemy": "res://scenes/orc_enemy.tscn",
	"orc_rider_enemy": "res://scenes/orc_rider_enemy.tscn",
	"exp_gem": "res://scenes/exp_gem.tscn"
}
static var loaded_scenes: Dictionary = {}

# 빠른 탐색을 위해 살아있는 적 노드 캐시
static var active_enemies: Array[Node2D] = []

static func clear_all() -> void:
	pools = {
		"arrow": [],
		"bat_enemy": [],
		"orc_enemy": [],
		"orc_rider_enemy": [],
		"exp_gem": [],
		"damage_number": []
	}
	active_enemies.clear()

static func register_enemy(enemy: Node2D) -> void:
	if not active_enemies.has(enemy):
		active_enemies.append(enemy)

static func unregister_enemy(enemy: Node2D) -> void:
	active_enemies.erase(enemy)

static func get_nearest_enemy(from_pos: Vector2, max_dist: float) -> Node2D:
	var nearest: Node2D = null
	var min_dist_sq: float = max_dist * max_dist
	
	for enemy in active_enemies:
		if is_instance_valid(enemy) and not enemy.get("is_dead"):
			var d_sq: float = from_pos.distance_squared_to(enemy.global_position)
			if d_sq < min_dist_sq:
				min_dist_sq = d_sq
				nearest = enemy
	return nearest

static func spawn(pool_name: String, parent: Node) -> Node:
	if not pools.has(pool_name):
		pools[pool_name] = []
		
	var pool_list: Array = pools[pool_name]
	var obj: Node = null
	
	while pool_list.size() > 0:
		var candidate = pool_list.pop_back()
		if is_instance_valid(candidate):
			obj = candidate
			break
			
	if obj == null:
		if scenes.has(pool_name):
			if not loaded_scenes.has(pool_name):
				loaded_scenes[pool_name] = load(scenes[pool_name])
			var scene: PackedScene = loaded_scenes[pool_name]
			if scene != null:
				obj = scene.instantiate()
			else:
				push_error("Failed to load scene for pool: " + pool_name)
				return null
		else:
			push_error("Unknown pool name: " + pool_name)
			return null
			
	if obj.get_parent() != parent:
		parent.add_child(obj)
	
	obj.show()
	obj.set_process(true)
	obj.set_physics_process(true)
	
	if obj is CollisionObject2D:
		for child in obj.get_children():
			if child is CollisionShape2D:
				child.set_deferred("disabled", false)
				
	return obj

static func recycle(pool_name: String, obj: Node) -> void:
	if not is_instance_valid(obj):
		return
		
	obj.hide()
	obj.set_process(false)
	obj.set_physics_process(false)
	
	if obj is CollisionObject2D:
		for child in obj.get_children():
			if child is CollisionShape2D:
				child.set_deferred("disabled", true)
				
	if not pools.has(pool_name):
		pools[pool_name] = []
		
	pools[pool_name].append(obj)

