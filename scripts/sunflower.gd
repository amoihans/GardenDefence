# scripts/sunflower.gd
# ----------------------------------------------------------------------
# 向日葵：每 8 秒在自身附近生成一颗 25 阳光
# ----------------------------------------------------------------------
extends Plant

const SUN_SCENE := preload("res://scenes/pickups/Sun.tscn")
const PRODUCE_INTERVAL := 8.0
const FIRST_DELAY := 5.0                       # 第一颗稍晚一些，给装下后一个缓冲

var _produce_timer: Timer

func _on_ready_setup() -> void:
	_produce_timer = Timer.new()
	_produce_timer.wait_time = FIRST_DELAY
	_produce_timer.one_shot = false
	_produce_timer.autostart = true
	add_child(_produce_timer)
	_produce_timer.timeout.connect(_produce_sun)

func _produce_sun() -> void:
	# 第一次后改为正常间隔
	_produce_timer.wait_time = PRODUCE_INTERVAL
	# 生成阳光，落在自己脚边
	var sun: Node2D = SUN_SCENE.instantiate()
	# 把阳光挂到 Game 节点下，避免随植物销毁
	var game := get_tree().get_first_node_in_group("game_root")
	if game:
		game.add_child(sun)
	else:
		get_parent().add_child(sun)
	sun.global_position = global_position + Vector2(0, -8)
	# 调用阳光自带的"小跳一下"
	if sun.has_method("ground_pop"):
		sun.ground_pop()
	# 弹一下表示在产
	var t := create_tween()
	t.tween_property(sprite, "scale", Vector2(1.15, 0.85), 0.08)
	t.tween_property(sprite, "scale", Vector2.ONE, 0.15)

# 肥料：5 秒内每 1 秒产 1 颗
func fertilize() -> void:
	if _boost_active:
		return
	_boost_active = true
	_apply_boost_visual(true)
	for i in 5:
		await get_tree().create_timer(1.0, false).timeout
		if not is_instance_valid(self):
			return
		_produce_sun()
	_boost_active = false
	_apply_boost_visual(false)
