# scripts/ice_pea.gd
# ----------------------------------------------------------------------
# 冰豆子弹：和 Pea 一样飞行 + 命中；额外给目标加减速。
# 减速机制：直接修改目标 Zombie 的 speed = base_speed * 0.5，
#           同时记录一个 Timer 倒计时，到期恢复。
# ----------------------------------------------------------------------
extends Node2D

const SPEED := 360.0
const SLOW_DURATION := 2.0
const SLOW_FACTOR := 0.5             # 1=不变；0.5=半速

var row: int = -1
var damage: float = 20.0

func setup(row_index: int, dmg: float) -> void:
    row = row_index
    damage = dmg

func _ready() -> void:
    add_to_group("peas")

func _process(delta: float) -> void:
    global_position.x += SPEED * delta
    if global_position.x > PlantDB.SCREEN_W + 16:
        queue_free()
        return
    for node in get_tree().get_nodes_in_group("zombies"):
        var z := node as Zombie
        if z == null: continue
        if z.row != row: continue
        if abs(z.global_position.x - global_position.x) < 32 \
                and abs(z.global_position.y - global_position.y) < 32:
            z.take_damage(damage)
            z.apply_slow(SLOW_FACTOR, SLOW_DURATION)
            _hit_effect()
            queue_free()
            return

func _hit_effect() -> void:
    # 蓝色闪光
    var flash := Sprite2D.new()
    flash.texture = $Sprite2D.texture
    flash.global_position = global_position
    flash.modulate = Color(0.6, 0.9, 1.0, 0.85)
    get_parent().add_child(flash)
    var t := flash.create_tween()
    t.parallel().tween_property(flash, "scale", Vector2(2, 2), 0.18)
    t.parallel().tween_property(flash, "modulate:a", 0.0, 0.18)
    t.tween_callback(flash.queue_free)
