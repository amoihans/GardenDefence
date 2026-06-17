# scripts/lawn.gd
# ----------------------------------------------------------------------
# 草坪：5 行 × 9 列的网格管理者
#
# 职责：
#   - 把背景画成棋盘条纹（用 ColorRect）
#   - 维护"格子是否被占用"
#   - 把鼠标坐标转换成行列、并高亮悬停的格子
#   - 接收"种植/铲除"请求
#
# 通讯：
#   - 接收外部 set 的 selected（从 GameState.selected_plant_id 而来）
#   - 不直接动 GameState.sun，付费由 Game 的种植流程负责
# ----------------------------------------------------------------------
extends Node2D
class_name Lawn

signal plant_requested(col: int, row: int, plant_id: String)
signal shovel_requested(col: int, row: int)

# 占用矩阵：plants[col][row] = Plant 实例 / null
var plants: Array = []

# 高亮用的 ColorRect，悬停时显示
var _hover_rect: ColorRect

func _ready() -> void:
    add_to_group("lawn")
    _init_grid_data()
    _build_visual_grid()
    _build_hover_indicator()
    _spawn_lawn_mowers()
    set_process(true)
    set_process_unhandled_input(true)

func _init_grid_data() -> void:
    plants.resize(PlantDB.GRID_COLS)
    for c in PlantDB.GRID_COLS:
        plants[c] = []
        plants[c].resize(PlantDB.GRID_ROWS)
        for r in PlantDB.GRID_ROWS:
            plants[c][r] = null

# 用 ColorRect 拼成深浅交替的棋盘 ------------------------------------
func _build_visual_grid() -> void:
    var light := Color(0.486, 0.702, 0.259)    # #7CB342
    var dark  := Color(0.408, 0.624, 0.220)    # #689F38
    for c in PlantDB.GRID_COLS:
        for r in PlantDB.GRID_ROWS:
            var rect := ColorRect.new()
            rect.size = Vector2(PlantDB.CELL_SIZE, PlantDB.CELL_SIZE)
            rect.position = Vector2(
                PlantDB.LAWN_ORIGIN_X + c * PlantDB.CELL_SIZE,
                PlantDB.LAWN_ORIGIN_Y + r * PlantDB.CELL_SIZE)
            rect.color = light if (c + r) % 2 == 0 else dark
            rect.mouse_filter = Control.MOUSE_FILTER_IGNORE   # ★ 不要拦截点击
            add_child(rect)

func _build_hover_indicator() -> void:
    _hover_rect = ColorRect.new()
    _hover_rect.size = Vector2(PlantDB.CELL_SIZE, PlantDB.CELL_SIZE)
    _hover_rect.color = Color(1, 1, 1, 0.0)
    _hover_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(_hover_rect)

# 每帧：刷新悬停高亮 ------------------------------------------------------
func _process(_delta: float) -> void:
    var sel := GameState.selected_plant_id
    if sel == "":
        _hover_rect.color = Color(1, 1, 1, 0)
        return
    var mouse := get_global_mouse_position()
    var cell := PlantDB.world_to_cell(mouse)
    if cell.x < 0:
        _hover_rect.color = Color(1, 1, 1, 0)
        return
    var c: int = cell.x
    var r: int = cell.y
    _hover_rect.position = Vector2(
        PlantDB.LAWN_ORIGIN_X + c * PlantDB.CELL_SIZE,
        PlantDB.LAWN_ORIGIN_Y + r * PlantDB.CELL_SIZE)
    if sel == "shovel":
        # 铲子：有植物 → 红框；无植物 → 不显示
        _hover_rect.color = Color(0.9, 0.2, 0.2, 0.4) if plants[c][r] != null \
            else Color(1, 1, 1, 0)
    else:
        # 植物：空格 → 绿；已占 → 红
        _hover_rect.color = Color(0.2, 1.0, 0.2, 0.35) if plants[c][r] == null \
            else Color(0.9, 0.2, 0.2, 0.35)

# 接收点击 ------------------------------------------------------------
func _unhandled_input(event: InputEvent) -> void:
    if not (event is InputEventMouseButton): return
    if not event.pressed: return
    var sel := GameState.selected_plant_id
    if sel == "": return
    var cell := PlantDB.world_to_cell(get_global_mouse_position())
    if cell.x < 0: return

    if event.button_index == MOUSE_BUTTON_LEFT:
        if sel == "shovel":
            shovel_requested.emit(cell.x, cell.y)
        else:
            plant_requested.emit(cell.x, cell.y, sel)
        get_viewport().set_input_as_handled()
    elif event.button_index == MOUSE_BUTTON_RIGHT:
        GameState.selected_plant_id = ""
        get_viewport().set_input_as_handled()

# 由 Game 实际种下植物后调用 -----------------------------------------
func register_plant(col: int, row: int, plant: Node) -> void:
    plants[col][row] = plant
    plant.died.connect(_on_plant_died.bind(col, row))

func _on_plant_died(_p: Node, col: int, row: int) -> void:
    if col >= 0 and col < PlantDB.GRID_COLS and row >= 0 and row < PlantDB.GRID_ROWS:
        plants[col][row] = null

# 由 Game 在铲除时调用 ------------------------------------------------
func remove_plant(col: int, row: int) -> void:
    var p = plants[col][row]
    if p != null and is_instance_valid(p):
        plants[col][row] = null
        p.queue_free()

func is_empty(col: int, row: int) -> bool:
    return plants[col][row] == null

# 在每行最左侧放一个除草机（最后一道防线）
const LawnMowerScene := preload("res://scenes/pickups/LawnMower.tscn")

func _spawn_lawn_mowers() -> void:
    for r in PlantDB.GRID_ROWS:
        var m = LawnMowerScene.instantiate()
        m.setup(r)
        # x = 草坪最左 - 80 → 稍微露在草坪外但还在画面内
        m.position = Vector2(PlantDB.LAWN_ORIGIN_X - 80, PlantDB.row_to_y(r))
        add_child(m)

# 外部调用：触发某行的除草机
func trigger_lawn_mower(row: int) -> void:
    for node in get_tree().get_nodes_in_group("lawn_mowers"):
        var m = node as Node
        if m == null: continue
        if "row" in m and m.row == row:
            m.trigger()
