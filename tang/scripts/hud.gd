class_name HUD
extends CanvasLayer

signal upgrade_selected(upgrade_id: String)
signal restart_requested()

@onready var exp_bar: ProgressBar = $TopContainer/ExpBar
@onready var level_label: Label = $TopContainer/LevelLabel
@onready var time_label: Label = $TopContainer/TimeLabel
@onready var kill_label: Label = $TopContainer/KillLabel
@onready var hp_bar: ProgressBar = $TopContainer/HpBar
@onready var hp_label: Label = $TopContainer/HpBar/HpLabel
@onready var auto_attack_btn: Button = $AutoAttackBadge

@onready var level_up_modal: Control = $LevelUpModal
@onready var cards_container: HBoxContainer = $LevelUpModal/CardsContainer
@onready var game_over_modal: Control = $GameOverModal
@onready var game_over_info: Label = $GameOverModal/InfoLabel

var all_upgrades: Array = [
	{
		"id": "arrow_count",
		"title": "멀티샷 (Multishot)",
		"desc": "화살 발사 개수 +1\n(부채꼴 다중 발사)",
		"icon": "🏹"
	},
	{
		"id": "attack_speed",
		"title": "신속 사격 (Rapid Fire)",
		"desc": "공격 속도 +20%\n(더 빠른 연사)",
		"icon": "⚡"
	},
	{
		"id": "damage",
		"title": "강궁의 일격 (Heavy Draw)",
		"desc": "화살 공격력 +25%\n(위력 증가)",
		"icon": "💥"
	},
	{
		"id": "pierce",
		"title": "관통 화살 (Piercing)",
		"desc": "적 관통 횟수 +1\n(다수의 적 관통)",
		"icon": "🗡️"
	},
	{
		"id": "speed",
		"title": "깃털 발걸음 (Swift)",
		"desc": "이동 속도 +15%\n(카이팅 기동력 강화)",
		"icon": "👟"
	},
	{
		"id": "magnet",
		"title": "자력 부적 (Magnet)",
		"desc": "보석 획득 반경 +50%\n(원거리 흡수)",
		"icon": "🧲"
	},
	{
		"id": "heal_hp",
		"title": "활력 비약 (Vitality)",
		"desc": "최대 HP +25 증가 &\nHP 40 즉시 회복",
		"icon": "🧪"
	}
]

func _ready() -> void:
	level_up_modal.visible = false
	game_over_modal.visible = false
	auto_attack_btn.pressed.connect(_on_auto_attack_pressed)
	$GameOverModal/RestartBtn.pressed.connect(func(): emit_signal("restart_requested"))

func _on_auto_attack_pressed() -> void:
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		players[0].toggle_auto_attack()

func update_health(curr: float, max_val: float) -> void:
	hp_bar.max_value = max_val
	hp_bar.value = curr
	hp_label.text = "%d / %d" % [int(curr), int(max_val)]

func update_exp(curr: int, max_val: int, lvl: int) -> void:
	exp_bar.max_value = max_val
	exp_bar.value = curr
	level_label.text = "Lv. %d" % lvl

func update_timer(seconds: float) -> void:
	var m := int(seconds) / 60
	var s := int(seconds) % 60
	time_label.text = "%02d:%02d" % [m, s]

func update_kills(count: int) -> void:
	kill_label.text = "💀 %d" % count

func update_auto_attack(is_enabled: bool) -> void:
	if is_enabled:
		auto_attack_btn.text = "⚡ AUTO-ATTACK: ON [Caps Lock]"
		auto_attack_btn.modulate = Color(0.3, 1.0, 0.4)
	else:
		auto_attack_btn.text = "🎯 AUTO-ATTACK: OFF [Caps Lock]"
		auto_attack_btn.modulate = Color(1.0, 0.6, 0.2)

func show_level_up() -> void:
	get_tree().paused = true
	level_up_modal.visible = true
	
	# Clear old card buttons
	for child in cards_container.get_children():
		child.queue_free()
		
	# Pick 3 random upgrades
	var shuffled := all_upgrades.duplicate()
	shuffled.shuffle()
	var selected := shuffled.slice(0, 3)
	
	for upg in selected:
		var card := _create_upgrade_card(upg)
		cards_container.add_child(card)

func _create_upgrade_card(upg: Dictionary) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(240, 320)
	btn.text = "\n\n%s\n\n%s\n\n%s\n\n[선택]" % [upg["icon"], upg["title"], upg["desc"]]
	btn.add_theme_font_size_override("font_size", 16)
	
	btn.pressed.connect(func():
		emit_signal("upgrade_selected", upg["id"])
		level_up_modal.visible = false
		get_tree().paused = false
	)
	return btn

func show_game_over(time_sec: float, kills: int) -> void:
	get_tree().paused = true
	game_over_modal.visible = true
	var m := int(time_sec) / 60
	var s := int(time_sec) % 60
	game_over_info.text = "생존 시간: %02d:%02d\n처치한 적: %d마리" % [m, s, kills]
