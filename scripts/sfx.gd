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

# ---------- BGM ----------
var _bgm_player: AudioStreamPlayer
var _bgm_playback: AudioStreamGeneratorPlayback
var _bgm_sample_idx: int = 0
const BGM_LOOP_SEC := 4.0                     # 4 秒一个循环

# C 大调频率表
const NOTE_C4 := 261.63
const NOTE_D4 := 293.66
const NOTE_E4 := 329.63
const NOTE_F4 := 349.23
const NOTE_G4 := 392.00
const NOTE_A4 := 440.00
const NOTE_B4 := 493.88
const NOTE_C5 := 523.25

const NOTE_C3 := 130.81
const NOTE_G3 := 196.00
const NOTE_A3 := 220.00
const NOTE_F3 := 174.61

# 4 秒 = 16 拍（每秒 4 拍）→ melody[i] = 第 i 拍的音高 (0 = 休止)
const BGM_MELODY: Array = [
	NOTE_C4, NOTE_E4, NOTE_G4, NOTE_E4,
	NOTE_C4, NOTE_D4, NOTE_E4, NOTE_C4,
	NOTE_F4, NOTE_E4, NOTE_D4, NOTE_C4,
	NOTE_G4, NOTE_E4, NOTE_C4, 0.0,
]
const BGM_BASS: Array = [
	NOTE_C3, 0.0, NOTE_C3, 0.0,
	NOTE_A3, 0.0, NOTE_A3, 0.0,
	NOTE_F3, 0.0, NOTE_F3, 0.0,
	NOTE_G3, 0.0, NOTE_G3, 0.0,
]
# 每拍 0.25s 是否"鼓点"：1=kick, 2=hat, 3=snare
const BGM_DRUM: Array = [1, 2, 0, 2, 1, 2, 0, 3, 1, 2, 0, 2, 1, 2, 0, 2]

# ---------- 初始化 ----------
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

	# BGM 用独立 stream（buffer 长一点）
	var bgm_stream := AudioStreamGenerator.new()
	bgm_stream.mix_rate = MIX_RATE
	bgm_stream.buffer_length = 1.0
	_bgm_player = AudioStreamPlayer.new()
	_bgm_player.stream = bgm_stream
	_bgm_player.bus = "Master"
	_bgm_player.volume_db = -8.0              # BGM 比 SFX 轻 8dB
	add_child(_bgm_player)

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

# ---------------------------------------------------------------------
# BGM —— 4 秒循环的 8-bit 风格背景音乐
#   旋律（C 大调）+ 贝斯 + 鼓点（kick / hat / snare）
# ---------------------------------------------------------------------

# 启动 / 继续
func play_bgm() -> void:
	if _bgm_player == null: return
	if _bgm_player.playing: return
	_bgm_player.play()
	_bgm_playback = _bgm_player.get_stream_playback()
	_bgm_sample_idx = 0
	_fill_bgm_buffer()

# 停止
func stop_bgm() -> void:
	if _bgm_player != null:
		_bgm_player.stop()

# 每帧检查 BGM 缓冲区是否需要补充
func _process(_delta: float) -> void:
	if _bgm_player == null: return
	if not _bgm_player.playing: return
	if _bgm_playback == null: return
	if _bgm_playback.get_frames_available() > 100:
		_fill_bgm_buffer()

func _fill_bgm_buffer() -> void:
	var available: int = _bgm_playback.get_frames_available()
	if available <= 0: return
	for i in available:
		var sample: float = _sample_bgm()
		_bgm_playback.push_frame(Vector2(sample * _master_volume, sample * _master_volume))
		_bgm_sample_idx += 1
		if _bgm_sample_idx >= int(MIX_RATE * BGM_LOOP_SEC):
			_bgm_sample_idx = 0    # 循环

# 合成一帧（旋律 + 贝斯 + 鼓）
func _sample_bgm() -> float:
	var t: float = float(_bgm_sample_idx) / MIX_RATE
	var beat: float = t * 4.0                                # 拍号（0~16）
	var beat_idx: int = int(beat) % 16
	var beat_local: float = beat - int(beat)                  # 本拍内 0~1 进度

	# 旋律（每拍 0.25s）
	var m_freq: float = BGM_MELODY[beat_idx]
	var melody: float = 0.0
	if m_freq > 0.0:
		var env: float = 1.0 - beat_local
		melody = square_wave(t, m_freq) * 0.10 * env

	# 贝斯
	var b_freq: float = BGM_BASS[beat_idx]
	var bass: float = 0.0
	if b_freq > 0.0:
		var env2: float = 1.0 - beat_local
		bass = square_wave(t, b_freq) * 0.18 * env2

	# 鼓
	var drum: float = 0.0
	var d: int = BGM_DRUM[beat_idx]
	if d == 1:                                # kick: 低正弦 50Hz
		drum = sin(TAU * 50.0 * t) * 0.25 * exp(-beat_local * 18.0)
	elif d == 2:                              # hat: 噪声
		drum = (randf() * 2.0 - 1.0) * 0.06 * exp(-beat_local * 30.0)
	elif d == 3:                              # snare: 噪声 + 200Hz
		drum = (randf() * 2.0 - 1.0 + sin(TAU * 200.0 * t)) * 0.10 * exp(-beat_local * 15.0)

	return melody + bass + drum

# 8-bit 风格的方波
func square_wave(t: float, freq: float) -> float:
	if freq <= 0.0: return 0.0
	var phase: float = fmod(t * freq, 1.0)
	return 1.0 if phase < 0.5 else -1.0
