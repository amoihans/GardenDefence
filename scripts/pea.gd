# scripts/pea.gd
# ----------------------------------------------------------------------
# 豌豆子弹
#   - 以固定 x 速度向右飞
#   - 命中同行第一个僵尸 → 扣血 → 自毁
#   - 飞出屏幕 → 自毁
# ----------------------------------------------------------------------
extends Node2D

const SPEED := 360.0

var row: int = -1
var damage: float = 20.0

func setup(row_index: int, dmg: float) -> void:
    row = row_index
    damage = dmg

func _ready() -> void:
    add_to_group("peas")
    # 命中检测：每帧用 group + 距离判断，最简单粗暴
    set_process(true)

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
            _hit_effect()
            queue_free()
            return

func _hit_effect() -> void:
    # 简单的命中闪光：复制一个变大变透明的自己
    var flash := Sprite2D.new()
    flash.texture = $Sprite2D.texture
    flash.global_position = global_position
    flash.modulate = Color(1, 1, 1, 0.7)
    get_parent().add_child(flash)
    var t := flash.create_tween()
    t.parallel().tween_property(flash, "scale", Vector2(2, 2), 0.15)
    t.parallel().tween_property(flash, "modulate:a", 0.0, 0.15)
    t.tween_callback(flash.queue_free)
