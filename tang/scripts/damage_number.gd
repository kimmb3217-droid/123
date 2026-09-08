extends Node2D

static func spawn(parent: Node, pos: Vector2, amount: float, is_crit: bool = false) -> void:
	var dmg_node: Node2D = Node2D.new()
	dmg_node.global_position = pos + Vector2(randf_range(-8.0, 8.0), randf_range(-12.0, -4.0))
	parent.add_child(dmg_node)
	
	var label: Label = Label.new()
	label.text = str(int(amount))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	if is_crit:
		label.modulate = Color(1.0, 0.4, 0.1)
		label.scale = Vector2(1.2, 1.2)
	else:
		label.modulate = Color(1.0, 1.0, 1.0)
		
	dmg_node.add_child(label)
	label.position = Vector2(-20.0, -10.0)
	
	var tween: Tween = dmg_node.create_tween()
	tween.set_parallel(true)
	tween.tween_property(dmg_node, "position:y", dmg_node.position.y - 25.0, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, 0.45).set_delay(0.15)
	tween.chain().tween_callback(dmg_node.queue_free)
