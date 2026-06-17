# scripts/plant_db.gd
# ----------------------------------------------------------------------
# 植物 / 僵尸 / 关卡 配置数据库（AutoLoad 单例）
#
# 设计目的：
#   把所有"数值"集中到一个地方，方便平衡和扩展。
#   想加一个新植物 = 在这里加一项 + 复制一份 Plant 子类 + 一个 .tscn。
#
# 用法：
#   PlantDB.PLANTS["peashooter"].cost   # → 100
#   PlantDB.LEVELS[0].waves             # → 第一个关卡的波次
# ----------------------------------------------------------------------
extends Node

# 植物数据 ------------------------------------------------------------
# 字段说明：
#   display_name : 卡片上的中文名
#   cost         : 阳光价格
#   max_hp       : 血量
#   cooldown     : 卡片冷却（s），种下之后多久才能再种同种
#   scene_path   : 对应的 .tscn 路径
#   icon_path    : 卡片上的小图，本项目复用大图（缩放）
const PLANTS: Dictionary = {
    "sunflower": {
        "display_name": "向日葵",
        "cost": 50,
        "max_hp": 60,
        "cooldown": 7.5,
        "scene_path": "res://scenes/plants/Sunflower.tscn",
        "icon_path": "res://assets/plants/sunflower.svg",
    },
    "peashooter": {
        "display_name": "豌豆射手",
        "cost": 100,
        "max_hp": 60,
        "cooldown": 7.5,
        "scene_path": "res://scenes/plants/Peashooter.tscn",
        "icon_path": "res://assets/plants/peashooter.svg",
    },
    "wallnut": {
        "display_name": "坚果墙",
        "cost": 50,
        "max_hp": 400,
        "cooldown": 30.0,
        "scene_path": "res://scenes/plants/WallNut.tscn",
        "icon_path": "res://assets/plants/wallnut.svg",
    },
    "cherrybomb": {
        "display_name": "樱桃炸弹",
        "cost": 150,
        "max_hp": 1,
        "cooldown": 50.0,
        "scene_path": "res://scenes/plants/CherryBomb.tscn",
        "icon_path": "res://assets/plants/cherrybomb.svg",
    },
    "repeater": {
        "display_name": "双发射手",
        "cost": 200,
        "max_hp": 60,
        "cooldown": 7.5,
        "scene_path": "res://scenes/plants/Repeater.tscn",
        "icon_path": "res://assets/plants/repeater.svg",
    },
    "freezer": {
        "display_name": "寒冰射手",
        "cost": 175,
        "max_hp": 60,
        "cooldown": 7.5,
        "scene_path": "res://scenes/plants/Freezer.tscn",
        "icon_path": "res://assets/plants/freezer.svg",
    },
    "threepeater": {
        "display_name": "三线射手",
        "cost": 325,
        "max_hp": 80,
        "cooldown": 7.5,
        "scene_path": "res://scenes/plants/Threepeater.tscn",
        "icon_path": "res://assets/plants/threepeater.svg",
    },
    "potato_mine": {
        "display_name": "土豆地雷",
        "cost": 25,
        "max_hp": 60,
        "cooldown": 30.0,
        "scene_path": "res://scenes/plants/PotatoMine.tscn",
        "icon_path": "res://assets/plants/potato_mine.svg",
    },
}

# HUD 上从左到右展示的植物 ID 顺序
const HUD_PLANT_ORDER: Array[String] = [
    "sunflower", "peashooter", "wallnut", "cherrybomb", "repeater",
    "freezer", "threepeater", "potato_mine",
]

# 僵尸数据 ------------------------------------------------------------
# scene_path 在 wave 配置里通过 id 字符串引用
const ZOMBIES: Dictionary = {
    "basic": {
        "display_name": "普通僵尸",
        "max_hp": 100,
        "speed": 20.0,
        "damage_per_sec": 30.0,
        "scene_path": "res://scenes/zombies/BasicZombie.tscn",
    },
    "conehead": {
        "display_name": "路障僵尸",
        "max_hp": 280,
        "speed": 20.0,
        "damage_per_sec": 30.0,
        "scene_path": "res://scenes/zombies/ConeheadZombie.tscn",
    },
    "buckethead": {
        "display_name": "铁桶僵尸",
        "max_hp": 600,
        "speed": 18.0,
        "damage_per_sec": 30.0,
        "scene_path": "res://scenes/zombies/BucketheadZombie.tscn",
    },
    "football": {
        "display_name": "橄榄球僵尸",
        "max_hp": 1000,
        "speed": 26.0,
        "damage_per_sec": 50.0,
        "scene_path": "res://scenes/zombies/FootballZombie.tscn",
    },
    "newspaper": {
        "display_name": "读报僵尸",
        "max_hp": 100,                 # 自身血
        "shield_hp": 300,              # 报纸护盾血
        "speed": 18.0,
        "speed_after_shield": 32.0,    # 报纸被打掉后速度
        "damage_per_sec": 30.0,
        "scene_path": "res://scenes/zombies/NewspaperZombie.tscn",
    },
    "pole_vaulter": {
        "display_name": "撑杆僵尸",
        "max_hp": 200,
        "speed": 26.0,
        "damage_per_sec": 30.0,
        "scene_path": "res://scenes/zombies/PoleVaulter.tscn",
    },
    "flag": {
        "display_name": "旗帜僵尸",
        "max_hp": 70,
        "speed": 22.0,
        "damage_per_sec": 30.0,
        "scene_path": "res://scenes/zombies/FlagZombie.tscn",
    },
}

