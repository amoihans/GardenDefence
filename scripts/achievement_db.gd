# scripts/achievement_db.gd
# ----------------------------------------------------------------------
# 成就数据库（AutoLoad 单例）
#
# 数据：
#   - ACHIEVEMENTS：8 个成就的元数据
#   - stats：累计统计（跨关卡持久化）
#   - unlocked：已解锁成就（key = id）
#
# 写入位置：user://achievements.cfg
#
# 通讯：游戏事件 → AchievementDB.on_xxx() → 检查 → 解锁 → emit
# ----------------------------------------------------------------------
extends Node

const SAVE_PATH := "user://achievements.cfg"

signal achievement_unlocked(achievement_id: String)

# 成就元数据
const ACHIEVEMENTS: Dictionary = {
	"first_blood": {
		"name": "首次击杀",
		"description": "击杀第一只僵尸",
		"icon": "💀",
	},
	"zombie_killer_100": {
		"name": "僵尸杀手",
		"description": "累计击杀 100 只僵尸",
		"icon": "🧟",
	},
	"green_thumb": {
		"name": "园艺高手",
		"description": "累计种植 50 棵植物",
		"icon": "🌱",
	},
	"sun_master": {
		"name": "阳光大师",
		"description": "累计收集 1000 颗阳光",
		"icon": "☀",
	},
	"first_clear": {
		"name": "初次通关",
		"description": "通关任意关卡",
		"icon": "🏆",
	},
	"day3_clear": {
		"name": "终日之刃",
		"description": "通关白天第 3 关",
		"icon": "👑",
	},
	"fertilizer_user": {
		"name": "精准施肥",
		"description": "使用一次肥料",
		"icon": "🧪",
	},
	"no_wallnut": {
		"name": "无坚果通关",
		"description": "不用坚果通关任一关卡",
		"icon": "🥋",
	},
}

# 当前进度
var stats: Dictionary = {
	"zombies_killed": 0,
	"plants_planted": 0,
	"sun_collected": 0,
	"fertilizer_used": 0,
	"levels_cleared": [],
	"levels_cleared_without_wallnut": [],
}

var unlocked: Dictionary = {}                       # id: true

# 本关临时追踪
var _current_level_id: String = ""
var _current_level_wallnut_count: int = 0

func _ready() -> void:
	_load()

# ---------- 持久化 ----------
func _load() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	var saved_stats = cfg.get_value("stats", "data", {})
	# 合并避免旧存档缺字段
	for k in stats.keys():
		if saved_stats.has(k):
			stats[k] = saved_stats[k]
	unlocked = cfg.get_value("unlocked", "data", {}).duplicate(true)

func _save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("stats", "data", stats)
	cfg.set_value("unlocked", "data", unlocked)
	cfg.save(SAVE_PATH)

# ---------- 事件入口 ----------
func on_zombie_killed() -> void:
	stats.zombies_killed += 1
	_save()
	if stats.zombies_killed >= 1: _unlock("first_blood")
	if stats.zombies_killed >= 100: _unlock("zombie_killer_100")

func on_plant_planted(plant_id: String) -> void:
	stats.plants_planted += 1
	if plant_id == "wallnut":
		_current_level_wallnut_count += 1
	_save()
	if stats.plants_planted >= 50: _unlock("green_thumb")

func on_sun_collected(amount: int) -> void:
	stats.sun_collected += amount
	_save()
	if stats.sun_collected >= 1000: _unlock("sun_master")

func on_fertilizer_used() -> void:
	stats.fertilizer_used += 1
	_save()
	if stats.fertilizer_used >= 1: _unlock("fertilizer_user")

func on_level_started(level_id: String) -> void:
	_current_level_id = level_id
	_current_level_wallnut_count = 0

func on_level_cleared(level_id: String) -> void:
	if not (level_id in stats.levels_cleared):
		stats.levels_cleared.append(level_id)
	if _current_level_wallnut_count == 0 and not (level_id in stats.levels_cleared_without_wallnut):
		stats.levels_cleared_without_wallnut.append(level_id)
	_save()
	_unlock("first_clear")
	if level_id == "day3":
		_unlock("day3_clear")
	if _current_level_wallnut_count == 0:
		_unlock("no_wallnut")

# ---------- 内部 ----------
func _unlock(id: String) -> void:
	if unlocked.get(id, false):
		return
	unlocked[id] = true
	_save()
	achievement_unlocked.emit(id)

func is_unlocked(id: String) -> bool:
	return unlocked.get(id, false)

# 重置（调试用）
func reset() -> void:
	stats = {
		"zombies_killed": 0,
		"plants_planted": 0,
		"sun_collected": 0,
		"fertilizer_used": 0,
		"levels_cleared": [],
		"levels_cleared_without_wallnut": [],
	}
	unlocked = {}
	_save()
