# scripts/level_select.gd
# ----------------------------------------------------------------------
# 选关界面
#   列出 PlantDB.LEVELS 里的全部关卡
#   点击某关 → 写 GameState.current_level_id → 切到 Game
#   顶部返回主菜单按钮
# ----------------------------------------------------------------------
extends Control

const LEVEL_CARD_SCENE := preload("res://scenes/ui/LevelCard.tscn")

@onready var level_list: VBoxContainer = $Center/List
@onready var back_btn: Button = $TopBar/BackBtn
@onready var title: Label = $TopBar/Title

func _ready() -> void:
    back_btn.pressed.connect(_on_back)
    title.text = "选关"
    _build_level_cards()

func _build_level_cards() -> void:
    # 清空已有
    for child in level_list.get_children():
        child.queue_free()
    # 按 PlantDB.LEVELS 顺序添加
    for i in PlantDB.LEVELS.size():
        var level: Dictionary = PlantDB.LEVELS[i]
        var card: Control = LEVEL_CARD_SCENE.instantiate()
        level_list.add_child(card)
        card.setup(i, level)
        card.start_requested.connect(_on_start_level)

func _on_start_level(level_id: String) -> void:
    GameState.set_level(level_id)
    get_tree().change_scene_to_file("res://scenes/main/Game.tscn")

func _on_back() -> void:
    get_tree().change_scene_to_file("res://scenes/main/MainMenu.tscn")
