class_name PoolManager
extends RefCounted

static var pools: Dictionary = {
	"arrow": [],
	"bat_enemy": [],
	"exp_gem": []
}

static var scenes: Dictionary = {
	"arrow": preload("res://scenes/arrow.tscn"),
	"bat_enemy": preload("res://scenes/bat_enemy.tscn"),
	"exp_gem": preload("res://scenes/exp_gem.tscn")
}

static func clear_all() -> void:
	pools = {
		"arrow": [],
		"bat_enemy": [],
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
			var scene: PackedScene = scenes[pool_name]
			obj = scene.instantiate()
		else:
			push_error("Unknown pool name: " + pool_name)
			return null
			
	if obj.get_parent() != parent:
		if obj.get_parent() != null:
			obj.get_parent().remove_child(obj)
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