# 关卡配置 ------------------------------------------------------------
# 每个关卡：
#   id          : 短代码（主菜单 → 游戏 传递用）
#   name        : 显示名
#   description : 选关界面的描述
#   unlock      : 默认 true（后续可加锁）
#   waves       : 与原 WAVES 元素同结构：spawns / interval / rest
const LEVELS: Array = [
    {
        "id": "day1",
        "name": "白天 - 第1天",
        "description": "入门关：5 波普通僵尸，熟悉向日葵和豌豆射手。",
        "unlock": true,
        "waves": [
            {"spawns": ["basic", "basic", "basic"], "interval": 6.0, "rest": 10.0},
            {"spawns": ["basic", "basic", "basic", "basic", "conehead"], "interval": 5.0, "rest": 10.0},
            {"spawns": ["basic", "conehead", "basic", "conehead", "basic", "conehead"], "interval": 4.5, "rest": 10.0},
            {"spawns": ["basic", "conehead", "basic", "conehead", "basic", "buckethead", "conehead"], "interval": 4.0, "rest": 12.0},
            {"spawns": ["basic", "basic", "basic", "conehead", "conehead", "buckethead",
                        "basic", "conehead", "buckethead", "basic", "conehead", "basic"],
             "interval": 3.0, "rest": 0.0},
        ],
    },
    {
        "id": "day2",
        "name": "白天 - 第2天",
        "description": "新增撑杆跳跃、铁桶、高血路障。会需要坚果墙拖延。",
        "unlock": true,
        "waves": [
            {"spawns": ["basic", "flag", "basic"], "interval": 5.0, "rest": 10.0},
            {"spawns": ["conehead", "basic", "basic", "buckethead"], "interval": 4.5, "rest": 10.0},
            {"spawns": ["basic", "conehead", "buckethead", "basic", "basic", "conehead"], "interval": 4.0, "rest": 9.0},
            {"spawns": ["basic", "basic", "buckethead", "conehead", "basic", "pole_vaulter", "conehead"],
             "interval": 3.5, "rest": 9.0},
            {"spawns": ["conehead", "pole_vaulter", "basic", "buckethead", "conehead", "basic",
                        "buckethead", "pole_vaulter", "basic", "conehead"],
             "interval": 3.0, "rest": 0.0},
        ],
    },
    {
        "id": "day3",
        "name": "白天 - 第3天（终日）",
        "description": "全僵尸登场 + 读报 / 橄榄球精英。推荐提前摆出双发射手和寒冰射手。",
        "unlock": true,
        "waves": [
            {"spawns": ["basic", "flag", "conehead", "basic"], "interval": 4.0, "rest": 9.0},
            {"spawns": ["conehead", "newspaper", "basic", "basic", "buckethead", "basic"],
             "interval": 3.8, "rest": 9.0},
            {"spawns": ["basic", "pole_vaulter", "newspaper", "conehead", "football", "basic", "buckethead"],
             "interval": 3.5, "rest": 9.0},
            {"spawns": ["football", "conehead", "newspaper", "basic", "buckethead", "pole_vaulter",
                        "newspaper", "conehead", "football", "basic"],
             "interval": 3.0, "rest": 9.0},
            {"spawns": ["football", "pole_vaulter", "newspaper", "buckethead", "basic", "conehead",
                        "football", "newspaper", "pole_vaulter", "buckethead", "basic", "conehead",
                        "football", "newspaper", "buckethead", "conehead"],
             "interval": 2.5, "rest": 0.0},
        ],
    },
]

# 工具：根据 id 找关卡下标；找不到返回 -1
static func find_level_index(level_id: String) -> int:
    for i in LEVELS.size():
        if LEVELS[i].id == level_id:
            return i
    return -1

# 关卡常量 ------------------------------------------------------------
const GRID_COLS: int = 9
const GRID_ROWS: int = 5
const CELL_SIZE: int = 96

const LAWN_ORIGIN_X: int = 96       # 草坪左上角 x
const LAWN_ORIGIN_Y: int = 168      # 草坪左上角 y（HUD 96 + 上边距 72）

const HUD_HEIGHT: int = 96
const SCREEN_W: int = 1280
const SCREEN_H: int = 720

# 工具方法 ------------------------------------------------------------
# 把 (col, row) 转成草坪上格子中心的世界坐标
static func cell_to_world(col: int, row: int) -> Vector2:
    return Vector2(
        LAWN_ORIGIN_X + col * CELL_SIZE + CELL_SIZE / 2.0,
        LAWN_ORIGIN_Y + row * CELL_SIZE + CELL_SIZE / 2.0,
    )

# 把世界坐标反查回 (col, row)；越界返回 (-1, -1)
static func world_to_cell(pos: Vector2) -> Vector2i:
    var c := int((pos.x - LAWN_ORIGIN_X) / CELL_SIZE)
    var r := int((pos.y - LAWN_ORIGIN_Y) / CELL_SIZE)
    if c < 0 or c >= GRID_COLS or r < 0 or r >= GRID_ROWS:
        return Vector2i(-1, -1)
    return Vector2i(c, r)

# 取行的中心 y
static func row_to_y(row: int) -> float:
    return LAWN_ORIGIN_Y + row * CELL_SIZE + CELL_SIZE / 2.0
