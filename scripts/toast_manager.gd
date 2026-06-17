# scripts/toast_manager.gd
# ----------------------------------------------------------------------
# 全局成就 toast 调度器
#   - 监听 AchievementDB.achievement_unlocked
#   - 每次解锁在屏幕右上角弹一个 toast
# ----------------------------------------------------------------------
extends CanvasLayer

const AchievementToastScene := preload("res://scenes/ui/AchievementToast.tscn")

var _queue: Array = []
var _displaying: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 8
	AchievementDB.achievement_unlocked.connect(_on_unlocked)

func _on_unlocked(id: String) -> void:
	_queue.append(id)
	_tick_queue()

func _tick_queue() -> void:
	if _displaying or _queue.is_empty():
		return
	_displaying = true
	var id: String = _queue.pop_front()
	var toast := AchievementToastScene.instantiate()
	add_child(toast)
	toast.setup(id)
	# 等它播放完（大约 3.5s：滑入 0.4 + 停留 2.5 + 滑出 0.4 + 余量）
	await get_tree().create_timer(3.5, false).timeout
	_displaying = false
	_tick_queue()
