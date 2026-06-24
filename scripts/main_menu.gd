# scripts/main_menu.gd
# ----------------------------------------------------------------------
# 主菜单：开始 / 选关 / 成就 / 图鉴 / 设置 / 退出
# ----------------------------------------------------------------------
extends Control

const SettingsPanelScene := preload("res://scenes/ui/SettingsPanel.tscn")

@onready var start_btn: Button = $Center/VBox/StartBtn
@onready var select_btn: Button = $Center/VBox/SelectBtn
@onready var achievements_btn: Button = $Center/VBox/AchievementsBtn
@onready var codebook_btn: Button = $Center/VBox/CodeBookBtn
@onready var settings_btn: Button = $Center/VBox/SettingsBtn
@onready var quit_btn: Button = $Center/VBox/QuitBtn

func _ready() -> void:
    _setup_fonts()                        # emoji 字体 fallback
    Sfx.play_bgm()                    # 进入主菜单自动播放 BGM
    start_btn.pressed.connect(_on_start)
    select_btn.pressed.connect(_on_select)
    achievements_btn.pressed.connect(_on_achievements)
    codebook_btn.pressed.connect(_on_codebook)
    settings_btn.pressed.connect(_on_settings)
    quit_btn.pressed.connect(_on_quit)

# 加载 NotoColorEmoji 作为全局 fallback —— emoji 字符（🎉🏆🌱等）会走它
# 顺序：默认 CJK 字体优先；emoji 字符集不在 CJK 范围 → fallback 到 Color Emoji
func _setup_fonts() -> void:
    var emoji_font := load("res://assets/fonts/NotoColorEmoji.ttf")
    if emoji_font == null:
        push_warning("NotoColorEmoji.ttf 未找到，emoji 可能显示失败")
        return
    ThemeDB.fallback_font = emoji_font

# 直接开始默认关卡
func _on_start() -> void:
    GameState.set_level(PlantDB.LEVELS[0].id)
    get_tree().change_scene_to_file("res://scenes/main/Game.tscn")

# 进入选关界面
func _on_select() -> void:
    get_tree().change_scene_to_file("res://scenes/ui/LevelSelect.tscn")

# 进入成就页面
func _on_achievements() -> void:
    get_tree().change_scene_to_file("res://scenes/ui/AchievementsView.tscn")

# 进入图鉴
func _on_codebook() -> void:
    get_tree().change_scene_to_file("res://scenes/ui/CodeBook.tscn")

# 弹出设置面板
func _on_settings() -> void:
    var panel := SettingsPanelScene.instantiate()
    add_child(panel)

func _on_quit() -> void:
    get_tree().quit()
