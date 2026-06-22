# scripts/wave_manager.gd
# ----------------------------------------------------------------------
# 波次管理器
#
# 两种模式：
#   - 关卡模式：按 PlantDB.LEVELS[id].waves 顺序刷僵尸（固定波数 → 胜利）
#   - 无尽模式：level_id == "endless"，无限刷 + 难度递增（玩家输 → 结束）
#
# 难度递增规则（每 5 波一轮）：
#   - interval *= 0.85 （min 0.6）
#   - 每波僵尸数 +2 （max 14）
#   - 每升 1 波，僵尸 HP ×1.04、speed ×1.02（小步长累积）
#   - 僵尸池随波次扩充（basic → conehead → buckethead → ... → gargantuar）
# ----------------------------------------------------------------------
extends Node
class_name WaveManager

signal big_wave_started(wave_index: int)
signal level_loaded(level_data: Dictionary)

@export var spawn_x: float = 1240.0
@export var first_wave_delay: float = 5.0

var _running: bool = false
var _all_spawned: bool = false
var _level_data: Dictionary = {}
var _is_endless: bool = false
var last_wave: int = 0                       # 玩家死时停在第几波（给 GameOverPanel 用）

func start(level_id: String = "") -> void:
	if _running: return
	_running = true
	_all_spawned = false
	var target_id := level_id
	if target_id == "":
		target_id = GameState.current_level_id
	# 无尽模式不查 LEVELS —— 自己生成模板
	if target_id == "endless":
		_is_endless = true
		_level_data = _make_endless_template()
		level_loaded.emit(_level_data)
		_run_endless()
		return
	# 坚果保龄
	if target_id == "bowling":
		_is_endless = false
		_level_data = _make_bowling_template()
		level_loaded.emit(_level_data)
		_run_bowling()
		return
	_is_endless = false
	var idx := PlantDB.find_level_index(target_id)
	if idx < 0:
		push_warning("未找到关卡 id: %s, 用第一个关卡替代" % target_id)
		idx = 0
	_level_data = PlantDB.LEVELS[idx]
	level_loaded.emit(_level_data)
	_run_all_waves()

# ---------- 关卡模式（原有逻辑） ----------
func _run_all_waves() -> void:
	var waves: Array = _level_data.waves
	var total: int = waves.size()
	# 注意：必须显式传 process_always=false —— Godot 4 默认是 true，会在暂停时继续刷僵尸
	await get_tree().create_timer(first_wave_delay, false).timeout

	for wi in total:
		if GameState.is_game_over: return
		GameState.advance_wave(total)
		big_wave_started.emit(wi + 1)
		var wave: Dictionary = waves[wi]
		var spawns: Array = wave.spawns
		var interval: float = wave.interval
		for zombie_id in spawns:
			if GameState.is_game_over: return
			_spawn_zombie(zombie_id)
			await get_tree().create_timer(interval, false).timeout
		if wi < total - 1:
			await get_tree().create_timer(wave.rest, false).timeout

	_all_spawned = true
	while not GameState.is_game_over:
		await get_tree().create_timer(0.5, false).timeout
		if get_tree().get_nodes_in_group("zombies").is_empty():
			GameState.declare_win()
			return

# ---------- 无尽模式 ----------
func _make_endless_template() -> Dictionary:
	# 仅供 level_loaded 信号使用；Hud 显示 "无尽模式"
	return {
		"id": "endless",
		"name": "∞ 无尽模式",
		"description": "无限波。速度/血量/密度随波次递增。死了算结束。",
		"environment": "day",
		"no_sky_sun": false,
		"start_sun": 100,
		"sky_tint": Color(0.40, 0.60, 0.85, 1),
		"waves": [],
	}

func _run_endless() -> void:
	await get_tree().create_timer(first_wave_delay, false).timeout
	var wave_index: int = 0
	while not GameState.is_game_over:
		wave_index += 1
		last_wave = wave_index
		# 无尽模式：传 -1 表示"总波数无限"
		GameState.advance_wave(-1)
		big_wave_started.emit(wave_index)
		# 难度系数
		var interval: float = max(0.6, 5.0 * pow(0.85, float(wave_index - 1) / 5.0))
		var hp_mult: float = pow(1.04, float(wave_index - 1))
		var speed_mult: float = pow(1.02, float(wave_index - 1))
		# 当前可用的僵尸池
		var pool: Array = _zombie_pool_for_wave(wave_index)
		# 这一波生成多少只
		var count: int = min(3 + wave_index, 14)
		for i in count:
			if GameState.is_game_over: return
			var zid: String = pool[randi() % pool.size()]
			_spawn_zombie(zid, hp_mult, speed_mult)
			await get_tree().create_timer(interval, false).timeout
		# 波间休息
		var rest: float = max(2.0, 8.0 - wave_index * 0.1)
		await get_tree().create_timer(rest, false).timeout

