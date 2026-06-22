# scripts/sun_sucker.gd
# ----------------------------------------------------------------------
# 吸阳菇：自动收集场上阳光
#   - 每 1.5 秒扫描 "suns" group
#   - 找最近的一颗未收集阳光，调用 sun._collect()
#   - sun._collect() 会自己 tween 飞向 HUD + 入账 + 触发成就
#   - 视觉：每收集一次，吸阳菇闪一下
# ----------------------------------------------------------------------
extends Plant

@export var fire_interval: float = 1.5
const COLLECT_RADIUS: float = 600.0             # 整张草坪范围（不再"只吸附近的"）

var _fire_timer: Timer
var _saved_fire_interval: float = 0.0

func _on_ready_setup() -> void:
    _fire_timer = Timer.new()
    _fire_timer.wait_time = fire_interval
    _fire_timer.one_shot = false
    _fire_timer.autostart = true
    add_child(_fire_timer)
    _fire_timer.timeout.connect(_try_collect)

func _try_collect() -> void:
    # 找最近的、未收集的阳光
    var best: Node = null
    var best_dist: float = INF
    for node in get_tree().get_nodes_in_group("suns"):
        var s = node as Node
        if s == null: continue
        if "_collected" in s and s._collected: continue
        # 距离
        var d: float = global_position.distance_to(s.global_position)
        if d < best_dist:
            best_dist = d
            best = s
    if best == null:
        return                                      # 场上没阳光
    # 调用 sun._collect()：它会自己飞向 HUD + 入账
    if best.has_method("_collect"):
        best._collect()
    _flash()

func _flash() -> void:
    # 视觉：紫色脉冲
    if sprite == null: return
    sprite.modulate = Color(1.6, 1.0, 1.8)
    var t := create_tween()
    t.tween_property(sprite, "modulate", Color.WHITE, 0.2)

# 肥料：吸阳光频率 ×2
func fertilize() -> void:
    if _boost_active or _fire_timer == null:
        return
    _boost_active = true
    _saved_fire_interval = _fire_timer.wait_time
    _fire_timer.wait_time = _saved_fire_interval / 2.0
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
