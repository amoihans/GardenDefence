# scripts/achievement_item.gd
# ----------------------------------------------------------------------
# 一条成就行：图标 + 名称 + 描述 + 解锁状态
# ----------------------------------------------------------------------
extends PanelContainer

@onready var icon_label: Label = $HBox/Icon
@onready var title_label: Label = $HBox/VBox/Title
@onready var desc_label: Label = $HBox/VBox/Desc
@onready var status_label: Label = $HBox/Status

func setup(id: String, data: Dictionary, unlocked: bool) -> void:
	# 在 _ready 后才生效
	if icon_label != null:
		_apply(data, unlocked)
	else:
		# 还没 ready，缓存
		set_meta("data", data)
		set_meta("unlocked", unlocked)

func _ready() -> void:
	if has_meta("data"):
		var data: Dictionary = get_meta("data")
		var unlocked: bool = get_meta("unlocked")
		_apply(data, unlocked)

func _apply(data: Dictionary, unlocked: bool) -> void:
	icon_label.text = data.icon
	title_label.text = data.name
	desc_label.text = data.description
	if unlocked:
		status_label.text = "✓ 已解锁"
		status_label.modulate = Color(0.4, 1.0, 0.4, 1)
		icon_label.modulate = Color.WHITE
	else:
		status_label.text = "🔒 未解锁"
		status_label.modulate = Color(0.5, 0.5, 0.5, 0.8)
		icon_label.modulate = Color(0.4, 0.4, 0.4, 1)
