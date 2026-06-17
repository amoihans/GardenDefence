# scripts/dancer_zombie.gd
# ----------------------------------------------------------------------
# 舞王僵尸：每 10s 召唤一只伴舞（基础 basic 僵尸），最多召唤 4 次
# 召唤时在自身所在行 + 自身右侧 1 格生成 basic 僵尸
# ----------------------------------------------------------------------
extends Zombie

const SUMMON_INTERVAL := 10.0
const MAX_SUMMONS := 4
const BASIC_SCENE := preload("res://scenes/zombies/BasicZombie.tscn")

var _summons_left: int = MAX_SUMMONS
var _summon_timer: Timer

func _ready() -> void:
	super._ready()
	_summon_timer = Timer.new()
	_summon_timer.wait_time = SUMMON_INTERVAL
	_summon_timer.one_shot = false
	_summon_timer.autostart = true
	add_child(_summon_timer)
	_summon_timer.timeout.connect(_on_summon)

func _on_summon() -> void:
	if _summons_left <= 0: return
	if GameState.is_game_over: return
	_summons_left -= 1
	# 召一个 basic 同行
	var z: Zombie = BASIC_SCENE.instantiate()
	z.row = row
	z.global_position = global_position + Vector2(40, 0)
	var game := get_tree().get_first_node_in_group("game_root")
	if game:
		game.add_child(z)
	else:
		get_parent().add_child(z)
	Sfx.play_zombie_die()                                # 借用死亡音效作为"召唤"提示
