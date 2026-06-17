# scripts/achievements_view.gd
# ----------------------------------------------------------------------
# 成就查看页：列出全部成就 + 解锁状态
# ----------------------------------------------------------------------
extends Control

const AchievementItemScene := preload("res://scenes/ui/AchievementItem.tscn")

@onready var list: VBoxContainer = $Center/List
@onready var back_btn: Button = $TopBar/BackBtn
@onready var title: Label = $TopBar/Title

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	title.text = "成就"
	back_btn.pressed.connect(_on_back)
	_build_list()

func _build_list() -> void:
	for child in list.get_children():
		child.queue_free()
	for id in AchievementDB.ACHIEVEMENTS:
		var data: Dictionary = AchievementDB.ACHIEVEMENTS[id]
		var item: Control = AchievementItemScene.instantiate()
		list.add_child(item)
		item.setup(id, data, AchievementDB.is_unlocked(id))

func _on_back() -> void:
	get_tree().change_scene_to_file("res://scenes/main/MainMenu.tscn")
