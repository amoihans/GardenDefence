# scripts/sun_shroom.gd
# ----------------------------------------------------------------------
# 太阳菇：夜晚用
#   - 小太阳菇：每 12s 产 15 阳光
#   - 长到 30s 后 → 大太阳菇：每 8s 产 25 阳光
#   - 视觉切换：变成金黄大蘑菇
# ----------------------------------------------------------------------
extends Plant

const SUN_SCENE := preload("res://scenes/pickups/Sun.tscn")
const GROW_TIME := 30.0
const PRODUCES_SMALL := 0.6					# 阳光动画变体（颜色偏淡）

var _produce_timer: Timer
var _grown: bool = false
var _elapsed: float = 0.0
var _has_been_fertilized: bool = false

func _on_ready_setup() -> void:
	_produce_timer = Timer.new()
	_produce_timer.wait_time = 12.0
	_produce_timer.one_shot = false
	_produce_timer.autostart = true
	add_child(_produce_timer)
	_produce_timer.timeout.connect(_produce_sun)

func _process(delta: float) -> void:
	_elapsed += delta
	if not _grown and _elapsed >= GROW_TIME:
		_grow()

# 施肥：5 秒内每 1.5s 产一颗
func fertilize() -> void:
	if _has_been_fertilized:
		return
	_has_been_fertilized = true
	# 用 Tween 间隔 5 次
	for i in 5:
		await get_tree().create_timer(1.0, false).timeout
		if not is_instance_valid(self):
			return
		_produce_sun()
	_has_been_fertilized = false

func _grow() -> void:
	_grown = true
	_produce_timer.wait_time = 8.0
	# 视觉：从灰褐小蘑菇 → 金黄大蘑菇
	sprite.modulate = Color(1.6, 1.4, 0.6)
	var t := create_tween()
	t.parallel().tween_property(sprite, "scale", Vector2(1.4, 1.4), 0.3)
	t.tween_property(sprite, "scale", Vector2(1.0, 1.0), 0.2)
	t.tween_callback(func(): sprite.modulate = Color(1.4, 1.1, 0.3))

func _produce_sun() -> void:
	var sun: Node2D = SUN_SCENE.instantiate()
	var game := get_tree().get_first_node_in_group("game_root")
	if game:
		game.add_child(sun)
	else:
		get_parent().add_child(sun)
	sun.global_position = global_position + Vector2(randf_range(-16, 16), -8)
	if sun.has_method("ground_pop"):
		sun.ground_pop()
	# 小弹一下
	var t := create_tween()
	t.tween_property(sprite, "scale", Vector2(1.15, 0.85), 0.08)
	t.tween_property(sprite, "scale", Vector2.ONE, 0.15)
