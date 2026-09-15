class_name PoolManager
extends RefCounted

static var pools: Dictionary = {
	"arrow": [],
	"bat_enemy": [],
	"orc_enemy": [],
	"exp_gem": []
}

static var scenes: Dictionary = {
	"arrow": "res://scenes/arrow.tscn",
	"bat_enemy": "res://scenes/bat_enemy.tscn",
	"orc_enemy": "res://scenes/orc_enemy.tscn",
	"exp_gem": "res://scenes/exp_gem.tscn"
}
static var loaded_scenes: Dictionary = {}

static func clear_all() -> void:
	pools = {
		"arrow": [],
		"bat_enemy": [],
		"orc_enemy": [],
		"exp_gem": []
	}

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
