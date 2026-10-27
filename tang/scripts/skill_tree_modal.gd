class_name SkillTreeModal
extends Control

signal skill_unlocked(skill_id: String)
signal closed()

@onready var points_label: Label = $Header/PointsLabel
@onready var close_btn: Button = $Header/CloseBtn
@onready var tree_canvas: Control = $TreeCanvas
@onready var desc_panel: Panel = $DescPanel
@onready var desc_title: Label = $DescPanel/Title
@onready var desc_body: Label = $DescPanel/Body
@onready var desc_level: Label = $DescPanel/Level
@onready var upgrade_btn: Button = $DescPanel/UpgradeBtn

var player: Node2D = null
var current_selected_node_id: String = ""

# 스킬 노드 정의:
# branch: "mobility" (중앙 노랑), "attack" (좌측 초록/민트), "survival" (우측 빨강)
var skill_data: Dictionary = {
	# [이동성 (Mobility) - 중앙 Yellow]
	"m_root": {
		"id": "move_speed",
		"branch": "mobility",
		"title": "날렵한 발걸음",
		"desc": "이동 속도가 18 증가합니다.",
		"max_level": 5,
		"pos": Vector2(576, 520),
		"prereq": []
	},
	"m_dash": {
		"id": "dash_cooldown",
		"branch": "mobility",
		"title": "돌풍의 기동",
		"desc": "돌풍(우클릭 특수기) 쿨다운이 15% 단축됩니다.",
		"max_level": 3,
		"pos": Vector2(576, 400),
		"prereq": ["m_root"]
	},
	"m_wind_step": {
		"id": "move_speed",
		"branch": "mobility",
		"title": "순풍 질주",
		"desc": "이동 속도가 18 추가로 증가합니다.",
		"max_level": 5,
		"pos": Vector2(510, 290),
		"prereq": ["m_dash"]
	},
	"m_mastery": {
		"id": "dash_mastery",
		"branch": "mobility",
		"title": "질풍의 지배자",
		"desc": "이동 속도 +25 및 돌풍 쿨다운이 20% 대폭 감소합니다.",
		"max_level": 1,
		"pos": Vector2(576, 170),
		"prereq": ["m_wind_step"]
	},

	# [탄환/공격 (Attack) - 좌측 Green]
	"a_root": {
		"id": "damage",
		"branch": "attack",
		"title": "강궁 사격",
		"desc": "화살 공격력이 20% 증가합니다.",
		"max_level": 5,
		"pos": Vector2(380, 520),
		"prereq": []
	},
	"a_speed": {
		"id": "attack_speed",
		"branch": "attack",
		"title": "연속 사격",
		"desc": "공격 속도가 18% 빨라집니다.",
		"max_level": 4,
		"pos": Vector2(300, 420),
		"prereq": ["a_root"]
	},
	"a_multishot": {
		"id": "arrow_count",
		"branch": "attack",
		"title": "멀티샷 (화살 +1)",
		"desc": "한 번에 발사하는 화살 수가 1발 증가합니다.",
		"max_level": 3,
		"pos": Vector2(230, 310),
		"prereq": ["a_speed"]
	},
	"a_pierce": {
		"id": "pierce",
		"branch": "attack",
		"title": "철갑 관통",
		"desc": "화살이 적을 1회 추가로 관통합니다.",
		"max_level": 3,
		"pos": Vector2(160, 200),
		"prereq": ["a_multishot"]
	},
	"a_storm": {
		"id": "storm_mastery",
		"branch": "attack",
		"title": "폭풍우 궁술",
		"desc": "공격력 +35% 및 대폭풍(타이푼) 쿨다운 25% 감소.",
		"max_level": 1,
		"pos": Vector2(190, 110),
		"prereq": ["a_pierce"]
	},

	# [생존 (Survival) - 우측 Red]
	"s_root": {
		"id": "max_hp",
		"branch": "survival",
		"title": "강인한 생명력",
		"desc": "최대 HP가 30 증가하고 30 즉시 치유됩니다.",
		"max_level": 5,
		"pos": Vector2(772, 520),
		"prereq": []
	},
	"s_magnet": {
		"id": "magnet",
		"branch": "survival",
		"title": "영혼의 자력",
		"desc": "보석과 회복 아이템을 끌어당기는 자력 범위가 35 증가합니다.",
		"max_level": 4,
		"pos": Vector2(852, 420),
		"prereq": ["s_root"]
	},
	"s_heal": {
		"id": "heal_potency",
		"branch": "survival",
		"title": "활력 정제",
		"desc": "즉시 50 HP를 회복하고 자력 범위를 20 추가 흡수합니다.",
		"max_level": 3,
		"pos": Vector2(922, 310),
		"prereq": ["s_magnet"]
	},
	"s_immortal": {
		"id": "immortal_vitality",
		"branch": "survival",
		"title": "불사의 의지",
		"desc": "최대 체력 +60 및 체력을 전체 회복합니다.",
		"max_level": 1,
		"pos": Vector2(960, 150),
		"prereq": ["s_heal"]
	}
}

var unlocked_levels: Dictionary = {}

func _ready() -> void:
	visible = false
	close_btn.pressed.connect(func(): close_tree())
	upgrade_btn.pressed.connect(_on_upgrade_clicked)
	desc_panel.visible = false
	
	for key in skill_data.keys():
		unlocked_levels[key] = 0
		
	_create_tree_ui()

func set_player_ref(p: Node2D) -> void:
	player = p

func open_tree() -> void:
	visible = true
	get_tree().paused = true
	_refresh_all()

func close_tree() -> void:
	visible = false
	get_tree().paused = false
	emit_signal("closed")

