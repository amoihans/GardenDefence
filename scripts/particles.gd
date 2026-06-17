# scripts/particles.gd
# ----------------------------------------------------------------------
# 通用粒子爆发系统
#
# 用法：
#   Particles.burst(parent, pos, count, color, speed, life, gravity)
#   Particles.burst(parent, pos, count, color, speed, life, gravity, size_min, size_max)
#
# parent: 通常传 Game（用 game_root group 找到）
# 粒子是小 ColorRect，自动消失
# ----------------------------------------------------------------------
extends Node

# 颜色 + 速度 + 生命 + 大小 默认值，可在 burst 调用时覆盖
const DEFAULT_SIZE := 4.0

static func burst(parent: Node, at: Vector2, count: int, color: Color,
		speed: float = 80.0, life: float = 0.8, gravity: float = 200.0,
		size_min: float = 3.0, size_max: float = 6.0,
		spread_deg: float = 360.0) -> void:
	var host: Node = _resolve_host(parent)
	if host == null:
		return
	for i in count:
		var p := _spawn_particle(host, at, color, speed, life, gravity, size_min, size_max, spread_deg)

# 飘叶子（轻、受重力小、左右飘）
static func leaves(parent: Node, at: Vector2, color: Color = Color(0.4, 0.8, 0.3)) -> void:
	var host: Node = _resolve_host(parent)
	if host == null:
		return
	for i in 8:
		var p := _spawn_particle(host, at, color, 50.0, 1.2, 60.0, 3.0, 5.0, 360.0)
		# 叶子比粒子更小、更随机
		if p != null:
			p.rotation = randf() * TAU
			p.scale *= Vector2(1.0, 0.6)

# 火星（小、快、亮）
static func sparks(parent: Node, at: Vector2, color: Color = Color(1.0, 0.7, 0.0)) -> void:
	var host: Node = _resolve_host(parent)
	if host == null:
		return
	for i in 14:
		_spawn_particle(host, at, color, 160.0, 0.45, 180.0, 2.0, 4.0, 360.0)

# 内部：找一个 host（优先用 game_root，否则用传入的 parent）
static func _resolve_host(parent: Node) -> Node:
	if parent == null:
		return null
	# 优先挂到 game_root（确保在 Game 节点下，与其它物体同 z_index 空间）
	var root := parent.get_tree().get_first_node_in_group("game_root")
	if root != null:
		return root
	return parent

# 内部：生成一个粒子
static func _spawn_particle(host: Node, at: Vector2, color: Color,
		speed: float, life: float, gravity: float,
		size_min: float, size_max: float, spread_deg: float) -> Node2D:
	var size := randf_range(size_min, size_max)
	var p := ColorRect.new()
	p.color = color
	p.size = Vector2(size, size)
	p.pivot_offset = Vector2(size / 2, size / 2)
	p.position = at - Vector2(size / 2, size / 2)
	p.z_index = 50
	host.add_child(p)

	# 初速度：均匀角度
	var ang := deg_to_rad(randf_range(0, spread_deg) - spread_deg * 0.5 - 90.0)
	var vel := Vector2(cos(ang), sin(ang)) * speed * randf_range(0.5, 1.2)

	# 用 _process 模拟物理（比 Tween 简单，能做重力 + 渐隐 + 缩放）
	_particle_process(p, at, vel, life, gravity, size)
	return p

# 用 Timer 异步推进（不在 _process 里跑循环，零开销）
static func _particle_process(p: Node2D, origin: Vector2, vel: Vector2, life: float, gravity: float, size: float) -> void:
	var t := 0.0
	var dt := 0.02
	var steps := int(life / dt)
	var host: Node = p.get_parent()
	if host == null:
		return
	# 简单地隔 dt 调一次 position + 渐隐
	for i in steps:
		# 用 await 推进
		await host.get_tree().create_timer(dt, false).timeout
		if not is_instance_valid(p):
			return
		t += dt
		p.position += vel * dt
		vel.y += gravity * dt
		var alpha: float = 1.0 - t / life
		p.modulate.a = clampf(alpha, 0.0, 1.0)
		# 临死前缩小
		if alpha < 0.4:
			p.scale = Vector2(0.6, 0.6)
	p.queue_free()
