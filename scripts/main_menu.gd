# scripts/main_menu.gd
# ----------------------------------------------------------------------
# 主菜单：开始 / 选关 / 设置 / 退出
# ----------------------------------------------------------------------
extends Control

const SettingsPanelScene := preload("res://scenes/ui/SettingsPanel.tscn")

@onready var start_btn: Button = $Center/VBox/StartBtn
@onready var select_btn: Button = $Center/VBox/SelectBtn
@onready var settings_btn: Button = $Center/VBox/SettingsBtn
@onready var quit_btn: Button = $Center/VBox/QuitBtn

func _ready() -> void:
    start_btn.pressed.connect(_on_start)
    select_btn.pressed.connect(_on_select)
    settings_btn.pressed.connect(_on_settings)
    quit_btn.pressed.connect(_on_quit)

# 直接开始默认关卡
func _on_start() -> void:
    GameState.set_level(PlantDB.LEVELS[0].id)
    get_tree().change_scene_to_file("res://scenes/main/Game.tscn")

# 进入选关界面
func _on_select() -> void:
    get_tree().change_scene_to_file("res://scenes/ui/LevelSelect.tscn")

# 弹出设置面板
func _on_settings() -> void:
    var panel := SettingsPanelScene.instantiate()
    add_child(panel)

func _on_quit() -> void:
    get_tree().quit()
