# scripts/sun.gd
# ----------------------------------------------------------------------
# 阳光掉落物：可被点击收集，超时自动消失
#
# 两种生成方式：
#   1. 天降：从屏幕外上方自由落到草坪某处 → 停留 8s
#   2. 向日葵生产：落在脚边偏移处 → 停留 8s
# ----------------------------------------------------------------------
extends Area2D

const VALUE := 25                              # 收集后加多少阳光
const LIFETIME := 8.0                          # 自动消失时间
const FALL_SPEED := 80.0                       # 天降时下落速度

var _is_falling: bool = false                  # 是否处于"下落到地面"状态
var _ground_y: float = 0.0                     # 落地目标 y
var _lifetime_remaining: float = LIFETIME
var _collected: bool = false

func _ready() -> void:
    add_to_group("suns")
    input_event.connect(_on_input_event)
    # 注意：Area2D 的 input_pickable 要为 true（场景里设置）

# 天降阳光调用：从指定高度落到 ground_y --------------------------------
func skyfall(start_pos: Vector2, ground_y: float) -> void:
    global_position = start_pos
    _ground_y = ground_y
    _is_falling = true

# 向日葵阳光调用：原地小跳一下 ----------------------------------------
func ground_pop() -> void:
    var origin := global_position
    var t := create_tween()
    t.tween_property(self, "global_position",
        origin + Vector2(randf_range(-32, 32), -40), 0.25)
    t.tween_property(self, "global_position",
        origin + Vector2(randf_range(-32, 32), 0), 0.35)

func _process(delta: float) -> void:
    if _collected:
        return
    if _is_falling:
        global_position.y += FALL_SPEED * delta
        if global_position.y >= _ground_y:
            global_position.y = _ground_y
            _is_falling = false
    else:
        _lifetime_remaining -= delta
        # 最后 1 秒闪烁提醒
        if _lifetime_remaining < 1.0:
            modulate.a = 0.4 + 0.6 * abs(sin(_lifetime_remaining * 12))
        if _lifetime_remaining <= 0.0:
            queue_free()

func _on_input_event(_viewport, event: InputEvent, _shape_idx) -> void:
    if _collected:
        return
    if event is InputEventMouseButton and event.pressed \
            and event.button_index == MOUSE_BUTTON_LEFT:
        _collect()

func _collect() -> void:
    _collected = true
    # 飞向 HUD 左上角的阳光计数器
    var target := Vector2(60, 40)
    var t := create_tween()
    t.set_parallel(true)
    t.tween_property(self, "global_position", target, 0.4)\
        .set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
    t.tween_property(self, "scale", Vector2(0.4, 0.4), 0.4)
    t.tween_property(self, "modulate:a", 0.3, 0.4)
    t.chain().tween_callback(_finish_collect)

func _finish_collect() -> void:
    GameState.sun_amount += VALUE
    Sfx.play_sun_collect()
    queue_free()
