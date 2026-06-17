# scripts/imp_zombie.gd
# ----------------------------------------------------------------------
# 小鬼僵尸：高速 + 自爆
#   - 速度比普通快 1.5 倍
#   - 接触植物时立即自爆，对该植物造成 1200 伤害
#   - 自爆后自己消失
# ----------------------------------------------------------------------
extends Zombie

const IMP_EXPLOSION_DAMAGE := 1200.0

func _ready() -> void:
	contact_damage_immune = true           # 啃不动 = 直接撞就爆
	super._ready()

# 覆写：碰到植物时除了吃，还立刻自爆
func _eat(target: Plant, delta: float) -> void:
	target.take_damage(IMP_EXPLOSION_DAMAGE)
	_explode()

func _explode() -> void:
	# 视觉：小范围爆炸
	var ring := ColorRect.new()
	ring.color = Color(1.0, 0.4, 0.0, 0.9)
	var r := 60.0
	ring.size = Vector2(r * 2, r * 2)
	ring.pivot_offset = ring.size * 0.5
	ring.position = global_position - ring.size * 0.5
	ring.z_index = 80
	var game := get_tree().get_first_node_in_group("game_root")
	if game:
		game.add_child(ring)
	else:
		get_parent().add_child(ring)
	var t := ring.create_tween()
	t.parallel().tween_property(ring, "scale", Vector2(1.5, 1.5), 0.3)
	t.parallel().tween_property(ring, "modulate:a", 0.0, 0.3)
	t.tween_callback(ring.queue_free)
	Sfx.play_explosion()
	die()
