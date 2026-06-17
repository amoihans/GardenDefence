# scripts/peashooter.gd
# ----------------------------------------------------------------------
# 豌豆射手：基础射手。
#   同行存在僵尸（x > 自身 x）时，每 1.4 秒朝 row_offsets 里的每一行射豌豆。
#   row_offsets 默认 [0]（只射自己这一行）。
#   Threepeater.tscn 设成 [-1, 0, 1] → 三行齐射。
# ----------------------------------------------------------------------
extends Plant

const PEA_SCENE := preload("res://scenes/projectiles/Pea.tscn")
@export var fire_interval: float = 1.4
@export var pea_damage: float = 20.0
@export var burst_count: int = 1               # repeater 把这设为 2
@export var burst_gap: float = 0.18
@export var row_offsets: Array[int] = [0]      # 三线射手 = [-1, 0, 1]

var _fire_timer: Timer
var _saved_fire_interval: float = 0.0           # 肥料回退用

func _on_ready_setup() -> void:
    _fire_timer = Timer.new()
    _fire_timer.wait_time = fire_interval
    _fire_timer.one_shot = false
    _fire_timer.autostart = true
    add_child(_fire_timer)
    _fire_timer.timeout.connect(_try_fire)

func _try_fire() -> void:
    if not _has_zombie_in_my_row() and not _has_zombie_in_offset_rows():
        return
    for i in burst_count:
        for offset in row_offsets:
            _shoot_pea(offset)
        if i < burst_count - 1:
            await get_tree().create_timer(burst_gap).timeout
            if not is_instance_valid(self):
                return

# 自己这一行（offset 0）需要判断
func _has_zombie_in_my_row() -> bool:
    return _row_has_zombie(0)

# 其它行（offset != 0）需要判断
func _has_zombie_in_offset_rows() -> bool:
    for offset in row_offsets:
        if offset != 0 and _row_has_zombie(offset):
            return true
    return false

func _row_has_zombie(offset: int) -> bool:
    var target_row := row + offset
    if target_row < 0 or target_row >= PlantDB.GRID_ROWS:
        return false
    for node in get_tree().get_nodes_in_group("zombies"):
        var z := node as Zombie
        if z == null: continue
        if z.row != target_row: continue
        if z.global_position.x > global_position.x - 16:
            return true
    return false

func _shoot_pea(row_offset: int = 0) -> void:
    var target_row := row + row_offset
    if target_row < 0 or target_row >= PlantDB.GRID_ROWS:
        return
    var pea: Node2D = PEA_SCENE.instantiate()
    var game := get_tree().get_first_node_in_group("game_root")
    if game:
        game.add_child(pea)
    else:
        get_parent().add_child(pea)
    # 子弹从植物嘴位置射出，按 row_offset 上下偏移
    pea.global_position = global_position + Vector2(20, -10 + row_offset * PlantDB.CELL_SIZE)
    if pea.has_method("setup"):
        pea.setup(target_row, pea_damage)
    Sfx.play_shoot()
    var t := create_tween()
    t.tween_property(sprite, "position", Vector2(-3, 0), 0.05)
    t.tween_property(sprite, "position", Vector2.ZERO, 0.1)

# 肥料：5 秒内 fire_interval 缩到 1/3（即射速 ×3）
func fertilize() -> void:
    if _boost_active or _fire_timer == null:
        return
    _boost_active = true
    _saved_fire_interval = _fire_timer.wait_time
    _fire_timer.wait_time = _saved_fire_interval / 3.0
    _apply_boost_visual(true)
    var t := Timer.new()
    t.one_shot = true
    t.wait_time = BOOST_DURATION
    add_child(t)
    t.timeout.connect(_on_fertilize_finished)
    t.start()

func _on_fertilize_finished() -> void:
    if _fire_timer != null:
        _fire_timer.wait_time = _saved_fire_interval
    _boost_active = false
    _apply_boost_visual(false)
