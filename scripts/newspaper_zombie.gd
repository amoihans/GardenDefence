# scripts/newspaper_zombie.gd
# ----------------------------------------------------------------------
# 读报僵尸
#   - 自身血 100 + 报纸护盾 300 = 400 有效
#   - 伤害先扣护盾，护盾破 → 加速 + 视觉变
#
# 实现：shield_hp 单独维护，take_damage 重写分配。
# ----------------------------------------------------------------------
extends Zombie

@export var shield_hp: float = 300.0
@export var speed_after_shield: float = 32.0

var _shield: float = 0.0
var _shield_broken: bool = false

func _ready() -> void:
    _shield = shield_hp
    super._ready()

func take_damage(amount: float) -> void:
    if _shield > 0.0:
        # 优先扣盾
        var dmg_to_shield := min(_shield, amount)
        _shield -= dmg_to_shield
        amount -= dmg_to_shield
        if _shield <= 0.0 and not _shield_broken:
            _on_shield_broken()
    if amount > 0.0:
        super.take_damage(amount)

func _on_shield_broken() -> void:
    _shield_broken = true
    base_speed = speed_after_shield
    _update_speed()
    # 视觉：报纸消失 → 露出身体 → 红色愤怒
    sprite.modulate = Color(1.4, 0.7, 0.7)
    # 报纸飞走小动画
    var t := create_tween()
    t.tween_property(sprite, "rotation", deg_to_rad(-15), 0.15)
    t.tween_property(sprite, "rotation", deg_to_rad(0), 0.2)
    t.tween_callback(_swap_visual)

func _swap_visual() -> void:
    # 没有报纸的纹理资源，简化处理：把 modulate 变暗 + 摆烂
    sprite.modulate = Color(0.85, 0.95, 1.0)
