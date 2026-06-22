# scripts/miner_zombie.gd
# ----------------------------------------------------------------------
# 矿工僵尸：从中段（col=4）地下冒出来
#   - 出生时 y 偏下（地下）→ 0.3s tween 回正常 y
#   - 其他行为完全用父类
# ----------------------------------------------------------------------
extends Zombie

const SPAWN_COL: int = 4                  # 中段：col 4（约屏幕中央）
const RISE_DURATION: float = 0.4

func _ready() -> void:
    super._ready()
    # 重新定位：col=4 中段
    var spawn_x: float = PlantDB.LAWN_ORIGIN_X + SPAWN_COL * PlantDB.CELL_SIZE + PlantDB.CELL_SIZE / 2.0
    var target_y: float = PlantDB.row_to_y(row)
    # 一开始 y 偏下 50 像素（地下）
    global_position = Vector2(spawn_x, target_y + 50)
    # 弹起到正常 y
    var t := create_tween()
    t.tween_property(self, "position:y", target_y, RISE_DURATION) \
        .set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    # 落点土块效果（棕色颗粒）
    _spawn_dust()
    Sfx.play_zombie_die()  # 复用 zombie 出现音（不算死；音效库没有"出土"）

func _spawn_dust() -> void:
    # 8 颗棕色粒子从脚下溅起
    for i in 8:
        var dust := ColorRect.new()
        dust.color = Color(0.6, 0.5, 0.3, 0.8)
        dust.size = Vector2(5, 5)
        var game := get_tree().get_first_node_in_group("game_root")
        if game:
            game.add_child(dust)
        else:
            get_parent().add_child(dust)
        dust.global_position = global_position + Vector2(randf_range(-20, 20), 0)
        var t := dust.create_tween()
        var dx := randf_range(-30, 30)
        t.parallel().tween_property(dust, "position", dust.position + Vector2(dx, -25), 0.4)
        t.parallel().tween_property(dust, "modulate:a", 0.0, 0.4)
        t.tween_callback(dust.queue_free)
