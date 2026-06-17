# scripts/hud.gd
# ----------------------------------------------------------------------
# 顶部 HUD：阳光数、植物卡片栏、铲子、波次提示
# ----------------------------------------------------------------------
extends CanvasLayer
class_name HUD

const PlantCardScene := preload("res://scenes/ui/PlantCard.tscn")

@onready var sun_label: Label = $Bar/SunCount
@onready var fertilizer_label: Label = $Bar/FertilizerLabel
@onready var wave_label: Label = $Bar/WaveLabel
@onready var card_row: HBoxContainer = $Bar/CardRow
@onready var shovel_button: TextureButton = $Bar/Shovel
@onready var pause_button: Button = $Bar/PauseBtn

signal card_pressed(plant_id: String)
signal card_drag_placed(col: int, row: int, plant_id: String)
signal shovel_pressed
signal pause_pressed

var _cards: Dictionary = {}                    # plant_id -> PlantCard

var _level_name: String = ""

func _ready() -> void:
    _build_cards()
    _refresh_sun(GameState.sun_amount)
    _refresh_fertilizer(GameState.fertilizer)
    _refresh_wave(GameState.current_wave, GameState.total_waves)
    GameState.sun_changed.connect(_refresh_sun)
    GameState.fertilizer_changed.connect(_refresh_fertilizer)
    GameState.wave_changed.connect(_refresh_wave)
    GameState.selected_plant_changed.connect(_on_selected_changed)
    shovel_button.pressed.connect(_on_shovel_pressed)
    pause_button.pressed.connect(func(): pause_pressed.emit())

# 由 Game 在 WaveManager.level_loaded 时调用，更新左上角关卡名
func set_level_name(name: String) -> void:
    _level_name = name
    _refresh_wave(GameState.current_wave, GameState.total_waves)

# 根据 PlantDB.HUD_PLANT_ORDER 实例化所有卡片 ------------------------
func _build_cards() -> void:
    for child in card_row.get_children():
        child.queue_free()
    for plant_id in PlantDB.HUD_PLANT_ORDER:
        var card: PlantCard = PlantCardScene.instantiate()
        card.plant_id = plant_id
        card_row.add_child(card)
        card.pressed_card.connect(_on_card_pressed)
        card.drag_placed.connect(_on_card_drag_placed)
        _cards[plant_id] = card

func _on_card_drag_placed(col: int, row: int, plant_id: String) -> void:
    card_drag_placed.emit(col, row, plant_id)

func _on_card_pressed(plant_id: String) -> void:
    GameState.selected_plant_id = plant_id
    card_pressed.emit(plant_id)

func _on_shovel_pressed() -> void:
    GameState.selected_plant_id = "shovel"
    shovel_pressed.emit()

func _on_selected_changed(sel: String) -> void:
    # 铲子高亮
    if sel == "shovel":
        shovel_button.modulate = Color(1.3, 1.3, 0.5)
    else:
        shovel_button.modulate = Color.WHITE

func _refresh_sun(amount: int) -> void:
    sun_label.text = str(amount)

func _refresh_fertilizer(amount: int) -> void:
    fertilizer_label.text = "🌱×%d" % amount
    fertilizer_label.modulate = Color(0.6, 1.0, 0.5, 1) if amount > 0 else Color(0.5, 0.5, 0.5, 0.6)

func _refresh_wave(cur: int, total: int) -> void:
    if total <= 0:
        if _level_name != "":
            wave_label.text = "%s" % _level_name
        else:
            wave_label.text = "准备中"
    else:
        if _level_name != "":
            wave_label.text = "%s  ·  波 %d / %d" % [_level_name, cur, total]
        else:
            wave_label.text = "波 %d / %d" % [cur, total]

# 当成功种下某种植物时由 Game 调用，让卡片进入冷却 -------------------
func start_cooldown_for(plant_id: String) -> void:
    if _cards.has(plant_id):
        _cards[plant_id].start_cooldown()
