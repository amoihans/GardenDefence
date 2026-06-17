# scripts/code_book.gd
# ----------------------------------------------------------------------
# 图鉴主页面：两个 tab（植物 / 僵尸）
# 网格展示所有条目，未发现的是锁住态
# ----------------------------------------------------------------------
extends Control

const CodeBookItemScene := preload("res://scenes/ui/CodeBookItem.tscn")
const COLS := 4

enum Tab { PLANT, ZOMBIE }

@onready var back_btn: Button = $TopBar/BackBtn
@onready var title: Label = $TopBar/Title
@onready var tab_plant_btn: Button = $Tabs/TabPlant
@onready var tab_zombie_btn: Button = $Tabs/TabZombie
@onready var grid: GridContainer = $Center/Scroll/Grid
@onready var progress_label: Label = $Center/Progress

var _current_tab: Tab = Tab.PLANT

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    title.text = "图鉴"
    back_btn.pressed.connect(_on_back)
    tab_plant_btn.pressed.connect(_on_tab_plant)
    tab_zombie_btn.pressed.connect(_on_tab_zombie)
    grid.columns = COLS
    _render()

func _on_tab_plant() -> void:
    _current_tab = Tab.PLANT
    _render()

func _on_tab_zombie() -> void:
    _current_tab = Tab.ZOMBIE
    _render()

func _render() -> void:
    # 清空旧
    for child in grid.get_children():
        child.queue_free()
    # 切 tab 高亮
    if _current_tab == Tab.PLANT:
        tab_plant_btn.modulate = Color(1, 0.9, 0.5, 1)
        tab_zombie_btn.modulate = Color(0.7, 0.7, 0.7, 1)
    else:
        tab_plant_btn.modulate = Color(0.7, 0.7, 0.7, 1)
        tab_zombie_btn.modulate = Color(1, 0.9, 0.5, 1)

    if _current_tab == Tab.PLANT:
        _render_plants()
    else:
        _render_zombies()

func _render_plants() -> void:
    var total: int = 0
    var found: int = 0
    # 按 HUD_PLANT_ORDER 展示（含顺序）
    for id in PlantDB.HUD_PLANT_ORDER:
        total += 1
        var data: Dictionary = PlantDB.PLANTS[id]
        var discovered: bool = CodeBookDB.is_plant_discovered(id)
        if discovered:
            found += 1
        _add_item("plant", id, data, discovered)
    progress_label.text = "已发现 %d / %d" % [found, total]

func _render_zombies() -> void:
    # 用 PlantDB.ZOMBIES 的 keys 顺序展示
    var keys: Array = PlantDB.ZOMBIES.keys()
    var total: int = keys.size()
    var found: int = 0
    for id in keys:
        var data: Dictionary = PlantDB.ZOMBIES[id]
        var discovered: bool = CodeBookDB.is_zombie_discovered(id)
        if discovered:
            found += 1
        _add_item("zombie", id, data, discovered)
    progress_label.text = "已发现 %d / %d" % [found, total]

func _add_item(kind: String, id: String, data: Dictionary, discovered: bool) -> void:
    var item: Control = CodeBookItemScene.instantiate()
    grid.add_child(item)
    item.custom_minimum_size = Vector2(280, 180)
    item.setup(kind, id, data, discovered)

func _on_back() -> void:
    get_tree().change_scene_to_file("res://scenes/main/MainMenu.tscn")
