# scripts/wallnut.gd
# ----------------------------------------------------------------------
# 坚果墙：纯肉盾，没有主动行为
# 但会根据 HP 比例切换贴图（满血→裂痕→碎裂前夕）
#
# 由于本项目只用 1 张贴图，这里仅做 modulate 调暗示意。
# 真要拓展可挂多张 sprite 切换。
# ----------------------------------------------------------------------
extends Plant

func _on_ready_setup() -> void:
    pass

func take_damage(amount: float) -> void:
    super.take_damage(amount)
    if sprite == null:
        return
    var ratio: float = float(current_hp) / float(max_hp)
    # 越破越暗
    var d = lerp(1.0, 0.55, 1.0 - clampf(ratio, 0.0, 1.0))
    sprite.modulate = Color(d, d, d)
