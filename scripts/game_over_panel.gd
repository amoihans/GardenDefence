# scripts/game_over_panel.gd
# ----------------------------------------------------------------------
# 胜利 / 失败结算面板
#   - 胜利时写入完成记录（持久化到 user://save.cfg）
#   - 胜利时显示"下一关"按钮（如果还有）
#   - 显示新纪录提示 + 用时
# ----------------------------------------------------------------------
extends CanvasLayer

@onready var title: Label = $Backdrop/Card/Title
@onready var stat_label: Label = $Backdrop/Card/StatLabel
@onready var next_btn: Button = $Backdrop/Card/VBox/NextBtn
@onready var retry_btn: Button = $Backdrop/Card/VBox/RetryBtn
@onready var menu_btn: Button = $Backdrop/Card/VBox/MenuBtn

func setup(won: bool, is_new_record: bool = false, elapsed: float = 0.0, endless_waves: int = 0) -> void:
    # 等场景就绪后再赋值，避免 onready 为 null
    await ready
    var is_endless: bool = GameState.current_level_id == "endless"
    if is_endless:
        _setup_endless(endless_waves, is_new_record)
        return
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
        # 统计 + 新纪录
        var record: Dictionary = GameState.get_level_record(GameState.current_level_id)
        var record_text: String = "⏱ 用时 %.1fs   ☀ 剩余 %d" % [elapsed, GameState.sun_amount]
        if is_new_record:
            stat_label.text = "🏆 新纪录！\n" + record_text
            stat_label.modulate = Color(1.0, 0.9, 0.4)
        else:
            stat_label.text = record_text + "   最佳 %.1fs" % record.get("best_time", 0.0)
            stat_label.modulate = Color(0.85, 0.85, 0.95)
        stat_label.visible = true
    else:
        title.text = "💀 僵尸进家了 …"
        title.modulate = Color(1.0, 0.4, 0.4)
        next_btn.visible = false
        stat_label.visible = false

# 无尽模式结算
func _setup_endless(waves: int, is_new_record: bool) -> void:
    # 写分
    var actual_new: bool = GameState.record_endless(waves)
    var record: Dictionary = GameState.get_level_record("endless")
    var best: int = int(record.get("best_waves", 0))
    # 文案
    title.text = "💀 无尽模式结束"
    title.modulate = Color(1.0, 0.5, 0.3)
    next_btn.visible = false                                  # 永远没有"下一关"
    retry_btn.text = "↻ 再来一次"
    if actual_new:
        stat_label.text = "🏆 新纪录！\n坚持了 %d 波" % waves
        stat_label.modulate = Color(1.0, 0.9, 0.4)
    else:
        stat_label.text = "坚持了 %d 波   最佳 %d 波" % [waves, best]
        stat_label.modulate = Color(0.85, 0.85, 0.95)
    stat_label.visible = true

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
