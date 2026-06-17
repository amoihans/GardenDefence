# scripts/sfx.gd
# ----------------------------------------------------------------------
# 程序化音效（AutoLoad 单例）
#
# 我们项目零外部资源，但引擎自带的 AudioStreamGenerator 让我们能用
# 正弦波 + 噪声直接生成"射击/爆炸/收集/死亡"四类基础音效。
#
# 用法：
#   Sfx.play_shoot()          # 豌豆射出去
#   Sfx.play_shoot_ice()      # 冰豆（更尖锐）
#   Sfx.play_explosion()      # 樱桃 / 土豆
#   Sfx.play_sun_collect()    # 收阳光
#   Sfx.play_zombie_die()     # 僵尸倒下
#
# 设置面板里调音量（_on_volume_changed）。
# ----------------------------------------------------------------------
extends Node

const POOL_SIZE := 6
const MIX_RATE := 22050

var _players: Array[AudioStreamPlayer] = []
var _stream: AudioStreamGenerator
var _master_volume: float = 1.0

func _ready() -> void:
	_stream = AudioStreamGenerator.new()
	_stream.mix_rate = MIX_RATE
	_stream.buffer_length = 0.25
	for i in POOL_SIZE:
		var p := AudioStreamPlayer.new()
		p.stream = _stream
		p.bus = "Master"
		add_child(p)
		_players.append(p)

# 由 Settings.gd 在音量变更时调用
func set_master_volume(v: float) -> void:
	_master_volume = clampf(v, 0.0, 1.0)
	# 转 dB；1.0 → 0dB，0.0 → -40dB
	var db: float = -40.0 + _master_volume * 40.0
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), db)

# ---------------------------------------------------------------------
# 音效 API
# ---------------------------------------------------------------------

func play_shoot() -> void:
	_play_buzzy(880.0, 0.05, 25.0, 0.30)

func play_shoot_ice() -> void:
	_play_buzzy(1320.0, 0.07, 30.0, 0.28)

func play_explosion() -> void:
	_play_noise(0.18, 6.0, 0.45)

func play_sun_collect() -> void:
	_play_chime(880.0, 1320.0, 0.10, 0.20)

func play_zombie_die() -> void:
	_play_buzzy(180.0, 0.15, 8.0, 0.35)

# 找一个空闲的播放池成员
func _get_free_player() -> AudioStreamPlayer:
	for p in _players:
		if not p.playing:
			return p
	return null

# 正弦波 beep：发射 / 死亡 类
func _play_buzzy(freq: float, duration: float, decay: float, amp: float) -> void:
	var p := _get_free_player()
	if p == null: return
	p.play()
	var playback: AudioStreamGeneratorPlayback = p.get_stream_playback()
	if playback == null: return
	var n: int = int(MIX_RATE * duration)
	for i in n:
		var t: float = float(i) / MIX_RATE
		var env: float = exp(-t * decay)
		var sample: float = sin(t * TAU * freq) * env * amp * _master_volume
		playback.push_frame(Vector2(sample, sample))

# 噪声爆炸：樱桃 / 土豆
func _play_noise(duration: float, decay: float, amp: float) -> void:
	var p := _get_free_player()
	if p == null: return
	p.play()
	var playback: AudioStreamGeneratorPlayback = p.get_stream_playback()
	if playback == null: return
	var n: int = int(MIX_RATE * duration)
	for i in n:
		var t: float = float(i) / MIX_RATE
		var env: float = exp(-t * decay)
		var sample: float = (randf() * 2.0 - 1.0) * env * amp * _master_volume
		playback.push_frame(Vector2(sample, sample))

# 叮咚（双音）：收阳光
func _play_chime(freq1: float, freq2: float, duration: float, amp: float) -> void:
	var p := _get_free_player()
	if p == null: return
	p.play()
	var playback: AudioStreamGeneratorPlayback = p.get_stream_playback()
	if playback == null: return
	var n: int = int(MIX_RATE * duration)
	for i in n:
		var t: float = float(i) / MIX_RATE
		var env: float = exp(-t * 18.0)
		var sample: float = (sin(t * TAU * freq1) * 0.6 + sin(t * TAU * freq2) * 0.4) * env * amp * _master_volume
		playback.push_frame(Vector2(sample, sample))
