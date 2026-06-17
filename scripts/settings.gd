# scripts/settings.gd
# ----------------------------------------------------------------------
# 全局设置（AutoLoad 单例）
#
# 数据：存到 user://settings.cfg
#   [audio]
#   master_volume = 0.8
#   [video]
#   fullscreen = false
#   resolution_x = 1280
#   resolution_y = 720
#
# 用法：
#   Settings.master_volume = 0.5
#   Settings.fullscreen = true
#   Settings.resolution = Vector2i(1280, 720)
# ----------------------------------------------------------------------
extends Node

const SAVE_PATH := "user://settings.cfg"

# 支持的分辨率预设
const RESOLUTION_PRESETS: Array[Vector2i] = [
    Vector2i(1280, 720),
    Vector2i(1600, 900),
    Vector2i(1920, 1080),
]

var master_volume: float = 0.8 : set = _set_master_volume
var fullscreen: bool = false : set = _set_fullscreen
var resolution: Vector2i = Vector2i(1280, 720) : set = _set_resolution

signal changed

func _ready() -> void:
    _load()
    # 把当前值应用到引擎
    _apply_master_volume(master_volume)
    _apply_fullscreen(fullscreen)
    _apply_resolution(resolution)

func _load() -> void:
    var cfg := ConfigFile.new()
    if cfg.load(SAVE_PATH) != OK:
        return
    master_volume = cfg.get_value("audio", "master_volume", 0.8)
    fullscreen = cfg.get_value("video", "fullscreen", false)
    var rx: int = cfg.get_value("video", "resolution_x", 1280)
    var ry: int = cfg.get_value("video", "resolution_y", 720)
    resolution = Vector2i(rx, ry)

func _save() -> void:
    var cfg := ConfigFile.new()
    cfg.set_value("audio", "master_volume", master_volume)
    cfg.set_value("video", "fullscreen", fullscreen)
    cfg.set_value("video", "resolution_x", resolution.x)
    cfg.set_value("video", "resolution_y", resolution.y)
    cfg.save(SAVE_PATH)

# ---------- Setter ----------
func _set_master_volume(v: float) -> void:
    master_volume = clampf(v, 0.0, 1.0)
    _apply_master_volume(master_volume)
    _save()
    changed.emit()

func _set_fullscreen(v: bool) -> void:
    fullscreen = v
    _apply_fullscreen(fullscreen)
    _save()
    changed.emit()

func _set_resolution(v: Vector2i) -> void:
    resolution = v
    _apply_resolution(resolution)
    _save()
    changed.emit()

# ---------- 应用 ----------
func _apply_master_volume(v: float) -> void:
    if Sfx != null:
        Sfx.set_master_volume(v)
    # 同步调整 Master 总线
    var bus_idx := AudioServer.get_bus_index("Master")
    if bus_idx >= 0:
        var db: float = -40.0 + v * 40.0
        AudioServer.set_bus_volume_db(bus_idx, db)

func _apply_fullscreen(v: bool) -> void:
    if v:
        DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
    else:
        DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func _apply_resolution(v: Vector2i) -> void:
    DisplayServer.window_set_size(v)
    # 居中
    var screen := DisplayServer.screen_get_size()
    DisplayServer.window_set_position(Vector2i(
        (screen.x - v.x) / 2,
        (screen.y - v.y) / 2
    ))
