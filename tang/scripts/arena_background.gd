extends Node2D

@export var grid_size: float = 64.0
@export var grid_color: Color = Color(0.18, 0.22, 0.28, 0.4)
@export var bg_color: Color = Color(0.09, 0.11, 0.14, 1.0)

var player: Node2D = null

func _ready() -> void:
	z_index = -100

func _process(_delta: float) -> void:
	if player == null:
		var players: Array[Node] = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			player = players[0] as Node2D
	queue_redraw()

func _draw() -> void:
	var center: Vector2 = Vector2.ZERO
	if player != null:
		center = player.global_position
		
	var view_size: Vector2 = Vector2(1600.0, 1000.0)
	var rect: Rect2 = Rect2(center - view_size * 0.5, view_size)
	draw_rect(rect, bg_color)
	
	var start_x: float = floor((center.x - view_size.x * 0.5) / grid_size) * grid_size
	var end_x: float = ceil((center.x + view_size.x * 0.5) / grid_size) * grid_size
	var start_y: float = floor((center.y - view_size.y * 0.5) / grid_size) * grid_size
	var end_y: float = ceil((center.y + view_size.y * 0.5) / grid_size) * grid_size
	
	var x: float = start_x
	while x <= end_x:
		draw_line(Vector2(x, start_y), Vector2(x, end_y), grid_color, 1.0)
		x += grid_size
		
	var y: float = start_y
	while y <= end_y:
		draw_line(Vector2(start_x, y), Vector2(end_x, y), grid_color, 1.0)
		y += grid_size
