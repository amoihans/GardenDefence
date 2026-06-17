# 项目代码讲解

> 配合源码读这篇。文件路径都是相对项目根目录。

---

## 1. 总体架构（一张图看懂）

```
				┌──────────────────────────────────┐
				│  AutoLoad 单例（全局，永远存在）  │
				├──────────────────────────────────┤
				│  GameState   阳光、波次、胜负     │
				│  PlantDB     所有植物/僵尸/波次    │
				│              配置 + 网格常量      │
				└──────────────┬───────────────────┘
							   │ 任何脚本都能直接访问
							   ▼
   ┌──────────┐   change_scene   ┌───────────────────────────────┐
   │ MainMenu │ ───────────────▶│            Game               │
   │  开始 退  │                  │  ┌──────────────────────────┐ │
   └──────────┘                  │  │     Lawn (5x9 网格)       │ │
								 │  │  - 棋盘背景               │ │
								 │  │  - 鼠标悬停高亮            │ │
								 │  │  - plant_requested 信号   │ │
								 │  └────────────┬─────────────┘ │
								 │               │ 信号           │
								 │               ▼                │
								 │  Game.gd 接到信号 → spend 阳光 │
								 │  → instantiate 植物 → add_child│
								 │                                │
								 │  WaveManager 按 PlantDB.WAVES  │
								 │    定时 spawn Zombie           │
								 │                                │
								 │  Plant ──fire──▶ Pea ──hit──▶ │
								 │                       Zombie   │
								 │  Sunflower ──spawn──▶ Sun      │
								 │  Sky timer ──spawn──▶ Sun      │
								 │                                │
								 │  HUD (CanvasLayer)             │
								 │   显示阳光、卡片、波次、暂停    │
								 └────────────────────────────────┘
```

关键设计原则：

1. **数据 / 表现 / 逻辑 分离**
   - 数据：`PlantDB`（数值表）
   - 表现：场景 .tscn（视图层）
   - 逻辑：.gd（行为层）
2. **节点间通过"信号 + 单例"通讯**，几乎不互相 `get_node` 直接耦合
3. **群组（group）替代碰撞**，简化游戏物体的相互查找

---

## 2. 文件清单

```
scripts/
├── game_state.gd        # autoload：全局状态（阳光、波次、胜负）
├── plant_db.gd          # autoload：植物/僵尸/波次数据 + 网格常量
│
├── plant.gd             # 植物基类（Node2D + HP + 行列）
├── sunflower.gd         # 向日葵：定时生成阳光
├── peashooter.gd        # 豌豆射手：发射 Pea
├── wallnut.gd           # 坚果：高 HP + 受伤变暗
├── cherrybomb.gd        # 樱桃：引信 + 范围伤害
│
├── zombie.gd            # 僵尸：自走 + 啃植物
├── pea.gd               # 子弹
├── sun.gd               # 阳光拾取物
│
├── lawn.gd              # 草坪网格（5x9）
├── plant_card.gd        # HUD 上的一张植物卡
├── hud.gd               # 顶部 UI
├── wave_manager.gd      # 波次推进
│
├── game.gd              # 战斗主场景控制
├── main_menu.gd         # 主菜单
└── game_over_panel.gd   # 胜利/失败结算

scenes/
├── main/{MainMenu,Game}.tscn
├── plants/{Sunflower,Peashooter,WallNut,CherryBomb,Repeater}.tscn
├── zombies/{Basic,Conehead,Buckethead}Zombie.tscn
├── projectiles/Pea.tscn
├── pickups/Sun.tscn
└── ui/{HUD,PlantCard,GameOverPanel}.tscn
```

---

## 3. 自上而下读：从启动到一颗豌豆射出

### 3.1 启动流程

1. `project.godot` 指定 `run/main_scene = MainMenu.tscn`
2. 同时 AutoLoad 了 `GameState`、`PlantDB`，两个永远在内存的单例
3. `MainMenu.tscn` 显示开始/退出
4. 点击「开始游戏」→ `main_menu.gd._on_start` → `change_scene_to_file("Game.tscn")`

### 3.2 Game 场景就绪

`game.gd._ready()`：

