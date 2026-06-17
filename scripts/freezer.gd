# scripts/freezer.gd
# ----------------------------------------------------------------------
# 寒冰射手：发射冰豆。命中目标造成伤害 + 减速 50% 持续 2 秒。
# 直接复用 peashooter.gd 的开火逻辑，只换子弹场景。
# ----------------------------------------------------------------------
extends "res://scripts/peashooter.gd"

const ICE_PEA_SCENE := preload("res://scenes/projectiles/IcePea.tscn")

func _on_ready_setup() -> void:
	# 构造一个临时覆盖：换掉 PEA_SCENE
	# peashooter.gd 里写死了 const PEA_SCENE，我们通过 _shoot_pea 多态来替换
	_fire_timer = Timer.new()
	_fire_timer.wait_time = fire_interval
	_fire_timer.one_shot = false
	_fire_timer.autostart = true
	add_child(_fire_timer)
	_fire_timer.timeout.connect(_try_fire)

# 覆盖父类的 _shoot_pea：换子弹场景
# 注意：必须保留 row_offset 参数与父类签名一致
func _shoot_pea(row_offset: int = 0) -> void:
	var pea: Node2D = ICE_PEA_SCENE.instantiate()
	var game := get_tree().get_first_node_in_group("game_root")
	if game:
		game.add_child(pea)
	else:
		get_parent().add_child(pea)
	pea.global_position = global_position + Vector2(20, -10)
	if pea.has_method("setup"):
		pea.setup(row + row_offset, pea_damage)
	Sfx.play_shoot_ice()
	var t := create_tween()
	t.tween_property(sprite, "position", Vector2(-3, 0), 0.05)
	t.tween_property(sprite, "position", Vector2.ZERO, 0.1)
