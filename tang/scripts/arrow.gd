extends Area2D

@export var speed: float = 520.0
@export var damage: float = 30.0
@export var pierce_count: int = 1
@export var lifetime: float = 1.6

var direction: Vector2 = Vector2.RIGHT
var traveled_time: float = 0.0
var hit_enemies: Array = []

func _ready() -> void:
	collision_layer = 4
	collision_mask = 2
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	rotation = direction.angle()

func setup(dir: Vector2, dmg: float, pierce: int = 1) -> void:
	direction = dir.normalized()
	damage = dmg
	pierce_count = pierce
	rotation = direction.angle()

func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
	traveled_time += delta
	if traveled_time >= lifetime:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	_handle_hit(body)

func _on_area_entered(area: Area2D) -> void:
	_handle_hit(area.get_parent())

func _handle_hit(target: Node) -> void:
	if target == null or target in hit_enemies:
		return
	if target.is_in_group("enemy") and target.has_method("take_damage"):
		hit_enemies.append(target)
		target.take_damage(damage, direction * 120.0)
		pierce_count -= 1
		if pierce_count <= 0:
			queue_free()