```gdscript
add_to_group("game_root")     # 给子节点一个公共锚点，方便挂动态实例
GameState.reset()             # 把阳光清回 50、波次清零
lawn.plant_requested.connect(_on_plant_requested)   # ★ 关键连接 1
lawn.shovel_requested.connect(_on_shovel_requested)
GameState.game_won.connect(_on_game_won)
GameState.game_lost.connect(_on_game_lost)
hud.pause_pressed.connect(_toggle_pause)
sky_timer.timeout.connect(_drop_sky_sun)            # ★ 关键连接 2
wave_manager.start()                                 # 启动波次
```

注意几条信号链：

- 草坪点击 → `Lawn` 发 `plant_requested` → `Game` 处理种植
- 僵尸到家 → `Zombie` 调 `GameState.declare_loss()` → 触发 `game_lost`
- 阳光被收集 → `Sun` 修改 `GameState.sun_amount` → 自动发 `sun_changed` → HUD 刷新

### 3.3 种下一棵向日葵的完整链路

1. 玩家点 HUD 上的「向日葵」卡片
2. `PlantCard._on_gui_input` → 检查 `is_usable()` → emit `pressed_card("sunflower")`
3. `HUD._on_card_pressed` 收到 → `GameState.selected_plant_id = "sunflower"`
4. `GameState` setter 触发 `selected_plant_changed.emit("sunflower")`
5. `Lawn._process` 每帧检测 `selected_plant_id`：
   - 非空时算出鼠标格子，把 `_hover_rect` 移到该格、染绿/红
6. 玩家在空格子上左键
7. `Lawn._unhandled_input` → emit `plant_requested(col, row, "sunflower")`
8. `Game._on_plant_requested`：
   ```gdscript
   if not GameState.spend(cost): return
   var scene = load(data.scene_path)
   var plant = scene.instantiate()
   plant.col / row / position = ...
   add_child(plant)
   lawn.register_plant(col, row, plant)
   hud.start_cooldown_for("sunflower")
   GameState.selected_plant_id = ""
   ```
9. 向日葵 `_ready` → `_on_ready_setup` 启动 5s 一次的 Timer
10. Timer 第一次 timeout → `_produce_sun` 实例化一颗 `Sun`，挂到 `game_root` 下

### 3.4 一颗豌豆从射出到命中

1. `Peashooter._fire_timer.timeout` → `_try_fire`
2. `_has_zombie_in_row` 遍历 `get_tree().get_nodes_in_group("zombies")`，看是否有同行右侧僵尸
3. 有则 `_shoot_pea`：
   - `instantiate Pea`、`setup(row, damage)`、`global_position = (plant.x+20, plant.y-10)`
   - 加到 `game_root`
4. `Pea._process` 每帧 +SPEED*delta；同时遍历 `zombies` 组判距离
5. 命中 → `z.take_damage(20)`、`_hit_effect()` 复制一个变大变透明的自己、`queue_free()`
6. 僵尸血 ≤ 0 → `Zombie.die()` 倒下动画后 `queue_free()`

---

## 4. 关键脚本细节

### 4.1 `game_state.gd` —— Setter 自动发信号

```gdscript
var sun_amount: int = 50 : set = _set_sun

func _set_sun(value: int) -> void:
	sun_amount = max(0, value)
	sun_changed.emit(sun_amount)
```

GDScript 支持 setter 语法 `var x: T : set = func_name`。任何 `sun_amount += 25` 都会走 setter，HUD 自动刷新——这意味着调用方不需要关心"我得记得通知 UI"。

### 4.2 `plant_db.gd` —— 数据驱动

把所有植物 / 僵尸 / 波次塞进一个静态字典：

```gdscript
const PLANTS: Dictionary = {
	"sunflower": {"cost": 50, "max_hp": 60, "scene_path": "..."},
	...
}
```

新增一种植物：
1. 写一个 `xxx.gd extends Plant`
2. 做一个 `Xxx.tscn`
3. 在这里加一行配置
4. 把 id 加进 `HUD_PLANT_ORDER`

整局游戏的"平衡数值"在一个文件里改。

工具函数：

