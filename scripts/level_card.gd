# scripts/level_card.gd
# ----------------------------------------------------------------------
# 选关界面的一张关卡卡：标题 + 描述 + 波数 + "进入"按钮
# ----------------------------------------------------------------------
extends PanelContainer

signal start_requested(level_id: String)

@onready var title_label: Label = $Margin/HBox/Info/TitleLabel
@onready var desc_label: Label = $Margin/HBox/Info/DescLabel
@onready var meta_label: Label = $Margin/HBox/Info/MetaLabel
@onready var start_btn: Button = $Margin/HBox/StartBtn
@onready var index_label: Label = $Margin/HBox/IndexLabel

var _level_id: String = ""

func setup(index: int, level: Dictionary) -> void:
	_level_id = level.id
	index_label.text = "第 %d 关" % (index + 1)
	title_label.text = level.name
	desc_label.text = level.description
	var waves: Array = level.waves
	var completed: bool = GameState.completed_levels.get(_level_id, false)
	var meta_parts: Array = ["共 %d 波" % waves.size()]
	if completed:
		meta_parts.append("已通关")
	meta_label.text = "  ·  ".join(meta_parts)
	start_btn.pressed.connect(_on_start)
	var unlocked: bool = GameState.is_level_unlocked(index)
	if not unlocked:
		start_btn.disabled = true
		start_btn.text = "🔒 未解锁"
		# 整张卡灰显
		modulate = Color(0.6, 0.6, 0.6, 1)
	else:
		start_btn.text = "▶ 进入"

func _on_start() -> void:
	if _level_id != "":
		start_requested.emit(_level_id)
