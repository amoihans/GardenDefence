# scripts/torchwood.gd
# ----------------------------------------------------------------------
# 火炬：放下去后，豌豆穿过它会变火球
#   - 伤害 ×2
#   - 改成红色 modulate
#   - 标记 pea.is_fireball = true → 飞行单位（气球）也能被打
#   - 同一条豌豆只 buff 一次（靠 pea.is_fireball 标志）
# ----------------------------------------------------------------------
extends Plant

const BUFF_RADIUS: float = 28.0        # 命中距离
const DAMAGE_MULT: float = 2.0         # 伤害倍率

var _fireballs_only: bool = false      # 调试用：true 时只放过火球（极少见）

func _physics_process(_delta: float) -> void:
    for node in get_tree().get_nodes_in_group("peas"):
        var p = node as Node
        if p == null: continue
        if "is_fireball" in p and p.is_fireball:
            continue                                # 已经 buff 过
        if abs(p.global_position.x - global_position.x) < BUFF_RADIUS \
                and abs(p.global_position.y - global_position.y) < BUFF_RADIUS:
            _buff_pea(p)

func _buff_pea(p: Node) -> void:
    p.is_fireball = true
    p.damage = p.damage * DAMAGE_MULT
    p.modulate = Color(1.4, 0.5, 0.2)                # 红橙色
    # 小小缩放一下模拟"燃烧"
    var t := p.create_tween()
    t.tween_property(p, "scale", Vector2(1.15, 1.15), 0.1)
    t.tween_property(p, "scale", Vector2(1.0, 1.0), 0.1)
    Sfx.play_shoot()                                  # 二次发射音效

# 火炬本身没有主动攻击 —— _on_ready_setup 不做任何事
func _on_ready_setup() -> void:
    pass