```gdscript
static func cell_to_world(col, row) -> Vector2   # 网格 → 屏幕坐标
static func world_to_cell(pos) -> Vector2i       # 屏幕 → 网格（越界返 -1,-1）
static func row_to_y(row) -> float               # 行号 → y 中线
```

任何需要"格子位置"的地方调它，**不允许散落硬编码**。

### 4.3 `plant.gd` —— 继承 + 模板方法

基类提供 HP、受击红闪、死亡通知。子类只重写一个 `_on_ready_setup()`：

```gdscript
# 基类：
func _ready() -> void:
	current_hp = max_hp
	add_to_group("plants")
	_on_ready_setup()      # ★ 钩子

func _on_ready_setup() -> void:    # ★ 子类填空
	pass
```

这是经典的 **Template Method 模式**，子类不需要 `super._ready()` 这种容易忘的事情。

### 4.4 `peashooter.gd` —— 用群组找目标

```gdscript
func _has_zombie_in_row() -> bool:
	for z in get_tree().get_nodes_in_group("zombies"):
		if z is Zombie and z.row == row \
				and z.global_position.x > global_position.x - 16:
			return true
	return false
```

不用射线、不用碰撞——遍历 + 简单条件就够了。**100 个僵尸 × 5 个射手 = 500 次/帧的遍历**，对现代 CPU 是空气，简单可靠。

### 4.5 `zombie.gd` —— 在物理帧里"看"植物

```gdscript
func _physics_process(delta: float) -> void:
	var target := _find_plant_to_eat()
	if target != null:
		_eat(target, delta)
	else:
		global_position.x -= speed * delta
```

为什么用 `_physics_process` 而不是 `_process`？
- `_physics_process` 频率固定 60Hz，避免不同帧率下移动距离不同
- 后续如果加碰撞或追踪，物理对象推荐用 `_physics_process`

`_find_plant_to_eat` 思路：同行、且植物 x 在 zombie 左边一点点的范围内 → 选 x 最大（最右）的那个。这天然保证僵尸啃的是**它面前的第一棵植物**。

### 4.6 `lawn.gd` —— 鼠标 → 网格

```gdscript
func _process(_delta) -> void:
	if GameState.selected_plant_id == "":
		_hide_hover(); return
	var cell := PlantDB.world_to_cell(get_global_mouse_position())
	if cell.x < 0: _hide_hover(); return
	_hover_rect.position = (LAWN_ORIGIN + cell * CELL_SIZE)
	_hover_rect.color = green_or_red_based_on_occupancy
```

`plants` 是一个二维数组（9×5），存放 `Plant 实例 / null`。这是**最直接的 grid 数据结构**——查询 O(1)，遍历方便。

植物死了怎么清这个矩阵？
```gdscript
func register_plant(col, row, plant):
	plants[col][row] = plant
	plant.died.connect(_on_plant_died.bind(col, row))   # ★ bind 闭包
```

`Callable.bind()` 把 `col, row` 提前塞进信号回调的参数列表。植物自己 emit 时不需要知道自己的位置。

### 4.7 `plant_card.gd` —— 三态视觉

| 状态 | 显示 | 可点 |
|---|---|---|
| 满足条件 | 全色 | ✓ |
| 阳光不够 | 整体变暗 | ✗ |
| 冷却中 | 顶部覆盖灰色遮罩（从下往上消退） | ✗ |
| 已选中 | 黄色边框 | — |

冷却遮罩用一个 `ColorRect`，每帧调整 `position.y` 和 `size.y`：

```gdscript
var p := _cd_remaining / cooldown               # 0..1
var h := size.y * p                              # 当前需要覆盖的高度
cooldown_overlay.position = Vector2(0, size.y - h)
cooldown_overlay.size     = Vector2(size.x, h)
```

剩余时间越长，遮罩越高（盖住下面）。视觉效果就是冷却"从下往上消"。

### 4.8 `wave_manager.gd` —— 用 `await` 写顺序流程

```gdscript
for wi in total:
	GameState.advance_wave(total)
	for zombie_id in wave.spawns:
		_spawn_zombie(zombie_id)
		await get_tree().create_timer(interval).timeout
	if wi < total - 1:
		await get_tree().create_timer(wave.rest).timeout
```

