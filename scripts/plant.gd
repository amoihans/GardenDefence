# scripts/plant.gd
# ----------------------------------------------------------------------
# 植物基类（抽象基类）
#
# 所有植物的共性：
#   - 有血量，能掉血、能死
#   - 知道自己在哪一行（lane / row），便于查找同行僵尸
#   - 死亡时通知自己所在的格子，让格子释放占用
#
# 子类需要做的：
#   - 在 _ready 里实现自己的攻击逻辑（计时器、子弹、阳光等）
#   - 重写 plant_id 静态信息（或通过场景把 id 设进来）
# ----------------------------------------------------------------------
extends Node2D
class_name Plant

signal died(plant: Plant)

@export var plant_id: String = ""              # 在场景里手动填
@export var max_hp: int = 60
@export var contact_damage_immune: bool = false

# current_hp 用 float 累计：僵尸每帧伤害可能是 0.5，必须能逐渐叠加
var current_hp: float = 0.0
var row: int = -1                              # 由 Lawn 在种下时赋值
var col: int = -1

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
    current_hp = max_hp
    add_to_group("plants")
    # 子类自己的逻辑放到 _on_ready_setup 里
    _on_ready_setup()

# 子类可重写：在 _ready 末尾被调用，做自己的初始化
func _on_ready_setup() -> void:
    pass

# 受到伤害；子类一般不重写
func take_damage(amount: float) -> void:
    if contact_damage_immune:
        return
    current_hp -= amount
    # 受击红闪
    _flash_damage()
    if current_hp <= 0:
        die()

func _flash_damage() -> void:
    if sprite == null:
        return
    sprite.modulate = Color(1.5, 0.6, 0.6)
    var t := create_tween()
    t.tween_property(sprite, "modulate", Color.WHITE, 0.15)

func die() -> void:
    died.emit(self)
    queue_free()
