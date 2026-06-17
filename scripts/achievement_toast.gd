# scripts/achievement_toast.gd
# ----------------------------------------------------------------------
# 成就解锁时屏幕右上角弹一个 toast
#   - 滑入 + 显示 2.5s + 滑出
#   - 一次可叠加多个（每个独立）
# ----------------------------------------------------------------------
extends Panel

@onready var icon_label: Label = $HBox/Icon
@onready var title_label: Label = $HBox/VBox/Title
@onready var desc_label: Label = $HBox/VBox/Desc

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	modulate.a = 0
	position.y = -60
	# 注意：必须在 add_child 后再用 anchor / offset 调整
	# 手动放右上角
	position = Vector2(PlantDB.SCREEN_W - size.x - 20, 20)
	# 如果 setup 之前调用过，pending_id 里可能存了数据
	if has_meta("pending_id"):
		var data: Dictionary = AchievementDB.ACHIEVEMENTS[get_meta("pending_id")]
		_apply_data(data)
	_play_animation()

func setup(id: String) -> void:
	# _ready 之前调用此函数设置内容
	var data: Dictionary = AchievementDB.ACHIEVEMENTS[id]
	if icon_label == null:
		# 还没 ready，缓存
		set_meta("pending_id", id)
		return
	_apply_data(data)

func _apply_data(data: Dictionary) -> void:
	icon_label.text = data.icon
	title_label.text = data.name
	desc_label.text = data.description

func _play_animation() -> void:
	# 滑入
	var t1 := create_tween()
	t1.set_parallel(true)
	t1.tween_property(self, "modulate:a", 1.0, 0.3)
	t1.tween_property(self, "position:y", 30, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	# 停 2.5s
	await get_tree().create_timer(2.5, false).timeout
	if not is_instance_valid(self):
		return
	# 滑出
	var t2 := create_tween()
	t2.set_parallel(true)
	t2.tween_property(self, "modulate:a", 0.0, 0.4)
	t2.tween_property(self, "position:y", -60, 0.4)
	t2.tween_callback(queue_free)
