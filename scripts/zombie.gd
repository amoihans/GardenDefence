# scripts/zombie.gd
# ----------------------------------------------------------------------
# 僵尸基类
#
# 行为：
#   1. 默认向左移动（行 row 固定，y 坐标不变）。
#   2. 每帧检查同行 col 是否有植物。
#   3. 若植物的 x 落入啃咬范围，停止前进、对植物 DPS 伤害。
#   4. 植物死后继续前进。
#   5. 越过左边界 → 通知失败。
#
# 扩展点：
#   - 子类可以重写 _find_plant_to_eat（撑杆跳）
#   - 子类可以重写 _on_plant_killed（报纸打破后加速）
#   - 外部可调用 apply_slow（冰豆效果）
# ----------------------------------------------------------------------
extends Node2D
class_name Zombie

const Particles := preload("res://scripts/particles.gd")

signal died(zombie)

@export var max_hp: float = 100.0
@export var base_speed: float = 20.0              # 基础速度（被减速/报纸打破时变更高）
@export var damage_per_sec: float = 30.0
@export var attack_range: float = 56.0

# 当前生效速度 = base_speed * (1 - slow_remain / slow_max) 简化版本：
#   slow_factor  1.0 = 不减速；0.5 = 50% 速
var current_speed: float = 0.0
var slow_factor: float = 1.0
var slow_timer: float = 0.0

var current_hp: float = 100.0
var row: int = 0
var _attacking_target: Node = null

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	add_to_group("zombies")
	current_hp = max_hp
	current_speed = base_speed
	# 入场偏移：给一个"上身晃动"的小走路动画
	var t := create_tween()
	t.set_loops()
	t.tween_property(sprite, "rotation", deg_to_rad(3), 0.4)
	t.tween_property(sprite, "rotation", deg_to_rad(-3), 0.4)

func _physics_process(delta: float) -> void:
	if GameState.is_game_over:
		return
	# 减速倒计时
	if slow_timer > 0.0:
		slow_timer -= delta
		if slow_timer <= 0.0:
			slow_factor = 1.0
			_update_speed()

	# 找到当前应当啃咬的最右植物
	var target := _find_plant_to_eat()
	if target != null:
		_attacking_target = target
		_eat(target, delta)
	else:
		_attacking_target = null
		global_position.x -= current_speed * delta
		# 越界：先触发该行除草机
		# 除草机只能挡一次：触发后该行僵尸应该被清掉；
		# 如果除草机已经用过（_used=true），再越界就判负。
		if global_position.x < PlantDB.LAWN_ORIGIN_X - 32:
			var mowers := get_tree().get_nodes_in_group("lawn_mowers")
			var saved: bool = false
			for m_node in mowers:
				var m = m_node as Node
				if m == null: continue
				if "row" in m and m.row == row and not m._used:
					m.trigger()
					saved = true
					break
			if not saved:
				GameState.declare_loss()
			queue_free()

# 找到同行、x 紧邻自己左边的植物
func _find_plant_to_eat() -> Node:
	var best: Node = null
	var best_x: float = -INF
	for node in get_tree().get_nodes_in_group("plants"):
		var p := node as Plant
		if p == null: continue
		if p.row != row: continue
		var dx: float = global_position.x - p.global_position.x
		if dx >= -8 and dx <= attack_range:
			if p.global_position.x > best_x:
				best = p
				best_x = p.global_position.x
	return best

func _eat(target: Node, delta: float) -> void:
	target.take_damage(damage_per_sec * delta)
	var phase := sin(Time.get_ticks_msec() * 0.02) * 1.5
	sprite.position.y = phase

func take_damage(amount: float) -> void:
	current_hp -= amount
	sprite.modulate = Color(1.5, 0.7, 0.7)
	var t := create_tween()
	t.tween_property(sprite, "modulate", Color.WHITE, 0.1)
	if current_hp <= 0:
		die()

# 减速：factor<1 时把速度乘以 factor；冰豆命中时调用
func apply_slow(factor: float, duration: float) -> void:
	# 取最深的减速；刷新时长
	if factor < slow_factor:
		slow_factor = factor
	slow_timer = max(slow_timer, duration)
	_update_speed()
	# 视觉提示：变成淡蓝色
	sprite.modulate = Color(0.7, 0.85, 1.4)

func _update_speed() -> void:
	current_speed = base_speed * slow_factor

func die() -> void:
	died.emit(self)
	Sfx.play_zombie_die()
	# 死亡粒子：紫色碎屑（普通僵尸）/ 灰色（护盾类由子类改）
	Particles.burst(self, global_position, 12, Color(0.5, 0.2, 0.6, 1.0), 90.0, 0.7, 180.0)
	var t := create_tween()
	t.parallel().tween_property(sprite, "rotation", deg_to_rad(-90), 0.4)
	t.parallel().tween_property(self, "modulate:a", 0.0, 0.4)
	t.tween_callback(queue_free)
