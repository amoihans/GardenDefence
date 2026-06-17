# scripts/code_book_item.gd
# ----------------------------------------------------------------------
# 图鉴里的一张卡：图标 + 名字 + 数值 + 能力描述
# 未发现时显示"?"和灰色遮罩
# ----------------------------------------------------------------------
extends PanelContainer

@onready var icon: TextureRect = $HBox/Icon
@onready var name_label: Label = $HBox/VBox/Name
@onready var stats_label: Label = $HBox/VBox/Stats
@onready var desc_label: Label = $HBox/VBox/Desc
@onready var status_label: Label = $HBox/Status

var _discovered: bool = false

func setup(kind: String, id: String, data: Dictionary, discovered: bool) -> void:
    _discovered = discovered
    if icon == null:
        # 还没 ready，缓存
        set_meta("kind", kind)
        set_meta("id", id)
        set_meta("data", data)
        set_meta("discovered", discovered)
        return
    _apply(kind, id, data, discovered)

func _ready() -> void:
    if has_meta("data"):
        _apply(get_meta("kind"), get_meta("id"), get_meta("data"), get_meta("discovered"))

func _apply(kind: String, id: String, data: Dictionary, discovered: bool) -> void:
    if discovered:
        # 显示图标（plant 和 zombie 都在 data.icon_path 里）
        var path: String = data.get("icon_path", "")
        if ResourceLoader.exists(path):
            icon.texture = load(path)
        # 状态：已发现
        status_label.text = "✓"
        status_label.modulate = Color(0.4, 1.0, 0.4, 1)
        # 名字 + 数值 + 描述
        name_label.text = data.display_name
        stats_label.text = _format_stats(kind, data)
        desc_label.text = data.get("description", "")
        name_label.modulate = Color.WHITE
        stats_label.modulate = Color(0.85, 0.85, 0.85, 1)
        desc_label.modulate = Color(0.95, 0.85, 0.55, 1)
        modulate = Color.WHITE
    else:
        # 锁住
        icon.texture = null
        name_label.text = "???"
        stats_label.text = "尚未发现"
        desc_label.text = "在游戏中使用或遇到即可解锁"
        status_label.text = "🔒"
        status_label.modulate = Color(0.5, 0.5, 0.5, 0.6)
        name_label.modulate = Color(0.6, 0.6, 0.6, 1)
        stats_label.modulate = Color(0.4, 0.4, 0.4, 1)
        desc_label.modulate = Color(0.45, 0.45, 0.45, 1)
        modulate = Color(0.6, 0.6, 0.6, 1)

func _format_stats(kind: String, data: Dictionary) -> String:
    if kind == "plant":
        return "☀ %d  ·  ❤ %d  ·  ⏱ %.1fs" % [data.cost, data.max_hp, data.cooldown]
    else:
        return "❤ %.0f  ·  速 %.0f  ·  ⚔ %.0f/s" % [data.max_hp, data.speed, data.damage_per_sec]
