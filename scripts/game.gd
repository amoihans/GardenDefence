# scripts/game.gd
# ----------------------------------------------------------------------
# 战斗主场景脚本
#
# 装配：
#   背景 + 房子 + 草坪 + HUD + WaveManager
#   并接管"种植 / 铲除 / 取消选择 / 暂停 / 胜负面板"等流程。
# ----------------------------------------------------------------------
extends Node2D

const SunScene := preload("res://scenes/pickups/Sun.tscn")
const GameOverPanelScene := preload("res://scenes/ui/GameOverPanel.tscn")
const PauseMenuScene := preload("res://scenes/ui/PauseMenu.tscn")

# 最后一个种下的植物（用于施肥）
var _last_plant: Plant = null

@onready var lawn: Lawn = $Lawn
@onready var hud: HUD = $HUD
@onready var wave_manager: WaveManager = $WaveManager
@onready var sky_timer: Timer = $SkySunTimer
@onready var background: ColorRect = $Background

func _ready() -> void:
    add_to_group("game_root")
    GameState.reset()
    lawn.plant_requested.connect(_on_plant_requested)
    lawn.shovel_requested.connect(_on_shovel_requested)
    hud.card_drag_placed.connect(_on_card_drag_placed)
    GameState.game_won.connect(_on_game_won)
    GameState.game_lost.connect(_on_game_lost)
    hud.pause_pressed.connect(_toggle_pause)
    sky_timer.timeout.connect(_drop_sky_sun)
    wave_manager.level_loaded.connect(_on_level_loaded)
    wave_manager.start()           # 不传 level_id → 读 GameState.current_level_id

func _unhandled_input(event: InputEvent) -> void:
    # 数字键 1~5 选植物，6 选铲子
    if event.is_action_pressed("cancel_selection"):
        GameState.selected_plant_id = ""
    elif event.is_action_pressed("pause"):
        _toggle_pause()
    elif event.is_action_pressed("slot_1"): _try_select_index(0)
    elif event.is_action_pressed("slot_2"): _try_select_index(1)
    elif event.is_action_pressed("slot_3"): _try_select_index(2)
    elif event.is_action_pressed("slot_4"): _try_select_index(3)
    elif event.is_action_pressed("slot_5"): _try_select_index(4)
    elif event.is_action_pressed("slot_6"): GameState.selected_plant_id = "shovel"
    elif event.is_action_pressed("fertilize"):
        _use_fertilize()

# 施肥：给最后种下的植物 + 视觉反馈
func _use_fertilize() -> void:
    if GameState.fertilizer <= 0:
        return
    if not is_instance_valid(_last_plant):
        return
    _last_plant.fertilize()
    GameState.fertilizer -= 1
    AchievementDB.on_fertilizer_used()

func _try_select_index(i: int) -> void:
    if i < 0 or i >= PlantDB.HUD_PLANT_ORDER.size(): return
    var pid: String = PlantDB.HUD_PLANT_ORDER[i]
    if GameState.can_afford(PlantDB.PLANTS[pid].cost):
        GameState.selected_plant_id = pid

# ---------- 种植 ----------
func _on_plant_requested(col: int, row: int, plant_id: String) -> void:
    _place_plant(col, row, plant_id)

# 拖拽释放触发
func _on_card_drag_placed(col: int, row: int, plant_id: String) -> void:
    _place_plant(col, row, plant_id)

# 真正的种植物实现：点击草坪 / 拖拽释放都走这里
func _place_plant(col: int, row: int, plant_id: String) -> void:
    if not lawn.is_empty(col, row): return
    if not PlantDB.PLANTS.has(plant_id): return
    var data: Dictionary = PlantDB.PLANTS[plant_id]
    if not GameState.spend(data.cost): return

    var scene: PackedScene = load(data.scene_path)
    var plant: Plant = scene.instantiate()
    plant.plant_id = plant_id
    plant.max_hp = data.max_hp
    plant.col = col
    plant.row = row
    plant.global_position = PlantDB.cell_to_world(col, row)
    add_child(plant)

    lawn.register_plant(col, row, plant)
    hud.start_cooldown_for(plant_id)
    GameState.selected_plant_id = ""
    # 记录"最后一个种下的植物"，作为肥料目标
    _last_plant = plant
    plant.died.connect(_on_last_plant_died.bind(plant))
    # 成就 + 图鉴
    AchievementDB.on_plant_planted(plant_id)
    CodeBookDB.on_plant_planted(plant_id)

func _on_last_plant_died(plant: Plant) -> void:
    if _last_plant == plant:
        _last_plant = null

# ---------- 铲除 ----------
func _on_shovel_requested(col: int, row: int) -> void:
    if lawn.is_empty(col, row): return
    lawn.remove_plant(col, row)
    GameState.selected_plant_id = ""

# ---------- 天降阳光 ----------
func _drop_sky_sun() -> void:
    if GameState.is_game_over: return
    var sun = SunScene.instantiate()
    add_child(sun)
    var col := randi_range(0, PlantDB.GRID_COLS - 1)
    var row := randi_range(0, PlantDB.GRID_ROWS - 1)
    var landing := PlantDB.cell_to_world(col, row)
    var start_pos := Vector2(landing.x, -32)
    sun.skyfall(start_pos, landing.y)

# ---------- 暂停 ----------
# 显示暂停菜单（如果已经在显示就忽略）
func _toggle_pause() -> void:
    if get_tree().paused:
        return                                  # PauseMenu 自己处理关闭
    var menu := PauseMenuScene.instantiate()
    add_child(menu)

# ---------- 胜负 ----------
func _on_game_won() -> void:
    AchievementDB.on_level_cleared(GameState.current_level_id)
    _show_endgame(true)

func _on_game_lost() -> void:
    _show_endgame(false)

func _show_endgame(won: bool) -> void:
    var panel := GameOverPanelScene.instantiate()
    panel.setup(won)
    add_child(panel)

# ---------- 关卡 ----------
func _on_level_loaded(level_data: Dictionary) -> void:
    hud.set_level_name(level_data.name)
    # 应用环境
    if level_data.has("sky_tint"):
        background.color = level_data.sky_tint
    if level_data.get("no_sky_sun", false):
        sky_timer.stop()
    else:
        if sky_timer.is_stopped():
            sky_timer.start()
    # 开局阳光覆盖
    if level_data.has("start_sun"):
        GameState.sun_amount = level_data.start_sun
    # 成就系统：通知当前关卡
    AchievementDB.on_level_started(level_data.id)
