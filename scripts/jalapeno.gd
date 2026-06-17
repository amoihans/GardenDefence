# scripts/jalapeno.gd
# ----------------------------------------------------------------------
# 辣椒：种下 0.5s 后引爆，清除整行所有僵尸（1800 伤害），自身销毁
# 视觉：火柱从下到上烧起来
# ----------------------------------------------------------------------
extends Plant

const FUSE_TIME := 0.5
const EXPLOSION_DAMAGE := 1800.0

var _fuse_tween: Tween

func _on_ready_setup() -> void:
	contact_damage_immune = true
	# 振动 + 加速发热
	_fuse_tween = create_tween()
	_fuse_tween.set_loops(int(FUSE_TIME / 0.08))
	_fuse_tween.tween_property(sprite, "scale", Vector2(1.15, 0.85), 0.04)
	_fuse_tween.tween_property(sprite, "scale", Vector2(1.0, 1.0), 0.04)
	await get_tree().create_timer(FUSE_TIME, false).timeout
	if is_instance_valid(self):
		_explode()

# 施肥立刻引爆
func fertilize() -> void:
	if not is_instance_valid(self):
		return
	if _fuse_tween != null and _fuse_tween.is_valid():
		_fuse_tween.kill()
	_explode()

func _explode() -> void:
	# 火柱：3 个 ColorRect 堆叠，逐个从下往上
	for i in 3:
		var flame := ColorRect.new()
		flame.color = [Color(1.0, 0.3, 0.0, 0.95), Color(1.0, 0.6, 0.0, 0.9), Color(1.0, 0.9, 0.0, 0.8)][i]
		flame.size = Vector2(PlantDB.SCREEN_W, PlantDB.SCREEN_H / PlantDB.GRID_ROWS)
		flame.position.x = 0
		flame.position.y = PlantDB.row_to_y(row) - flame.size.y / 2
		flame.z_index = 90
		var game := get_tree().get_first_node_in_group("game_root")
		if game:
			game.add_child(flame)
		else:
			get_parent().add_child(flame)
		var t := flame.create_tween()
		t.tween_property(flame, "scale:y", Vector2(1, 0.2), 0.0)			 # 先压扁
		t.parallel().tween_property(flame, "scale:y", Vector2(1, 1.1), 0.2)	# 涨高
		t.parallel().tween_property(flame, "modulate:a", 0.0, 0.4)
		t.tween_callback(flame.queue_free)
		await get_tree().create_timer(0.05, false).timeout

	# 清场：整行所有僵尸
	for node in get_tree().get_nodes_in_group("zombies"):
		var z := node as Zombie
		if z == null: continue
		if z.row == row:
			z.take_damage(EXPLOSION_DAMAGE)
	Sfx.play_explosion()
	queue_free()