# 僵尸池随波次扩充
func _zombie_pool_for_wave(w: int) -> Array:
	var pool: Array = ["basic"]
	if w >= 3:  pool.append("conehead")
	if w >= 5:  pool.append("buckethead")
	if w >= 8:  pool.append("flag")
	if w >= 10: pool.append("football")
	if w >= 12: pool.append("newspaper")
	if w >= 15: pool.append("pole_vaulter")
	if w >= 18: pool.append("imp")
	if w >= 20: pool.append("balloon")
	if w >= 22: pool.append("dancer")
	if w >= 25: pool.append("miner")
	if w >= 30: pool.append("gargantuar")
	return pool

# ---------- 通用 ----------
func _spawn_zombie(zombie_id: String, hp_mult: float = 1.0, speed_mult: float = 1.0) -> void:
	if not PlantDB.ZOMBIES.has(zombie_id):
		push_error("未知僵尸 id: %s" % zombie_id)
		return
	var data: Dictionary = PlantDB.ZOMBIES[zombie_id]
	var scene: PackedScene = load(data.scene_path)
	var z: Zombie = scene.instantiate()
	z.row = randi() % PlantDB.GRID_ROWS
	z.global_position = Vector2(spawn_x, PlantDB.row_to_y(z.row))
	# 无尽模式：叠加 HP / 速度系数
	if hp_mult != 1.0:
		z.max_hp *= hp_mult
		z.current_hp = z.max_hp
	if speed_mult != 1.0:
		z.base_speed *= speed_mult
		z.current_speed = z.base_speed
	var game := get_tree().get_first_node_in_group("game_root")
	if game:
		game.add_child(z)
	else:
		get_parent().add_child(z)
	z.died.connect(_on_zombie_died)
	CodeBookDB.on_zombie_spawned(zombie_id)

func _on_zombie_died(_z: Zombie) -> void:
	AchievementDB.on_zombie_killed()

# ---------- 坚果保龄模式 ----------
const BOWLING_NUT_SCENE := preload("res://scenes/pickups/BowlingNut.tscn")
const BOWLING_TOTAL: int = 3
const BOWLING_ZOMBIE_ROWS: Array = [0, 1, 2, 3, 4]
const BOWLING_ZOMBIE_TYPES: Array = ["basic", "conehead", "basic", "buckethead", "basic"]

# 暴露给 game.gd 读：剩余坚果数
var nuts_remaining: int = BOWLING_TOTAL
var nuts_used: int = 0

func _make_bowling_template() -> Dictionary:
	return {
		"id": "bowling",
		"name": "🎳 坚果保龄",
		"description": "3 颗坚果，发射撞飞僵尸。Space 发射。",
		"environment": "day",
		"no_sky_sun": true,
		"start_sun": 0,
		"sky_tint": Color(0.40, 0.60, 0.85, 1),
		"waves": [],
	}

func _run_bowling() -> void:
	nuts_remaining = BOWLING_TOTAL
	nuts_used = 0
	GameState.advance_wave(1)
	big_wave_started.emit(1)
	# 暂停天降阳光 + 不开向日葵
	# 一次性刷一排僵尸
	for i in BOWLING_ZOMBIE_TYPES.size():
		var zid: String = BOWLING_ZOMBIE_TYPES[i]
		var r: int = BOWLING_ZOMBIE_ROWS[i]
		_spawn_zombie_at(zid, r, 1100.0)
	# 等坚果发射 / 等玩家输
	# 输：坚果用完 + 场上还有僵尸
	while not GameState.is_game_over:
		await get_tree().create_timer(0.5, false).timeout
		if get_tree().get_nodes_in_group("zombies").is_empty():
			GameState.declare_win()
			return

func _spawn_zombie_at(zombie_id: String, row: int, x: float) -> void:
	if not PlantDB.ZOMBIES.has(zombie_id):
		return
	var data: Dictionary = PlantDB.ZOMBIES[zombie_id]
	var scene: PackedScene = load(data.scene_path)
	var z: Zombie = scene.instantiate()
	z.row = row
	z.global_position = Vector2(x, PlantDB.row_to_y(row))
	var game := get_tree().get_first_node_in_group("game_root")
	if game:
		game.add_child(z)
	else:
		get_parent().add_child(z)
	z.died.connect(_on_zombie_died)
	CodeBookDB.on_zombie_spawned(zombie_id)

# game.gd 调用：玩家按 Space
func fire_bowling_nut(row: int) -> bool:
	if nuts_remaining <= 0:
		return false
	if GameState.is_game_over:
		return false
	nuts_remaining -= 1
	nuts_used += 1
	var nut = BOWLING_NUT_SCENE.instantiate()
	nut.row = row
	nut.global_position = Vector2(PlantDB.LAWN_ORIGIN_X - 30, PlantDB.row_to_y(row))
	var game := get_tree().get_first_node_in_group("game_root")
	if game:
		game.add_child(nut)
	else:
		get_parent().add_child(nut)
	Sfx.play_shoot()
	return true
