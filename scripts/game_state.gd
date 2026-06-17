# scripts/game_state.gd
# ----------------------------------------------------------------------
# 全局游戏状态（AutoLoad 单例）
#
# 为什么用单例？
#   - 阳光数、当前波次、游戏胜负这些数据需要被 HUD / 植物 / 僵尸 / 主菜单
#     等多个互不相关的节点访问。
#   - 单例可以避免到处 get_parent().get_parent()... 取节点。
#   - 配合信号，谁关心数据变化谁就连接对应信号。
#
# 用法：
#   GameState.sun_amount += 25
#   GameState.sun_changed.connect(_on_sun_changed)
# ----------------------------------------------------------------------
extends Node

# 信号 ----------------------------------------------------------------
signal sun_changed(new_amount: int)             # 阳光数发生变化
signal wave_changed(new_wave: int, total: int)  # 波次切换
signal game_won                                  # 通关
signal game_lost                                  # 失败（僵尸进家）

# 全局状态 ------------------------------------------------------------
var sun_amount: int = 50 : set = _set_sun
var current_wave: int = 0
var total_waves: int = 0
var is_game_over: bool = false

# 肥料：每关开局送 3 罐
var fertilizer: int = 3 : set = _set_fertilizer
signal fertilizer_changed(new_amount: int)

# 当前关卡 id（选关界面写入；Game 启动时读取）
var current_level_id: String = "day1"

# 当前玩家选中的植物 id（""=未选；"shovel"=铲子）
# Lawn 监听这个值来决定鼠标悬停时的格子高亮颜色
var selected_plant_id: String = "" : set = _set_selected

signal selected_plant_changed(new_id: String)

# 关卡完成记录 { level_id: true, ... } —— 写入 user://save.cfg 持久化
var completed_levels: Dictionary = {}
const SAVE_PATH := "user://save.cfg"

# 关卡最佳记录 { level_id: { best_time: float, no_wallnut: bool, max_sun: int } }
var level_records: Dictionary = {}

# 重置接口 ------------------------------------------------------------
func reset() -> void:
    sun_amount = 50
    current_wave = 0
    is_game_over = false
    selected_plant_id = ""
    fertilizer = 3

func _ready() -> void:
    _load_save()

# ---------- 存档 ----------
func _load_save() -> void:
    var cfg := ConfigFile.new()
    if cfg.load(SAVE_PATH) == OK:
        completed_levels = cfg.get_value("progress", "completed", {}).duplicate(true)
        level_records = cfg.get_value("progress", "records", {}).duplicate(true)

func _save_to_disk() -> void:
    var cfg := ConfigFile.new()
    cfg.set_value("progress", "completed", completed_levels)
    cfg.set_value("progress", "records", level_records)
    cfg.save(SAVE_PATH)

# 标记通关；立即写盘
func complete_level(level_id: String) -> void:
    completed_levels[level_id] = true
    _save_to_disk()

# 记录一次通关：time（秒）、sun_remaining、used_wallnut
# 返回 is_new_record: bool
func record_completion(level_id: String, time: float, sun_remaining: int, used_wallnut: bool) -> bool:
    var prev: Dictionary = level_records.get(level_id, {})
    var is_new: bool = false
    if not prev.has("best_time") or time < prev.best_time:
        is_new = true
    var new_record: Dictionary = {
        "best_time": min(time, prev.get("best_time", INF)),
        "max_sun": max(sun_remaining, prev.get("max_sun", 0)),
        "no_wallnut": prev.get("no_wallnut", false) or not used_wallnut,
    }
    level_records[level_id] = new_record
    _save_to_disk()
    return is_new

func get_level_record(level_id: String) -> Dictionary:
    return level_records.get(level_id, {})

# 是否解锁：
#   - 第一关默认解锁
#   - 第 N 关解锁 = 第 N-1 关已通关
func is_level_unlocked(idx: int) -> bool:
    if idx <= 0:
        return true
    if idx >= PlantDB.LEVELS.size():
        return false
    var prev_id: String = PlantDB.LEVELS[idx - 1].id
    return completed_levels.get(prev_id, false)

# 设置当前关卡（供 LevelSelect 点击时调用）
func set_level(level_id: String) -> void:
    current_level_id = level_id

# 取当前关卡的字典；找不到就用第一个
func get_current_level() -> Dictionary:
    var idx := PlantDB.find_level_index(current_level_id)
    if idx < 0:
        idx = 0
    return PlantDB.LEVELS[idx]

# Setter 用于自动发出信号，外部直接 += 也能触发 ----------------------
func _set_sun(value: int) -> void:
    sun_amount = max(0, value)
    sun_changed.emit(sun_amount)

func _set_fertilizer(value: int) -> void:
    fertilizer = max(0, value)
    fertilizer_changed.emit(fertilizer)

func _set_selected(value: String) -> void:
    selected_plant_id = value
    selected_plant_changed.emit(value)

# 便捷方法 ------------------------------------------------------------
func can_afford(cost: int) -> bool:
    return sun_amount >= cost

func spend(cost: int) -> bool:
    if not can_afford(cost):
        return false
    sun_amount -= cost
    return true

func advance_wave(total: int) -> void:
    current_wave += 1
    total_waves = total
    wave_changed.emit(current_wave, total)

func declare_win() -> void:
    if is_game_over:
        return
    is_game_over = true
    game_won.emit()

func declare_loss() -> void:
    if is_game_over:
        return
    is_game_over = true
    game_lost.emit()
