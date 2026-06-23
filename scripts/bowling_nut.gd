# scripts/bowling_nut.gd
# ----------------------------------------------------------------------
# 坚果保龄（新版弹珠台）：
#   - 放在 col=0 后进入"待发"状态：在发射格内上下弹跳
#   - 按住 Space 或点击草坪 → 发射：向右 + 当前弹跳方向
#   - 在草坪范围内左右弹跳，上下碰到边界也弹
#   - 撞到僵尸：僵尸立即死亡（+25阳光），坚果垂直方向反弹
# ----------------------------------------------------------------------
extends Node2D

const NUT_TEXTURE := preload("res://assets/plants/wallnut.svg")

# 弹跳速度
const BOUNCE_SPEED := 380.0
# 发射后水平速度
const LAUNCH_SPEED_X := 480.0
# 坚果半径（碰撞用）
const NUT_RADIUS := 20.0
# 坚果碰撞盒半径
const HIT_RADIUS := 36.0
# 旋转速度（弧度/秒）
const SPIN_SPEED := 3.0

# 状态：ready=上下弹跳待发, flying=已发射弹跳中, consumed=已销毁
enum State { READY, FLYING, CONSUMED }
var _state: State = State.READY

var _vel: Vector2 = Vector2.ZERO
var _sprite: Sprite2D
var _consumed: bool = false

# 弹跳边界（由 launch_zone 决定）
var _bounce_left: float
var _bounce_right: float
var _bounce_top: float
var _bounce_bottom: float
# READY 状态的左右边界固定在 col=0 格子
var _ready_left: float
var _ready_right: float

# 发射区格子位置（待发弹跳的中心）
var _cell_col: int = 0
var _cell_row: int = 0
var _cell_center: Vector2

# 坚果旋转角度（视觉）
var _rotation_angle: float = 0.0

func _ready() -> void:
	z_index = 10
	_sprite = Sprite2D.new()
	_sprite.texture = NUT_TEXTURE
	_sprite.centered = true
	add_child(_sprite)

# 由 wave_manager 调用：初始化弹跳区域并开始待发弹跳
func configure(bounce_rect: Rect2, col: int, row: int) -> void:
	_cell_col = col
	_cell_row = row
	# 整片草坪边界（发射后用）
	_bounce_left   = bounce_rect.position.x
	_bounce_right  = bounce_rect.position.x + bounce_rect.size.x
	_bounce_top    = bounce_rect.position.y
	_bounce_bottom = bounce_rect.position.y + bounce_rect.size.y
	# READY 状态固定在 col=0 格子
	_ready_left  = PlantDB.LAWN_ORIGIN_X + NUT_RADIUS
	_ready_right = PlantDB.LAWN_ORIGIN_X + PlantDB.CELL_SIZE - NUT_RADIUS
	_cell_center = Vector2(
		PlantDB.LAWN_ORIGIN_X + col * PlantDB.CELL_SIZE + PlantDB.CELL_SIZE / 2.0,
		PlantDB.LAWN_ORIGIN_Y + row * PlantDB.CELL_SIZE + PlantDB.CELL_SIZE / 2.0)
	global_position = _cell_center
	_state = State.READY
	_vel = Vector2(0, -BOUNCE_SPEED)              # 一开始往上弹
	_start_bounce()

# 开始上下弹跳（待发状态）
func _start_bounce() -> void:
	_vel.y = -BOUNCE_SPEED if _vel.y == 0 else _vel.y

func _physics_process(delta: float) -> void:
	if _state == State.CONSUMED:
		return

	# 移动
	global_position += _vel * delta
	_rotation_angle += SPIN_SPEED * delta
	if _sprite:
		_sprite.rotation = _rotation_angle

	if _state == State.READY:
		# 只在 col=0 格子弹跳，上下碰到边界就反弹
		var top_limit := _bounce_top + NUT_RADIUS
		var bot_limit := _bounce_bottom - NUT_RADIUS
		if global_position.y <= top_limit:
			global_position.y = top_limit
			_vel.y = BOUNCE_SPEED
		elif global_position.y >= bot_limit:
			global_position.y = bot_limit
			_vel.y = -BOUNCE_SPEED
		# 水平方向也约束在 col=0 格内
		if global_position.x <= _ready_left:
			global_position.x = _ready_left
		elif global_position.x >= _ready_right:
			global_position.x = _ready_right

	elif _state == State.FLYING:
		# 左边界反弹
		if global_position.x <= _bounce_left + NUT_RADIUS:
			global_position.x = _bounce_left + NUT_RADIUS
			_vel.x = BOUNCE_SPEED
		# 右边界不拦，飞出屏幕右侧即销毁
		if global_position.x > PlantDB.SCREEN_W + 100:
			_consumed = true
			queue_free()
			return
		# 碰到上下边界
		if global_position.y <= _bounce_top + NUT_RADIUS:
			global_position.y = _bounce_top + NUT_RADIUS
			_vel.y = BOUNCE_SPEED
		elif global_position.y >= _bounce_bottom - NUT_RADIUS:
			global_position.y = _bounce_bottom - NUT_RADIUS
			_vel.y = -BOUNCE_SPEED

	# 撞僵尸检测
	_check_zombie_hit()

# Space / 点击触发：发射
func launch() -> void:
	print("[BowlingNut] launch called, state=", _state, " pos=", global_position)
	if _state != State.READY:
		print("[BowlingNut] launch rejected - not READY")
		return
	_state = State.FLYING
	# 保持当前弹跳方向（_vel.y），但确保不会朝向边界发射后立刻碰壁
	if _vel.y > 0 and global_position.y > _bounce_bottom - NUT_RADIUS * 3:
		_vel.y = -abs(_vel.y)
	elif _vel.y < 0 and global_position.y < _bounce_top + NUT_RADIUS * 3:
		_vel.y = abs(_vel.y)
	_vel.x = LAUNCH_SPEED_X
	print("[BowlingNut] now FLYING, vel=", _vel)

# 点击草坪也可以发射（如果有待发坚果）
func try_launch_from_click(click_pos: Vector2) -> bool:
	if _state != State.READY:
		return false
	# 点击位置在发射格上半部分 → 向上发射；下半部分 → 向下发射
	if click_pos.y < global_position.y:
		_vel.y = -abs(_vel.y)
	else:
		_vel.y = abs(_vel.y)
	launch()
	return true

func _check_zombie_hit() -> void:
	for node in get_tree().get_nodes_in_group("zombies"):
		var z = node as Node
		if z == null: continue
		var dist := global_position.distance_to(z.global_position)
		if dist < HIT_RADIUS:
			_on_hit_zombie(z)
			return

func _on_hit_zombie(z: Node) -> void:
	# 僵尸立即死亡
	if z.has_method("take_damage"):
		z.take_damage(9999.0)
	# +25 阳光
	GameState.sun_amount += 25
	Sfx.play_shoot()
	# 坚果垂直反弹（不销毁，继续弹）
	_vel.y = -_vel.y
