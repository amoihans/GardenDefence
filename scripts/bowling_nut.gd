# scripts/bowling_nut.gd
# ----------------------------------------------------------------------
# 坚果保龄：横向滚动的坚果
#   - 玩家按 Space 发射一个坚果，沿正右方向高速滚动
#   - 撞到同行僵尸：扣血 + 把僵尸往右推
#   - 出屏幕 → 自毁
#   - 用纯 Node2D + ColorRect 画一个棕色球（避免 .svg 导入）
# ----------------------------------------------------------------------
extends Node2D

const SPEED: float = 700.0
const HIT_DAMAGE: float = 800.0
const KNOCKBACK: float = 80.0

var row: int = 0
var is_ready: bool = true                # true = 待命（不动），false = 已发射
var _consumed: bool = false
var _body: ColorRect
var _ready_tween: Tween                   # 待命浮动 tween（发射时要 kill）

func _ready() -> void:
    z_index = 10                            # 显在 lawn 背景之上
    _body = ColorRect.new()
    _body.color = Color(0.85, 0.55, 0.25)  # 鲜亮橙棕（在浅绿草坪上明显）
    _body.size = Vector2(40, 40)
    _body.position = Vector2(-20, -20)
    add_child(_body)
    # 黑色边框让坚果边缘更清楚
    var border := ColorRect.new()
    border.color = Color(0, 0, 0)
    border.size = Vector2(40, 40)
    border.position = Vector2(-20, -20)
    add_child(border)
    _body = ColorRect.new()                 # 重建在 border 上面
    _body.color = Color(0.85, 0.55, 0.25)
    _body.size = Vector2(36, 36)
    _body.position = Vector2(-18, -18)
    add_child(_body)
    # 待命时上下浮动（视觉提示"可发射"）
    if is_ready:
        _ready_tween = create_tween().set_loops()
        _ready_tween.tween_property(_body, "position:y", -25.0, 0.4)
        _ready_tween.tween_property(_body, "position:y", -15.0, 0.4)

func _physics_process(_delta: float) -> void:
    if is_ready or _consumed:
        return
    position.x += SPEED * _delta
    # 出屏幕
    if position.x > PlantDB.SCREEN_W + 64:
        queue_free()
        return
    # 撞僵尸
    for node in get_tree().get_nodes_in_group("zombies"):
        var z = node as Node
        if z == null: continue
        if "row" in z and z.row != row: continue
        if abs(z.global_position.x - global_position.x) < 48 \
                and abs(z.global_position.y - global_position.y) < 48:
            _hit_zombie(z)
            return

# Space 触发：把待命坚果设为"已发射"状态
func fire() -> void:
    if not is_ready or _consumed:
        return
    is_ready = false
    if _ready_tween != null and _ready_tween.is_valid():
        _ready_tween.kill()
    # 视觉换色 + 旋转动画
    if _body != null:
        _body.color = Color(0.85, 0.6, 0.3)
        _body.position = Vector2(-20, -20)
        var t := create_tween().set_loops()
        t.tween_property(_body, "rotation", TAU, 0.2)

func _hit_zombie(z: Node) -> void:
    if _consumed: return
    _consumed = true
    if z.has_method("take_damage"):
        z.take_damage(HIT_DAMAGE)
    if "global_position" in z:
        z.global_position.x += KNOCKBACK
    Sfx.play_shoot()
    queue_free()
