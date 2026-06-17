# scripts/settings_panel.gd
# ----------------------------------------------------------------------
# 设置面板
#   - 音量滑条（0~1）
#   - 全屏切换
#   - 分辨率下拉（来自 Settings.RESOLUTION_PRESETS）
#   - 关闭按钮
# ----------------------------------------------------------------------
extends Panel

@onready var volume_slider: HSlider = $Margin/VBox/VolumeRow/VolumeSlider
@onready var volume_value: Label = $Margin/VBox/VolumeRow/VolumeValue
@onready var fullscreen_check: CheckBox = $Margin/VBox/FullscreenCheck
@onready var resolution_option: OptionButton = $Margin/VBox/ResolutionRow/ResolutionOption
@onready var close_btn: Button = $Margin/VBox/CloseBtn

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    # 用现有值初始化
    volume_slider.value = Settings.master_volume
    _update_volume_label(Settings.master_volume)
    fullscreen_check.button_pressed = Settings.fullscreen
    _fill_resolutions()
    resolution_option.select(_find_res_index(Settings.resolution))

    volume_slider.value_changed.connect(_on_volume_changed)
    fullscreen_check.toggled.connect(_on_fullscreen_toggled)
    resolution_option.item_selected.connect(_on_resolution_changed)
    close_btn.pressed.connect(_on_close)

func _fill_resolutions() -> void:
    resolution_option.clear()
    for i in Settings.RESOLUTION_PRESETS.size():
        var v: Vector2i = Settings.RESOLUTION_PRESETS[i]
        resolution_option.add_item("%d × %d" % [v.x, v.y], i)

func _find_res_index(v: Vector2i) -> int:
    for i in Settings.RESOLUTION_PRESETS.size():
        if Settings.RESOLUTION_PRESETS[i] == v:
            return i
    return 0

func _update_volume_label(v: float) -> void:
    volume_value.text = "%d%%" % int(v * 100)

func _on_volume_changed(v: float) -> void:
    Settings.master_volume = v
    _update_volume_label(v)

func _on_fullscreen_toggled(pressed: bool) -> void:
    Settings.fullscreen = pressed

func _on_resolution_changed(idx: int) -> void:
    Settings.resolution = Settings.RESOLUTION_PRESETS[idx]

func _on_close() -> void:
    queue_free()