func _create_tree_ui() -> void:
	# 배경 선(Line) 및 버튼 생성
	for child in tree_canvas.get_children():
		child.queue_free()
		
	# 1. 트리 선 그리기 (LineRenderer 대용 커스텀 드로우 컨트롤)
	var line_drawer := Control.new()
	line_drawer.name = "Lines"
	line_drawer.set_anchors_preset(Control.PRESET_FULL_RECT)
	line_drawer.draw.connect(_on_draw_lines.bind(line_drawer))
	tree_canvas.add_child(line_drawer)
	
	# 2. 노드 버튼들 배치
	for key in skill_data.keys():
		var data = skill_data[key]
		var btn := Button.new()
		btn.name = "Node_" + key
		btn.custom_minimum_size = Vector2(48, 48)
		btn.position = data["pos"] - Vector2(24, 24)
		
		# 아이콘/텍스트 표기
		btn.text = _get_node_short_text(data)
		btn.pressed.connect(_on_node_pressed.bind(key))
		tree_canvas.add_child(btn)

func _get_node_short_text(data: Dictionary) -> String:
	match data["branch"]:
		"mobility": return "⚡"
		"attack": return "🏹"
		"survival": return "❤️"
	return "●"

func _on_draw_lines(canvas: Control) -> void:
	for key in skill_data.keys():
		var data = skill_data[key]
		var from_pos: Vector2 = data["pos"]
		for prereq_key in data["prereq"]:
			if skill_data.has(prereq_key):
				var to_pos: Vector2 = skill_data[prereq_key]["pos"]
				var is_active: bool = (unlocked_levels[prereq_key] > 0)
				var line_color := Color(0.3, 0.3, 0.35, 0.7)
				var width := 3.0
				if is_active:
					match data["branch"]:
						"mobility": line_color = Color(1.0, 0.85, 0.2, 1.0)
						"attack": line_color = Color(0.2, 0.9, 0.4, 1.0)
						"survival": line_color = Color(1.0, 0.25, 0.25, 1.0)
					width = 5.0
				canvas.draw_line(from_pos, to_pos, line_color, width)

func _on_node_pressed(node_key: String) -> void:
	current_selected_node_id = node_key
	_refresh_desc_panel()

func _refresh_desc_panel() -> void:
	if current_selected_node_id == "" or not skill_data.has(current_selected_node_id):
		desc_panel.visible = false
		return
		
	desc_panel.visible = true
	var data = skill_data[current_selected_node_id]
	var cur_lvl: int = unlocked_levels[current_selected_node_id]
	var max_lvl: int = data["max_level"]
	
	desc_title.text = data["title"]
	desc_body.text = data["desc"]
	desc_level.text = "현재 레벨: %d / %d" % [cur_lvl, max_lvl]
	
	var can_upgrade: bool = _can_unlock(current_selected_node_id)
	var pts: int = int(player.get("skill_points")) if is_instance_valid(player) else 0
	
	if cur_lvl >= max_lvl:
		upgrade_btn.disabled = true
		upgrade_btn.text = "마스터 완료"
	elif pts <= 0:
		upgrade_btn.disabled = true
		upgrade_btn.text = "스킬 포인트 부족"
	elif not can_upgrade:
		upgrade_btn.disabled = true
		upgrade_btn.text = "선행 스킬 필요"
	else:
		upgrade_btn.disabled = false
		upgrade_btn.text = "강화하기 (1pt)"

func _can_unlock(node_key: String) -> bool:
	var data = skill_data[node_key]
	var cur_lvl: int = unlocked_levels[node_key]
	if cur_lvl >= data["max_level"]:
		return false
		
	# 선행 노드가 모두 최소 1 이상 해금되었는지 체크
	for prereq_key in data["prereq"]:
		if unlocked_levels.get(prereq_key, 0) <= 0:
			return false
	return true

func _on_upgrade_clicked() -> void:
	if current_selected_node_id == "":
		return
	if not _can_unlock(current_selected_node_id):
		return
	if not is_instance_valid(player):
		return
		
	var pts: int = int(player.get("skill_points"))
	if pts <= 0:
		return
		
	# 스킬 포인트 차감 및 레벨 증가
	player.set("skill_points", pts - 1)
	unlocked_levels[current_selected_node_id] += 1
	
	# 플레이어에게 실제 스탯 버프 적용
	var data = skill_data[current_selected_node_id]
	if player.has_method("apply_upgrade"):
		player.apply_upgrade(data["id"])
		
	_refresh_all()

func _refresh_all() -> void:
	if is_instance_valid(player):
		var pts: int = int(player.get("skill_points"))
		points_label.text = "보유 스킬 포인트: %d" % pts
		
	# 노드 버튼 색상 업데이트
	for key in skill_data.keys():
		var btn: Button = tree_canvas.get_node_or_null("Node_" + key) as Button
		if btn != null:
			var lvl: int = unlocked_levels[key]
			var max_l: int = skill_data[key]["max_level"]
			var branch: String = skill_data[key]["branch"]
			btn.text = "%s\n%d/%d" % [_get_node_short_text(skill_data[key]), lvl, max_l]
			
			if lvl > 0:
				match branch:
					"mobility": btn.modulate = Color(1.2, 1.0, 0.3)
					"attack": btn.modulate = Color(0.4, 1.2, 0.5)
					"survival": btn.modulate = Color(1.2, 0.4, 0.4)
			elif _can_unlock(key):
				btn.modulate = Color(1.0, 1.0, 1.0) # 해금 가능
			else:
				btn.modulate = Color(0.35, 0.35, 0.4) # 잠김
				
	# 선 다시 그리기
	var line_drawer := tree_canvas.get_node_or_null("Lines") as Control
	if line_drawer != null:
		line_drawer.queue_redraw()
		
	_refresh_desc_panel()