`await` 是 GDScript 的协程：暂停函数到信号触发再继续，不阻塞主线程。
**用 await 写关卡脚本远比一堆 Timer + 状态变量清爽。**

最后波刷完之后还要等场上无僵尸才宣布胜利：

```gdscript
while not GameState.is_game_over:
	await get_tree().create_timer(0.5).timeout
	if get_tree().get_nodes_in_group("zombies").is_empty():
		GameState.declare_win()
		return
```

### 4.9 `sun.gd` —— 同一脚本两种生成方式

```gdscript
func skyfall(start_pos, ground_y):        # 天降：从空中落到地面
	_is_falling = true
	...

func ground_pop():                         # 向日葵：原地跳一下
	var t := create_tween()
	t.tween_property(...)
```

外部根据来源调不同接口，避免分两个类。

点击收集 → 飞向 HUD 阳光数字 → 真正加阳光：

```gdscript
func _collect():
	var t := create_tween()
	t.set_parallel(true)
	t.tween_property(self, "global_position", Vector2(60, 40), 0.4)
	t.tween_property(self, "scale", Vector2(0.4, 0.4), 0.4)
	t.tween_property(self, "modulate:a", 0.3, 0.4)
	t.chain().tween_callback(_finish_collect)

func _finish_collect():
	GameState.sun_amount += VALUE
	queue_free()
```

`set_parallel(true)` 让位置、缩放、透明度三个 tween 同时进行；`chain()` 切回串行接 callback。

---

## 5. 怎么扩展？

### 加一种植物（举例：寒冰射手 freezer，发冰豆减速）

1. `assets/plants/freezer.svg`（或复制 peashooter 改色）
2. `scripts/freezer.gd`：
   ```gdscript
   extends Plant
   const ICEPEA = preload("res://scenes/projectiles/IcePea.tscn")
   var _t: Timer
   func _on_ready_setup():
	   _t = Timer.new(); _t.wait_time = 2.0; _t.autostart = true
	   add_child(_t); _t.timeout.connect(_fire)
   func _fire():
	   # 同 peashooter 思路，但子弹另一个场景，命中后 zombie.speed *= 0.5
   ```
3. `IcePea.tscn` 复制 Pea.tscn，挂 ice_pea.gd（命中时给 zombie 加一个减速 Timer）
4. `plant_db.gd`：
   ```gdscript
   "freezer": {"cost": 175, "max_hp": 60, "cooldown": 7.5, ...}
   ```
   把 "freezer" 加进 `HUD_PLANT_ORDER`
5. 跑起来就有了

### 加一种僵尸（举例：飞行僵尸 flyer，无视植物）

1. 复制 BasicZombie.tscn 改贴图
2. 复制 zombie.gd 改 `_physics_process`：去掉 `_find_plant_to_eat` 分支
3. 在 `plant_db.gd` 注册
4. 在 WAVES 里加它

---

## 6. 性能 / 工程小贴士

- **`load()` vs `preload()`**：`preload` 在编译期解析、随脚本一并装入；`load` 在运行期。频繁使用的资源（如 Pea、Sun 场景）用 `preload`。
- **`queue_free` 而不是 `free`**：避免在迭代过程中删自己导致崩溃。
- **`is_instance_valid(x)`**：在 await 之后用一下，防止节点期间被销毁。
- **`@onready var x = $Path`**：等价 `_ready` 里赋值，但更紧凑。
- **`get_tree().paused = true`** 配合每个节点的 `process_mode` 控制暂停行为；HUD 设为 `PROCESS_MODE_ALWAYS` 才能在暂停时点按钮（本项目已配）。

---

## 7. 调试技巧

- 打开 **远程场景树**（运行时 → Remote 标签），实时看 zombies / plants / suns 数量与位置
- `print(GameState.sun_amount)` 输出到底部"输出"面板
- 在 `_physics_process` 里临时画线：`queue_redraw()` + `_draw()` 里 `draw_line(...)`
- 怀疑某个事件没触发：在信号回调第一行 `print("triggered")`

---

## 8. 接下来

读到这就掌握全部代码了。下一步：
- `04-BUILD.md` 学怎么运行和打包成 .exe
- 自己改一个数值/加一棵植物，跑一遍验证理解
