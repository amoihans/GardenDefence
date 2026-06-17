# scripts/lawn_mower.gd
# ----------------------------------------------------------------------
# 除草机（Lawn Mower）—— PvZ 最后一道防线
#
# 默认状态：每行最左侧停放，灰白颜色，表示"未启动"。
# 触发条件：该行有僵尸越过草坪左边界（行 0 第一格 = LAWN_ORIGIN_X - 32）。
# 触发后：向右匀速移动，扫除沿途所有僵尸。
# 死亡：离开屏幕右边界后 queue_free。
# 兜底：若除草机出屏幕时该行仍有僵尸进家，按 _on_exit 信号交给 Game 判负。
# ----------------------------------------------------------------------
extends Node2D

signal triggered                            # 被僵尸"挤"过去时
signal exited_screen                        # 出屏幕右边
signal consumed                             # 已经用过（防止同一次越界触发两次）

# 移动参数
const MOVE_SPEED: float = 320.0             # 像素/秒
# 除草机与僵尸的接触半径（用 x 距离近似）
const HIT_RANGE: float = 30.0

# 屏幕右边界（> 草坪最右 + 余量）
const EXIT_X: float = 1280.0

var row: int = 0
var _triggered: bool = false
var _used: bool = false

@onready var body: ColorRect = $Body
@onready var label: Label = $Body/Label

func setup(r: int) -> void:
	row = r

func _ready() -> void:
	add_to_group("lawn_mowers")
	# 视觉默认灰白
	_apply_visual(false)

# 外部调用：通知该行有僵尸越界 → 启动
func trigger() -> void:
	if _used:
		return
	_used = true
	_triggered = true
	_apply_visual(true)
	triggered.emit()

func _process(delta: float) -> void:
	if not _triggered:
		return
	# 向右移动
	position.x += MOVE_SPEED * delta
	# 扫除同行僵尸
	_kill_zombies_in_row()
	# 出屏幕
	if position.x > EXIT_X:
		exited_screen.emit()
		queue_free()

func _kill_zombies_in_row() -> void:
	for node in get_tree().get_nodes_in_group("zombies"):
		var z := node as Node2D
		if z == null:
			continue
		# 同行：通过 global_position.y 与自身比较；用整型 row 字段更稳
		if "row" in z and z.row != row:
			continue
		if abs(z.global_position.x - global_position.x) <= HIT_RANGE:
			if z.has_method("die"):
				z.die()

func _apply_visual(active: bool) -> void:
	if active:
		body.color = Color(1.0, 0.5, 0.2)         # 橙红：已启动
		label.text = "M!"
	else:
		body.color = Color(0.85, 0.85, 0.85)      # 灰白：未启动
		label.text = "M"
