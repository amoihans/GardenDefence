# 庭院保卫战 · Garden Defense

> 一份 **Godot 4 + GDScript** 的塔防小游戏，植物大战僵尸玩法的最小可玩复刻。
> 整个项目 ~1500 行代码，**全部用 SVG 矢量素材**，无任何外部依赖。
> 面向 Godot 初学者，配套四篇详细文档。

![icon](icon.svg)

## 5 分钟跑起来

1. 去 [godotengine.org/download](https://godotengine.org/download) 下载 **Godot 4.x Standard**（单文件 exe，无需安装）
2. 双击 → 项目管理器 → **导入** → 选 `project.godot`
3. 按 **F5** 开始游戏

## 文档

四篇文档按推荐顺序读：

| # | 文档 | 一句话 |
|---|---|---|
| 1 | [docs/01-QUICK_START.md](docs/01-QUICK_START.md) | Godot 4 零基础入门 |
| 2 | [docs/02-GAME_DESIGN.md](docs/02-GAME_DESIGN.md) | 玩法 / 数值 / 关卡设计 |
| 3 | [docs/03-IMPLEMENTATION.md](docs/03-IMPLEMENTATION.md) | 代码逐层解析 |
| 4 | [docs/04-BUILD.md](docs/04-BUILD.md) | 运行与导出 EXE |

## 玩法

- 5 行 × 9 列草坪，僵尸从右往左推进
- 用阳光种植物拦截，撑过 5 波即胜利
- 植物：向日葵 / 豌豆射手 / 坚果墙 / 樱桃炸弹 / 双发射手 + 铲子
- 僵尸：普通 / 路障 / 铁桶

## 操作

| 操作 | 按键 |
|---|---|
| 收阳光 | 左键点击 |
| 选植物 | 数字键 1~5，或鼠标点 HUD 卡片 |
| 选铲子 | 数字键 6 |
| 种 / 铲 | 左键点格子 |
| 取消选择 | 右键 / Esc |
| 暂停 | Space / HUD 右上 [暂停] |

## 项目结构

```
godot/
├── README.md              # 本文件
├── project.godot          # Godot 项目入口
├── icon.svg               # 项目图标
├── docs/                  # ★ 4 篇文档
├── assets/                # SVG 素材（植物 / 僵尸 / UI / 世界）
├── scenes/                # .tscn 场景
│   ├── main/              #   主菜单 + 战斗主场
│   ├── plants/            #   5 种植物
│   ├── zombies/           #   3 种僵尸
│   ├── projectiles/       #   豌豆
│   ├── pickups/           #   阳光
│   └── ui/                #   HUD / 卡片 / 结算
└── scripts/               # GDScript
    ├── game_state.gd      # AutoLoad：全局状态
    ├── plant_db.gd        # AutoLoad：所有配置数据
    ├── plant.gd           # 植物基类
    ├── *.gd               # 各类植物 / 僵尸 / Pea / Sun / Lawn / HUD …
    └── game.gd            # 战斗主场景控制
```

## 想动手改？

最低成本扩展（参考 [docs/03-IMPLEMENTATION.md §5](docs/03-IMPLEMENTATION.md)）：

- **改数值**：编辑 `scripts/plant_db.gd` 里的 PLANTS / ZOMBIES / WAVES
- **加植物**：拷贝一份 `*.gd + *.tscn + *.svg` + 在 `plant_db.gd` 注册
- **换美术**：把 `assets/` 下任意 SVG 换成同名 PNG / SVG 即可

## 协议

代码 MIT；SVG 素材 CC0。

## 致谢

- 灵感来源：PopCap 《Plants vs. Zombies》
- 引擎：[Godot Engine](https://godotengine.org) — MIT
