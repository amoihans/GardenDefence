# scripts/cherrybomb.gd
# ----------------------------------------------------------------------
# 樱桃炸弹：落地 1.2 秒后引爆，3×3 范围内（以自身格子为中心）的所有
# 僵尸受到 1800 伤害，自身销毁。
# ----------------------------------------------------------------------
extends Plant

const FUSE_TIME := 1.2
const EXPLOSION_DAMAGE := 1800.0
const EXPLOSION_RADIUS_CELLS := 1.5            # 半径 1.5 格 ≈ 3x3

var _fuse_tween: Tween
var _fertilized: bool = false

func _on_ready_setup() -> void:
    contact_damage_immune = true                # 引爆前不会被啃死
    # 节奏感：抖动 → 膨胀 → 爆炸
    _fuse_tween = create_tween()
    _fuse_tween.set_loops(int(FUSE_TIME / 0.2))
    _fuse_tween.tween_property(sprite, "scale", Vector2(1.1, 1.1), 0.1)
    _fuse_tween.tween_property(sprite, "scale", Vector2(1.0, 1.0), 0.1)
    # 引信结束 → 爆炸
    await get_tree().create_timer(FUSE_TIME, false).timeout
    if is_instance_valid(self):
        _explode()

func _explode() -> void:
    if _fertilized:
        return
    _fertilized = true
    var center := global_position
    var radius_px: float = EXPLOSION_RADIUS_CELLS * PlantDB.CELL_SIZE
    Sfx.play_explosion()
    # 视觉效果：白圆扩散
    _spawn_blast(center, radius_px)
    # 对范围内所有僵尸造成伤害
    for node in get_tree().get_nodes_in_group("zombies"):
        var z := node as Zombie
        if z == null: continue
        if z.global_position.distance_to(center) <= radius_px:
            z.take_damage(EXPLOSION_DAMAGE)
    # 自身销毁
    # 屏幕震动
    var game := get_tree().get_first_node_in_group("game_root")
    if game:
        game.shake(20.0, 0.35)
    queue_free()

# 肥料：立刻引爆
func fertilize() -> void:
    if _fuse_tween != null and _fuse_tween.is_valid():
        _fuse_tween.kill()
    _explode()

func _spawn_blast(at: Vector2, radius: float) -> void:
    # 火花（黄/红）
    Particles.sparks(self, at, Color(1.0, 0.8, 0.0))
    Particles.sparks(self, at, Color(1.0, 0.3, 0.0))
    # 用 ColorRect + tween 做个最简单的爆炸圈
    var ring := ColorRect.new()
    ring.color = Color(1.0, 0.6, 0.0, 0.8)
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
