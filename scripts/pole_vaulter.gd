# scripts/pole_vaulter.gd
# ----------------------------------------------------------------------
# 撑杆僵尸：
#   - 第一次遇到植物时撑杆跳过
#   - 跳到该植物后一格，落地后继续正常走 / 啃
#   - 撑杆用过了（_has_jumped = true），后续遇到植物不会跳
# ----------------------------------------------------------------------
extends Zombie

const JUMP_DURATION := 0.45

var _has_jumped: bool = false
var _jumping: bool = false
var _jump_target: Plant = null

# 覆写 _physics_process：跳的时候不走"行内"逻辑
func _physics_process(delta: float) -> void:
    if GameState.is_game_over:
        return
    if _jumping:
        return                                                # 跳的动画由 _start_jump 接管
    # 减速倒计时（继承自父类）
    if slow_timer > 0.0:
        slow_timer -= delta
        if slow_timer <= 0.0:
            slow_factor = 1.0
            _update_speed()
    # 没跳过且面前有植物 → 撑杆跳
    if not _has_jumped:
        var target := _find_plant_to_eat()
        if target != null:
            _start_jump(target)
            return
    # 正常移动 / 啃
    var target := _find_plant_to_eat()
    if target != null:
        _attacking_target = target
        _eat(target, delta)
    else:
        _attacking_target = null
        global_position.x -= current_speed * delta
        if global_position.x < PlantDB.LAWN_ORIGIN_X - 32:
            GameState.declare_loss()
            queue_free()

func _start_jump(plant: Plant) -> void:
    _jumping = true
    _jump_target = plant
    # 跳过的目标 = 该植物的左侧一格（靠近家的方向）
    var target_x: float = global_position.x - 96.0
    var target_y: float = global_position.y
    # 视觉曲线：先向上再向下
    var start_pos := global_position
    var peak_pos := start_pos + Vector2(48, -80)
    var end_pos := Vector2(target_x, target_y)
    var t := create_tween()
    t.tween_property(self, "global_position", peak_pos, JUMP_DURATION * 0.5)\
        .set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
    t.tween_property(self, "global_position", end_pos, JUMP_DURATION * 0.5)\
        .set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
    t.tween_callback(_on_jump_finished)

func _on_jump_finished() -> void:
    _jumping = false
    _has_jumped = true
    _jump_target = null
