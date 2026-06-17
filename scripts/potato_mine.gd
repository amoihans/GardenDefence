# scripts/potato_mine.gd
# ----------------------------------------------------------------------
# 土豆地雷
#   1. 种下后 ARM_TIME 秒（地下状态）
#   2. 武装好（露出，引信亮红）
#   3. 第一个进入本行攻击范围的僵尸 → 1.5 格内大范围爆炸 + 自毁
# ----------------------------------------------------------------------
extends Plant

const ARM_TIME := 1.5                # 装填时间（秒）
const EXPLOSION_DAMAGE := 1800.0
const EXPLOSION_RADIUS_CELLS := 1.5
const TRIGGER_RANGE_CELLS := 1.4     # 触发半径（用格数 * 96 像素）

var _armed: bool = false

@onready var body: Sprite2D = $Sprite2D

func _on_ready_setup() -> void:
    contact_damage_immune = true     # 装填时不被啃
    # 起手半埋：缩到 0.6
    body.scale = Vector2(0.6, 0.6)
    body.position.y = 20
    body.modulate = Color(0.55, 0.45, 0.35)
    # 装填结束后，弹一下 + 变亮表示就绪
    await get_tree().create_timer(ARM_TIME).timeout
    if not is_instance_valid(self):
        return
    _armed = true
    var t := create_tween()
    t.set_parallel(true)
    t.tween_property(body, "scale", Vector2(1.0, 1.0), 0.2)
    t.tween_property(body, "position", Vector2.ZERO, 0.2)
    t.tween_property(body, "modulate", Color.WHITE, 0.2)
    # 闪 3 下表示就绪
    for i in 3:
        t.tween_property(body, "modulate", Color(1.5, 0.6, 0.6), 0.1)
        t.tween_property(body, "modulate", Color.WHITE, 0.1)

func _process(_delta: float) -> void:
    if not _armed: return
    if GameState.is_game_over: return
    # 检查同行是否已有僵尸走进触发圈
    var trigger_px := TRIGGER_RANGE_CELLS * PlantDB.CELL_SIZE
    for node in get_tree().get_nodes_in_group("zombies"):
        var z := node as Zombie
        if z == null: continue
        if z.row != row: continue
        if abs(z.global_position.x - global_position.x) <= trigger_px:
            _explode()
            return

func _explode() -> void:
    var center := global_position
    var radius_px := EXPLOSION_RADIUS_CELLS * PlantDB.CELL_SIZE
    Sfx.play_explosion()
    _spawn_blast(center, radius_px)
    for node in get_tree().get_nodes_in_group("zombies"):
        var z := node as Zombie
        if z == null: continue
        if z.global_position.distance_to(center) <= radius_px:
            z.take_damage(EXPLOSION_DAMAGE)
    queue_free()

func _spawn_blast(at: Vector2, radius: float) -> void:
    var ring := ColorRect.new()
    ring.color = Color(1.0, 0.4, 0.0, 0.85)
    ring.size = Vector2(radius * 2, radius * 2)
    ring.pivot_offset = ring.size * 0.5
    ring.position = at - ring.size * 0.5
    var game := get_tree().get_first_node_in_group("game_root")
    if game:
        game.add_child(ring)
    else:
        get_parent().add_child(ring)
    var t := ring.create_tween()
    t.parallel().tween_property(ring, "scale", Vector2(1.4, 1.4), 0.4)
    t.parallel().tween_property(ring, "modulate:a", 0.0, 0.4)
    t.tween_callback(ring.queue_free)
