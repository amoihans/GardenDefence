# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 运行

**没有 Makefile / 构建脚本**。这个项目是纯 Godot 工程：

- 打开 Godot 4.x Standard → 导入 `D:\hans\godot\project.godot` → F5
- 主场景 `scenes/main/MainMenu.tscn`
- 导出 EXE 配置在 `export_presets.cfg`（文档见 `docs/04-BUILD.md`）
- 存档位置 `user://save.cfg`（Windows 实际路径 `%APPDATA%\Godot\app_userdata\庭院保卫战 (Garden Defense)\save.cfg`）

**没有测试 / 没有 CI / 没有 Lint**。调试靠 Godot 编辑器底部 Errors 面板。

## 关键约定（先读这些再写代码）

### GDScript 4.6 严格类型陷阱
- `extends` 必须是文件**第一个非注释语句**（`class_name` 之后）。`const := preload(...)` 必须放在 `extends` **之后**，否则 `Unexpected 'extends' in class body`。
- **不要写 class_name 自引用**：`class_name Plant` 紧跟 `signal died(plant: Plant)` 会让整个脚本解析失败。signal 参数用无类型或基本类型。
- **跨文件 class_name 类型引用是连锁陷阱** — a.gd 解析失败 → class_name A 没注册 → b.gd 找 A 失败 → b.gd 的 class_name B 也不注册 → c.gd 找 B 也失败。**最稳的解法：跨文件类型注解全部用 `Node`**，靠 `node as Type` cast + 动态派发。`extends X` 是必需继承（依赖 class_name 的本职），无法绕过。
- `get_nodes_in_group()` 返回 `Array[Node]`，不能直接 `for x is Plant`。必须 `var p := node as Plant; if p == null: continue`。
- `create_timer(N, false)` 第二个参数**必须显式传 false** — Godot 4 默认 `process_always=true`，暂停时计时器继续跑。
- `set_process(false)` 会**永久**关掉 _process。临时分支用 bool 标志位。
- 子类覆写方法签名必须**完全一致**（参数 + 返回类型 + 默认值），否则 `function signature doesn't match parent`。
- `CanvasItem` 是 `Node2D` 和 `Control` 的共同父类。做"通用 2D 节点"参数用 `CanvasItem`（这样 `ColorRect` 也能传）。

### HUD / 控件
- CanvasLayer 必须 `process_mode = 3`（`PROCESS_MODE_ALWAYS`），否则暂停后按钮失效。
- `Control` 默认 `mouse_filter = STOP` 会吞所有点击。纯装饰用 `MOUSE_FILTER_IGNORE (2)`，否则下层 Node2D 收不到 `_unhandled_input`。

### 物理 / 碰撞
- 项目**完全不用 Area2D / 物理碰撞**做单位间通讯。所有"找同行僵尸 / 找碰撞"都靠 `get_tree().get_nodes_in_group(...)` + 距离判断。物理层在 `project.godot` 里只是装饰。

## 架构

### AutoLoad 单例（`project.godot` 23-31 行）
启动时全部加载，**全局可访问，名字就是变量名**：

| 单例 | 职责 |
|---|---|
| `GameState` | 阳光数 / 波次 / 胜负 / 选中的植物 / 肥料 / 存档读写 |
| `PlantDB` | **所有配置数据**：PLANTS / ZOMBIES / WAVES / LEVELS / 网格常量 |
| `Sfx` | 程序化音效（爆 / 啃 / 收阳光）+ 8-bit BGM |
| `Settings` | 用户设置（音量等） |
| `AchievementDB` | 成就状态 + 触发回调 |
| `CodeBookDB` | 图鉴解锁状态 |
| `ToastManager` | 浮动成就提示 |

### 信号 + 群组
- 节点间通讯走**信号 + 群组**，不用 `get_parent().get_parent()` 取节点。
- 群组：`plants` / `zombies` / `lawn_mowers` / `game_root` / `lawn`。
- 全局状态变更靠 `setter` 自动 emit 信号（见 `game_state.gd` 的 `_set_sun` 模式）。

### 模板方法（Plant 基类）
`scripts/plant.gd` 是所有植物的基类。子类重写 `_on_ready_setup()` 做自己的初始化（计时器 / 子弹 / 阳光）。`die()` / `take_damage()` / `fertilize()` 都不重写。`fertilize()` 默认行为是 5 秒金色发光，子类可重写为"立刻开火 / 立即引爆"等。

### 数据驱动
**所有数值都在 `scripts/plant_db.gd`**，不在脚本里散硬编码。改数值 / 加植物 / 加僵尸只动这个文件 + 一份 .gd + 一份 .tscn + 一份 .svg。详见 `docs/03-IMPLEMENTATION.md §5`。

### 网格系统
- `PlantDB.LAWN_ORIGIN_X / Y` + `CELL_SIZE` 定义草坪左上角 + 格子大小
- `cell_to_world(col, row)` / `world_to_cell(pos)` 工具方法封装在 `PlantDB` 里
- 5 行 × 9 列（`GRID_ROWS` / `GRID_COLS`）

### 输入动作
`project.godot` 41-93 行定义：`place_plant` / `cancel_selection` / `pause` / `slot_1..6` / `fertilize`。脚本里**只用动作名**，不直接监听具体键。

## 常见任务

| 任务 | 改哪里 |
|---|---|
| 改数值（伤害 / 阳光 / 冷却） | `scripts/plant_db.gd` |
| 加新植物 | 拷 .gd + .tscn + .svg + `PlantDB.PLANTS` 注册 + `PlantDB.HUD_PLANT_ORDER` 排序 |
| 加新僵尸 | 拷 .gd + .tscn + .svg + `PlantDB.ZOMBIES` 注册 |
| 加新关卡 | `PlantDB.LEVELS` 加一项（含 waves 数组） |
| 改输入键 | `project.godot` `[input]` 段 |
| 加新成就 | `AchievementDB` 加条目 + 在触发点调 `AchievementDB.on_xxx()` |

## 配套文档

`docs/01-QUICK_START.md` → `04-BUILD.md` 四篇是给 Godot 初学者的教程。**改代码前先看 `03-IMPLEMENTATION.md`**，它解释了每个模块为什么这么写。`README.md` 是项目门面。

## 提交

- 仓库：https://github.com/amoihans/GardenDefence.git
- 习惯一次 commit 做一件事（fix / feat / refactor）
- 提交信息中文即可
