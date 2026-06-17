# scripts/code_book_db.gd
# ----------------------------------------------------------------------
# 图鉴数据库（AutoLoad 单例）
#
# 记录"已发现的植物 / 僵尸"集合（跨关卡持久化）。
# 写入位置：user://code_book.cfg
#
# 通讯：游戏事件 → on_xxx() → discover_xxx()
# ----------------------------------------------------------------------
extends Node

const SAVE_PATH := "user://code_book.cfg"

var discovered_plants: Dictionary = {}      # id: true
var discovered_zombies: Dictionary = {}     # id: true

func _ready() -> void:
    _load()

# ---------- 持久化 ----------
func _load() -> void:
    var cfg := ConfigFile.new()
    if cfg.load(SAVE_PATH) != OK:
        return
    discovered_plants = cfg.get_value("plants", "data", {}).duplicate(true)
    discovered_zombies = cfg.get_value("zombies", "data", {}).duplicate(true)

func _save() -> void:
    var cfg := ConfigFile.new()
    cfg.set_value("plants", "data", discovered_plants)
    cfg.set_value("zombies", "data", discovered_zombies)
    cfg.save(SAVE_PATH)

# ---------- 事件入口 ----------
func on_plant_planted(plant_id: String) -> void:
    if not discovered_plants.get(plant_id, false):
        discovered_plants[plant_id] = true
        _save()

func on_zombie_spawned(zombie_id: String) -> void:
    if not discovered_zombies.get(zombie_id, false):
        discovered_zombies[zombie_id] = true
        _save()

# ---------- 查询 ----------
func is_plant_discovered(id: String) -> bool:
    return discovered_plants.get(id, false)

func is_zombie_discovered(id: String) -> bool:
    return discovered_zombies.get(id, false)

# ---------- 调试 ----------
func reset() -> void:
    discovered_plants = {}
    discovered_zombies = {}
    _save()
