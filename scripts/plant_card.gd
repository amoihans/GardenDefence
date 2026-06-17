# scripts/plant_card.gd
# ----------------------------------------------------------------------
# HUD 上的一张植物卡片
#
# 支持两种交互：
#   1. 单击模式：点卡片 → 选植物 → 点格子放下（保留原 PvZ "两段式"操作）
#   2. 拖拽模式：按住卡片拖到格子上抬起放下（现代 PvZ 操作）
#
# 用位移阈值（DRAG_THRESHOLD = 6 px）区分点 vs 拖。
# ----------------------------------------------------------------------
extends Control
class_name PlantCard

signal pressed_card(plant_id: String)              # 单击：HUD 收到后会写入 GameState.selected_plant_id
signal drag_placed(col: int, row: int, plant_id: String)   # 拖拽释放到合法格子上

@export var plant_id: String = ""

const DRAG_THRESHOLD := 6.0

@onready var bg: TextureRect = $Background
@onready var icon: TextureRect = $Icon
@onready var cost_label: Label = $CostLabel
@onready var cooldown_overlay: ColorRect = $CooldownOverlay
@onready var select_border: Panel = $SelectBorder

var cost: int = 0
var cooldown: float = 0.0
var _cd_remaining: float = 0.0

# 拖拽状态
var _tracking_press: bool = false    # 本次按下是否由本卡片捕获
var _dragging: bool = false          # 是否真的进入了拖拽态
var _press_pos: Vector2 = Vector2.ZERO
var _ghost: Sprite2D = null          # 跟手的"幽灵植物"，加到 Game 节点下

func _ready() -> void:
    if plant_id == "" or not PlantDB.PLANTS.has(plant_id):
        return
    var data: Dictionary = PlantDB.PLANTS[plant_id]
    cost = data.cost
    cooldown = data.cooldown
    cost_label.text = str(cost)
    icon.texture = load(data.icon_path)
    select_border.visible = false
    cooldown_overlay.size = Vector2(0, 0)
    custom_minimum_size = Vector2(72, 96)
    GameState.sun_changed.connect(_refresh_affordable)
    GameState.selected_plant_changed.connect(_refresh_selected)
    gui_input.connect(_on_gui_input)
    set_process_unhandled_input(true)              # ★ 让卡片在卡外释放时也能收到事件
    _refresh_affordable(GameState.sun_amount)

# 当前能不能点 --------------------------------------------------------
func is_usable() -> bool:
    return _cd_remaining <= 0.0 and GameState.can_afford(cost)

# 阳光变化时更新视觉 --------------------------------------------------
func _refresh_affordable(_amount: int) -> void:
    if GameState.can_afford(cost) and _cd_remaining <= 0.0:
        modulate = Color(1, 1, 1, 1)
    else:
        modulate = Color(0.55, 0.55, 0.55, 1)

func _refresh_selected(sel: String) -> void:
    select_border.visible = (sel == plant_id)

# 鼠标在卡片内的按下/抬起（_gui_input 仅在鼠标位于本卡片时触发）----
func _on_gui_input(event: InputEvent) -> void:
    if not (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT):
        return
    if event.pressed:
        # 按下：开始跟踪本卡片作为拖拽源
        if is_usable():
            _tracking_press = true
            _press_pos = event.position
        get_viewport().set_input_as_handled()
    else:
        # 抬起在卡片上：要么刚放下（true 拖拽），要么是纯点击
        if _tracking_press:
            _tracking_press = false
            if _dragging:
                _end_drag()                       # 拖回卡片 = 取消
            else:
                if is_usable():
                    pressed_card.emit(plant_id)    # 纯点击 → 通知 HUD 选中
        get_viewport().set_input_as_handled()

# 在卡外（草坪、屏幕空地）发生的鼠标抬起 -----------------------------
func _unhandled_input(event: InputEvent) -> void:
    if not _tracking_press:
        return
    if not (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT):
        return
    if event.pressed:
        return                                   # 只关心抬起
    _tracking_press = false
    if _dragging:
        _end_drag()
        get_viewport().set_input_as_handled()

# 拖拽结束：尝试在鼠标位置种下，否则什么都不做
func _end_drag() -> void:
    _dragging = false
    _destroy_ghost()
    var cell: Vector2i = PlantDB.world_to_cell(get_global_mouse_position())
    if cell.x >= 0 and is_usable():
        drag_placed.emit(cell.x, cell.y, plant_id)
    # 任何情况下，抬起都清掉当前选择（防止误留状态）
    GameState.selected_plant_id = ""

# 跟手：监测是否进入"真的拖" + 持续更新幽灵位置 + 冷却 -----------
func _process(delta: float) -> void:
    # 1) 拖拽态切换 + 幽灵位置
    if _tracking_press and not _dragging:
        if get_global_mouse_position().distance_to(_press_pos) > DRAG_THRESHOLD:
            _dragging = true
            # 进入拖拽态才真正设置选择；这样纯点击不会留 selection
            GameState.selected_plant_id = plant_id
            _create_ghost()
    if _dragging and _ghost != null:
        _ghost.global_position = get_global_mouse_position()

    # 2) 冷却进度
    if _cd_remaining > 0.0:
        _cd_remaining -= delta
        var p: float = clampf(_cd_remaining / cooldown, 0.0, 1.0)
        var h := size.y * p
        cooldown_overlay.position = Vector2(0, size.y - h)
        cooldown_overlay.size = Vector2(size.x, h)
        if _cd_remaining <= 0.0:
            cooldown_overlay.size = Vector2(size.x, 0)
            _refresh_affordable(GameState.sun_amount)
    else:
        _refresh_affordable(GameState.sun_amount)

# 幽灵 = 一个半透明的植物贴图，挂在 Game 节点下，跟随鼠标 ----------
func _create_ghost() -> void:
    if _ghost != null:
        return
    _ghost = Sprite2D.new()
    _ghost.texture = load(PlantDB.PLANTS[plant_id].icon_path)
    _ghost.modulate = Color(1, 1, 1, 0.7)
    _ghost.z_index = 100
    var game: Node = get_tree().get_first_node_in_group("game_root")
    if game:
        game.add_child(_ghost)
    else:
        get_parent().add_child(_ghost)

func _destroy_ghost() -> void:
    if _ghost != null:
        _ghost.queue_free()
        _ghost = null

# 由 Game 在成功种下时调用，启动冷却 ---------------------------------
func start_cooldown() -> void:
    _cd_remaining = cooldown
