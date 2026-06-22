# scripts/fume_shroom.gd
# ----------------------------------------------------------------------
# 忧郁菇：范围攻击的蘑菇
#   - 不分 row —— 整张草坪 220 像素内所有僵尸都受到伤害
#   - 但范围不分远近都是同样的伤害（不是 PvZ 原版的距离衰减）
#   - 飞行单位（气球）也能打到（不走 row 判定）
# ----------------------------------------------------------------------
extends Plant

@export var fire_interval: float = 1.5
@export var damage: float = 20.0
@export var radius: float = 220.0

var _fire_timer: Timer
var _saved_fire_interval: float = 0.0

func _on_ready_setup() -> void:
    _fire_timer = Timer.new()
    _fire_timer.wait_time = fire_interval
    _fire_timer.one_shot = false
    _fire_timer.autostart = true
    add_child(_fire_timer)
    _fire_timer.timeout.connect(_spore_attack)

func _spore_attack() -> void:
    # 视觉：喷一团紫色雾
    _spawn_puff()
    # 范围伤害：所有距离 ≤ radius 的僵尸都打
    for node in get_tree().get_nodes_in_group("zombies"):
        var z = node as Node
        if z == null: continue
        if "is_instance_valid" in z and not z.is_instance_valid(): continue
        if not z.has_method("take_damage"): continue
        if global_position.distance_to(z.global_position) <= radius:
            z.take_damage(damage)
    Sfx.play_shoot()                                # 复用豌豆发射音

func _spawn_puff() -> void:
    # 简单的紫色半透明圆，朝向最近的僵尸方向偏移
    var puff := ColorRect.new()
    puff.color = Color(0.6, 0.4, 0.9, 0.6)
    puff.size = Vector2(60, 60)
    puff.position = global_position - Vector2(30, 30)
    var game := get_tree().get_first_node_in_group("game_root")
    if game:
        game.add_child(puff)
    else:
        get_parent().add_child(puff)
    var t := puff.create_tween()
    t.parallel().tween_property(puff, "scale", Vector2(2.0, 2.0), 0.4)
    t.parallel().tween_property(puff, "modulate:a", 0.0, 0.4)
    t.tween_callback(puff.queue_free)

# 肥料：射速 ×3
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
