# scripts/game_over_panel.gd
# ----------------------------------------------------------------------
# 胜利 / 失败结算面板
#   - 胜利时写入完成记录（持久化到 user://save.cfg）
#   - 胜利时显示"下一关"按钮（如果还有）
# ----------------------------------------------------------------------
extends CanvasLayer

@onready var title: Label = $Backdrop/Card/Title
@onready var next_btn: Button = $Backdrop/Card/VBox/NextBtn
@onready var retry_btn: Button = $Backdrop/Card/VBox/RetryBtn
@onready var menu_btn: Button = $Backdrop/Card/VBox/MenuBtn

func setup(won: bool) -> void:
    # 等场景就绪后再赋值，避免 onready 为 null
    await ready
    if won:
        title.text = "🎉 守住了！"
        title.modulate = Color(0.4, 1.0, 0.4)
        # 写通关记录
        GameState.complete_level(GameState.current_level_id)
        # 决定"下一关"按钮的可见性
        var idx := PlantDB.find_level_index(GameState.current_level_id)
        if idx >= 0 and idx + 1 < PlantDB.LEVELS.size():
            next_btn.visible = true
            next_btn.disabled = false
        else:
            next_btn.visible = false
    else:
        title.text = "💀 僵尸进家了 …"
        title.modulate = Color(1.0, 0.4, 0.4)
        next_btn.visible = false

func _ready() -> void:
    next_btn.pressed.connect(_on_next)
    retry_btn.pressed.connect(_on_retry)
    menu_btn.pressed.connect(_on_menu)

func _on_next() -> void:
    get_tree().paused = false
    var idx := PlantDB.find_level_index(GameState.current_level_id)
    if idx >= 0 and idx + 1 < PlantDB.LEVELS.size():
        GameState.set_level(PlantDB.LEVELS[idx + 1].id)
    get_tree().change_scene_to_file("res://scenes/main/Game.tscn")

func _on_retry() -> void:
    get_tree().paused = false
    get_tree().change_scene_to_file("res://scenes/main/Game.tscn")

func _on_menu() -> void:
    get_tree().paused = false
    get_tree().change_scene_to_file("res://scenes/main/MainMenu.tscn")
