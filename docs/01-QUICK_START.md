# Godot 4 快速入门（零基础版）

> 目标读者：完全没用过 Godot、但有一点编程基础的你。
> 读完这一篇，你能看懂本项目里所有 `.tscn` 与 `.gd` 文件。

---

## 1. Godot 是什么？

Godot 是一个开源的游戏引擎，由编辑器 + 运行时组成。它有两个最关键的特点：

1. **一切皆节点（Node）**：游戏里的一棵树状结构，每个节点负责一件具体的事（显示图、播放声音、检测碰撞……）。组合这些节点就能拼出任何游戏对象。
2. **场景（Scene）就是一棵节点树**：可以保存复用。一个植物是一个场景，一个僵尸是一个场景，整张游戏画面也是一个场景。

理解了这两件事，剩下的都是细节。

---

## 2. 安装

1. 去 [godotengine.org](https://godotengine.org/download) 下载 **Godot 4.x Standard**（不是 .NET 版，本项目用 GDScript）。
2. 解压得到一个单独的 `Godot_v4.x_win64.exe`（≈ 70MB），双击即启动，不需要安装。
3. 第一次打开是项目管理器。点 **导入** → 选择 `D:\hans\godot\project.godot` → 编辑。

> Godot 没有"安装包"，整个引擎就一个 exe。删了也没残留。

---

## 3. 编辑器界面三分钟速览

打开项目后看到这几块：

```
┌──────────────────────────────────────────────────────────┐
│ 顶部菜单  [2D] [3D] [Script] [AssetLib]    [▶ 运行]      │
├───────────┬──────────────────────────────┬───────────────┤
│ 场景树    │                              │  检查器        │
│ (Scene)   │       视口 (Viewport)         │  (Inspector)  │
│           │   你在这里看到游戏画面         │   选中节点的   │
│ 节点列表   │                              │   属性都在这    │
├───────────┤                              ├───────────────┤
│ 文件系统  │                              │  节点 / 信号   │
│ (FileSys) │                              │  (Node panel) │
└───────────┴──────────────────────────────┴───────────────┘
                  底部：输出 / 调试器 / 文件搜索
```

- **场景树**：当前打开的场景的节点结构。
- **视口**：游戏画面，可以拖动、缩放。
- **检查器**：选中一个节点，所有可改属性在右边。
- **节点面板**：选中节点后，下面可以连接它的"信号（Signal）"。
- **文件系统**：项目里的所有文件（场景、脚本、图片）。

切到 **Script** 标签是代码编辑器。

---

## 4. 核心概念：Node、Scene、Script

### Node（节点）

最小的功能单元。常用的几类：

| 节点类型 | 干什么用 |
|---|---|
| `Node` | 啥也不做，纯逻辑容器 |
| `Node2D` | 有位置、旋转、缩放的 2D 对象基类 |
| `Sprite2D` | 显示一张图 |
| `Area2D` | 检测碰撞但不被物理推 |
| `CharacterBody2D` | 玩家/怪物常用，受控移动 + 物理 |
| `RigidBody2D` | 被物理推（重力、力） |
| `CollisionShape2D` | 给上面的物体加一个碰撞形状 |
| `Timer` | 计时器，到点发信号 |
| `Label` | UI 文本 |
| `Button` | UI 按钮 |
| `CanvasLayer` | UI 专用层，不受相机影响 |

### Scene（场景）

把若干 Node 拼成一棵树，保存为 `.tscn` 文件。**场景可以嵌套实例化**：本项目的 `Sunflower.tscn` 就是 `Plant.tscn` 的派生场景，而 `Game.tscn` 里又会动态实例化无数个 `Sunflower` 节点。

### Script（脚本）

附加在节点上的 `.gd` 文件。脚本通过继承获得节点的全部能力，并且可以在生命周期函数里写自己的逻辑。

---

## 5. GDScript 速成

GDScript 看起来像 Python，强类型可选。本项目所有脚本都用它。

### 5.1 文件结构

```gdscript
extends Node2D                            # 继承的节点类型
class_name MyPlant                        # 给脚本起个全局类名（可选）

# ---------- 信号 ----------
signal died(by_zombie: Zombie)            # 自定义信号

# ---------- 导出到检查器的变量 ----------
@export var max_hp: int = 100             # 在编辑器右侧能直接改
@export var damage: float = 20.0

# ---------- 私有/普通变量 ----------
var current_hp: int = 100
var _cooldown: float = 0.0

# ---------- 子节点引用 ----------
@onready var sprite: Sprite2D = $Sprite2D           # $ 是 get_node 的语法糖
@onready var timer: Timer    = $AttackTimer

# ---------- 生命周期 ----------
func _ready() -> void:                    # 入场时调用一次
    current_hp = max_hp
    timer.timeout.connect(_on_attack_timer)

func _process(delta: float) -> void:      # 每帧调用，delta = 上一帧耗时
    _cooldown -= delta

func _physics_process(delta: float) -> void:  # 物理帧，频率稳定
    pass

# ---------- 自定义函数 ----------
func take_damage(amount: int) -> void:
    current_hp -= amount
    if current_hp <= 0:
        died.emit(null)                   # 发射信号
        queue_free()                      # 安全地从场景树移除

func _on_attack_timer() -> void:
    print("攻击！")
```

### 5.2 类型与运算

```gdscript
var i: int = 5
var f: float = 3.14
var s: String = "hello"
var v: Vector2 = Vector2(10, 20)          # 2D 向量，最常用
var a: Array = [1, 2, 3]
var d: Dictionary = {"name": "豌豆射手", "hp": 100}
var b: bool = true
```

`Vector2` 是 2D 游戏的灵魂：

```gdscript
var pos: Vector2 = Vector2(100, 200)
pos += Vector2(10, 0)                     # 向右移动
var distance: float = pos.distance_to(other_pos)
var direction: Vector2 = (target - pos).normalized()
```

### 5.3 控制流

```gdscript
if hp > 0:
    print("活着")
elif hp == 0:
    print("濒死")
else:
    print("死了")

for i in range(5):              # 0..4
    print(i)

for zombie in zombies:          # 遍历数组
    zombie.take_damage(10)

while not done:
    do_something()

# match 类似 switch
match state:
    "idle": pass
    "attack": _attack()
    _: print("未知状态")
```

### 5.4 获取节点的几种方式

```gdscript
$Sprite2D                                # 同级子节点（最常用）
$"HUD/SunLabel"                          # 多级路径
get_node("Sprite2D")                     # 等价于上面
get_parent()                             # 父节点
get_tree().get_root()                    # 根节点
get_tree().get_first_node_in_group("zombies")   # 按组查找
```

> **群组（Group）**：可以给任意节点贴一个或多个标签字符串，便于按类型查找。
> 本项目把所有僵尸加进 `"zombies"` 组，植物用射线时直接遍历该组。

---

## 6. 信号（Signal）—— 节点之间通信的最佳方式

信号是"事件回调"。节点 A 发信号，节点 B 监听，A 不需要知道 B 是谁。

**发射**：

```gdscript
signal collected(amount: int)            # 声明
collected.emit(25)                       # 触发
```

**连接**（两种方式）：

```gdscript
# 1. 编辑器：选中节点 → 节点面板 → 双击信号 → 选择接收节点
# 2. 代码：
sun.collected.connect(_on_sun_collected)

func _on_sun_collected(amount: int) -> void:
    sun_total += amount
```

**Godot 4 内置常用信号**：

- `Button.pressed` —— 按钮按下
- `Timer.timeout` —— 计时器到点
- `Area2D.body_entered(body)` —— 物体进入区域
- `Area2D.area_entered(area)` —— 另一个 Area 进入

---

## 7. 输入处理

三种写法，按需选：

```gdscript
# A. 每帧轮询（适合持续输入，比如按住移动）
func _process(_delta):
    if Input.is_action_pressed("ui_right"):
        position.x += 5

# B. 事件回调（适合单次触发）
func _input(event: InputEvent) -> void:
    if event is InputEventMouseButton and event.pressed:
        print("点击了 ", event.position)

# C. 未消费的输入（UI 之外的输入）
func _unhandled_input(event):
    pass
```

**输入映射**：项目 → 项目设置 → 输入映射 里定义动作（如 `place_plant`），然后用 `Input.is_action_pressed("place_plant")` 引用，便于改键。

---

## 8. 资源（Resource）

`.tres` / `.res` 文件是可保存的数据对象。在本项目里你会看到：

- `PlantData.tres`：每种植物的数值（HP、攻击速度、价格、贴图）
- `WaveConfig.tres`：每一波刷什么僵尸

定义一个资源类：

```gdscript
class_name PlantData extends Resource

@export var display_name: String
@export var cost: int
@export var max_hp: int
@export var scene: PackedScene            # 关联场景
```

然后右键 → 新建资源 → PlantData，就能在检查器里填好数值并保存为文件。

> 这是 Godot 区别于大多数引擎的一个超好用的设计：**数据驱动**。

---

## 9. AutoLoad（单例 / 全局脚本）

项目设置 → 自动加载 里挂上一个脚本，整局游戏只有一个实例，任何脚本都能用名字访问。

本项目的 `GameState`（在 `scripts/game_state.gd`）就是 AutoLoad：

```gdscript
# 别的脚本里直接用：
GameState.sun_amount += 25
GameState.game_over.emit()
```

适合存：玩家阳光、当前关卡、设置项 …… 别用 AutoLoad 存"当前场景里的某个对象"。

---

## 10. 运行 / 调试

- **F5** = 运行主场景（项目设置里指定）
- **F6** = 运行当前打开的场景
- **F8** = 停止
- **左侧调试器**：断点、变量、调用栈、远程场景树
- `print()` 输出到下方的"输出"面板

---

## 11. 常见坑

1. **`@onready` 必须用于 `$Node` 引用**，否则 `_ready` 之前 `null`。
2. **删除节点用 `queue_free()`**，不要用 `free()`——`free` 是立刻删，可能导致信号回调里访问已被删的对象。
3. **`Vector2(0, -1)` 才是"向上"**：Godot 2D Y 轴朝下。
4. **类型注解强烈推荐**：`var x: int = 0` 比 `var x = 0` 报错更早。
5. **场景树未就绪时调用方法**：在 `_init` 里访问子节点会崩，子节点要在 `_ready` 才存在。
6. **导出变量改完场景没生效**：可能你改的是父场景，而某个子场景 override 了。

---

## 12. 接下来读哪份文档

| 顺序 | 文档 | 内容 |
|---|---|---|
| 1 | **本文** | Godot 概念 |
| 2 | `02-GAME_DESIGN.md` | 游戏怎么玩、数值表 |
| 3 | `03-IMPLEMENTATION.md` | 项目代码逐层解析 |
| 4 | `04-BUILD.md` | 运行和打包 exe |

打开 Godot 后建议先按 F5 跑一次完整流程，再回来读 `03-IMPLEMENTATION.md`，体感会强很多。
