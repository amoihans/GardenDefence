# scripts/magnet_shroom.gd
# ----------------------------------------------------------------------
# 磁力菇：吸走金属护盾
#   - 每 8 秒吸走同行最近的"有 shield_hp 字段"的僵尸的护盾
#   - 当前只对 newspaper_zombie 有效（其它护盾僵尸没有 shield_hp 字段）
#   - 吸走时调用该僵尸的 _strip_shield() 方法（如果存在），否则直接清 0
#   - 视觉：磁力菇闪烁 + 蓝色磁力线
# ----------------------------------------------------------------------
extends Plant

@export var fire_interval: float = 8.0

var _fire_timer: Timer
var _saved_fire_interval: float = 0.0

func _on_ready_setup() -> void:
    _fire_timer = Timer.new()
    _fire_timer.wait_time = fire_interval
    _fire_timer.one_shot = false
    _fire_timer.autostart = true
    add_child(_fire_timer)
    _fire_timer.timeout.connect(_magnetize)

func _magnetize() -> void:
    # 找同行最近的"有 shield"僵尸（shield_hp > 0）
    var target: Node = null
    var best_x: float = INF
    for node in get_tree().get_nodes_in_group("zombies"):
        var z = node as Node
        if z == null: continue
        if "row" in z and z.row != row: continue
        if not ("shield_hp" in z): continue
        if z.shield_hp <= 0.0: continue
        # 找最近的（按 x 距离）
        if z.global_position.x < best_x:
            best_x = z.global_position.x
            target = z
    if target == null:
        return                                  # 这行没有护盾僵尸，浪费一次
    # 拆护盾
    if target.has_method("_strip_shield"):
        target._strip_shield()
    else:
        target.shield_hp = 0.0
    # 视觉
    _spawn_arc_to(target.global_position)
    Sfx.play_shoot()                              # 复用发射音

func _strip_shield() -> void:
    # 磁力菇本身没有 shield —— 这是给其它僵尸"被吸"的回调（如果它们愿意重写）
    pass

func _spawn_arc_to(target_pos: Vector2) -> void:
    # 简单磁力线：3 个蓝色圆点从磁力菇飞向目标
    for i in 4:
        var dot := ColorRect.new()
        dot.color = Color(0.4, 0.6, 1.0, 0.9)
        dot.size = Vector2(6, 6)
        dot.position = global_position - Vector2(3, 3)
        var game := get_tree().get_first_node_in_group("game_root")
        if game:
            game.add_child(dot)
        else:
            get_parent().add_child(dot)
        var t := dot.create_tween()
        t.tween_property(dot, "position", target_pos, 0.3) \
            .set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
        t.parallel().tween_property(dot, "modulate:a", 0.0, 0.3)
        t.tween_callback(dot.queue_free)
        # 错开 0.05s
        await get_tree().create_timer(0.05, false).timeout
        if not is_instance_valid(self):
            return

# 肥料：8s → 3s（吸盾频率 ×2.5）
func fertilize() -> void:
    if _boost_active or _fire_timer == null:
        return
    _boost_active = true
    _saved_fire_interval = _fire_timer.wait_time
    _fire_timer.wait_time = _saved_fire_interval / 2.5
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
