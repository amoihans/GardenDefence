# scripts/pause_menu.gd
# ----------------------------------------------------------------------
# 暂停菜单（半透遮挡 + 4 个按钮）
#   - 继续：关自己 + 取消暂停
#   - 重玩：关自己 + 取消暂停 + 切到 Game（同一关）
#   - 设置：弹出 SettingsPanel
#   - 回主菜单：关自己 + 取消暂停 + 切到 MainMenu
# ----------------------------------------------------------------------
extends CanvasLayer

const SettingsPanelScene := preload("res://scenes/ui/SettingsPanel.tscn")

@onready var resume_btn: Button = $Backdrop/Card/VBox/ResumeBtn
@onready var restart_btn: Button = $Backdrop/Card/VBox/RestartBtn
@onready var settings_btn: Button = $Backdrop/Card/VBox/SettingsBtn
@onready var menu_btn: Button = $Backdrop/Card/VBox/MenuBtn

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    resume_btn.pressed.connect(_on_resume)
    restart_btn.pressed.connect(_on_restart)
    settings_btn.pressed.connect(_on_settings)
    menu_btn.pressed.connect(_on_menu)
    get_tree().paused = true

func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("pause") or event.is_action_pressed("cancel_selection"):
        _on_resume()
        get_viewport().set_input_as_handled()

func _on_resume() -> void:
    _unpause_and_free()

func _on_restart() -> void:
    get_tree().paused = false
    get_tree().change_scene_to_file("res://scenes/main/Game.tscn")
    queue_free()

func _on_settings() -> void:
    var panel := SettingsPanelScene.instantiate()
    add_child(panel)

func _on_menu() -> void:
    get_tree().paused = false
    get_tree().change_scene_to_file("res://scenes/main/MainMenu.tscn")
    queue_free()

func _unpause_and_free() -> void:
    get_tree().paused = false
    queue_free()

func _exit_tree() -> void:
    # 兜底：万一被直接清掉，确保游戏不卡死在暂停
    if get_tree().paused:
        get_tree().paused = false
