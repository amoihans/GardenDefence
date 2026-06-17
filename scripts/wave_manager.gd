# scripts/wave_manager.gd
# ----------------------------------------------------------------------
# 波次管理器：按 GameState.current_level_id 对应关卡的 waves 顺序刷僵尸
#
# 流程：
#   - start(level_id) → 用指定关卡；若为空就 fallback 到 GameState.current_level_id
#   - 等 first_wave_delay 秒 → 第 1 波
#   - 每波内：按 interval 间隔刷僵尸
#   - 一波刷完 + 等 rest 秒 → 下一波
#   - 最后一波刷完 → 监听场上僵尸数量，全部清理后宣布胜利
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

func start(level_id: String = "") -> void:
    if _running: return
    _running = true
    _all_spawned = false
    # 解析关卡
    var target_id := level_id
    if target_id == "":
        target_id = GameState.current_level_id
    var idx := PlantDB.find_level_index(target_id)
    if idx < 0:
        push_warning("未找到关卡 id: %s, 用第一个关卡替代" % target_id)
        idx = 0
    _level_data = PlantDB.LEVELS[idx]
    level_loaded.emit(_level_data)
    _run_all_waves()

func _run_all_waves() -> void:
    var waves: Array = _level_data.waves
    var total: int = waves.size()
    # 给玩家一点准备时间
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
    # 等场上僵尸全部死光
    while not GameState.is_game_over:
        await get_tree().create_timer(0.5, false).timeout
        if get_tree().get_nodes_in_group("zombies").is_empty():
            GameState.declare_win()
            return

func _spawn_zombie(zombie_id: String) -> void:
    if not PlantDB.ZOMBIES.has(zombie_id):
        push_error("未知僵尸 id: %s" % zombie_id)
        return
    var data: Dictionary = PlantDB.ZOMBIES[zombie_id]
    var scene: PackedScene = load(data.scene_path)
    var z: Zombie = scene.instantiate()
    z.row = randi() % PlantDB.GRID_ROWS
    z.global_position = Vector2(spawn_x, PlantDB.row_to_y(z.row))
    var game := get_tree().get_first_node_in_group("game_root")
    if game:
        game.add_child(z)
    else:
        get_parent().add_child(z)
    # 成就系统：监听死亡
    z.died.connect(_on_zombie_died)

func _on_zombie_died(_z: Zombie) -> void:
    AchievementDB.on_zombie_killed()
