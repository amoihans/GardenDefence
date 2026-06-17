# 运行 & 打包成 EXE

## 0. 一句话总结

```
拿到 Godot.exe → 双击 → 导入 project.godot → 按 F5 玩
              → 项目 → 导出 → 添加 Windows Desktop → 下载导出模板 → 导出 → 拿到 .exe
```

下面一步一步来。

---

## 1. 准备：下载 Godot

去官网 **https://godotengine.org/download/windows/**

下载 **Godot Engine 4.x for Windows · Standard 64‑bit**（**不是** Mono / .NET 版本，本项目用 GDScript）。

得到一个 `Godot_v4.x-stable_win64.exe`（约 70MB）。**这就是引擎全部**，不需要安装。建议放到一个固定的目录，比如：

```
D:\tools\godot\Godot_v4.x.exe
```

---

## 2. 第一次打开项目

1. 双击 `Godot_v4.x.exe`，打开项目管理器
2. 点 **导入(Import)** → 浏览到 `D:\hans\godot\project.godot` → **导入并编辑**
3. Godot 首次打开会自动**导入所有 SVG 资源**，下方进度条跑完即可（约 5~10 秒）

> 第一次进入后，Godot 会在每个 SVG 旁边生成 `.import` 文件。这是 Godot 的资源缓存，**别手动删，也别加进 Git 提交（已 .gitignore）**。

---

## 3. 在编辑器里运行

1. 顶部 ▶ 运行项目（或 F5）→ 主菜单出现
2. 点「开始游戏」→ 进入战斗
3. 操作：
   - 左键收阳光
   - 数字键 1~5 选植物，6 选铲子，或鼠标点 HUD 卡片
   - 左键空格子 → 种植
   - 右键 / Esc 取消选择
   - Space 暂停（再按一次……见下方"已知小问题"）

### 调试时的几个常用快捷键

| 键 | 作用 |
|---|---|
| **F5** | 运行项目主场景 |
| **F6** | 运行当前打开的场景（调试单个植物 / 僵尸时很顺手） |
| **F7** | 暂停场景 |
| **F8** | 停止运行 |
| **F9** | 当前行加断点 |
| **F12 (运行时)** | 切换全屏 |

底部「输出」面板显示 `print()`，「调试器」面板显示报错和断点变量。

---

## 4. 命令行运行（无编辑器）

如果你想在没开 Godot 编辑器的情况下直接跑（比如自动化测试）：

```bash
# 直接运行项目
"D:\tools\godot\Godot_v4.x.exe" --path "D:\hans\godot"

# 全屏
"D:\tools\godot\Godot_v4.x.exe" --path "D:\hans\godot" --fullscreen
```

---

## 5. 导出成独立 EXE

### 5.1 下载导出模板（一次性）

EXE 打包需要"导出模板"——这是 Godot 引擎本体，会和你的项目一起打包。

1. 打开任意项目 → 顶部菜单 **编辑器(Editor)** → **管理导出模板(Manage Export Templates)**
2. 弹窗里点 **下载并安装(Download and Install)**
3. 等待下载完成（约 700MB，包含所有平台模板）

> 没有网也可以从 godotengine.org 下 `Godot_v4.x_export_templates.tpz` 离线包，再用同一个弹窗里的「从文件安装」选。

### 5.2 配置 Windows 导出预设

1. 顶部菜单 **项目(Project)** → **导出(Export)**
2. 左侧点 **添加(Add)** → 选 **Windows Desktop**
3. 默认参数已经够用，可以微调：
   - **二进制格式 → 嵌入 PCK**：勾上，把游戏数据嵌入 exe，单文件分发
   - **应用程序图标**：可选，指定一个 `.ico` 文件让 exe 有图标
4. 右上「文件名」处验证一下输出路径（建议改成 `build/garden_defense.exe`）

### 5.3 一键导出

1. 点底部 **导出项目(Export Project)** 按钮
2. 选输出位置 → 等待 5~30 秒
3. 拿到：
   - `garden_defense.exe`（可单文件运行）
   - `garden_defense.pck`（若没勾"嵌入 PCK"则单独的数据文件）

双击 exe 就能玩，**目标机器不需要装 Godot**。

### 5.4 想分发给朋友

把 exe（必要时连同 pck）放进一个 zip：

```
garden_defense_v1.0.zip
└── garden_defense.exe
```

发出去即可。Windows 7/10/11 都能跑（Godot 4 最低支持 Windows 7）。

---

## 6. 命令行一键导出（CI / 自动化）

```bash
# 假设已经配置好名为 "Windows Desktop" 的导出预设
"D:\tools\godot\Godot_v4.x.exe" --headless --path "D:\hans\godot" \
    --export-release "Windows Desktop" "D:\hans\godot\build\garden_defense.exe"
```

- `--headless`：不打开编辑器窗口
- `--export-release`：用 release 模板（更小、无调试符号）
- `--export-debug`：用 debug 模板（出问题时控制台能看堆栈）

---

## 7. 想做更多平台？

| 平台 | 操作 |
|---|---|
| **Linux** | 导出预设里加 "Linux/X11" → 出 .x86_64 二进制 |
| **macOS** | 加 "macOS" → 出 .app（在 macOS 上签名才能在别人 Mac 跑） |
| **Web (HTML5)** | 加 "Web" → 出一个文件夹，扔进任意静态服务器（GitHub Pages 也行） |
| **Android** | 装 Android SDK + JDK，配置一次即可 |

每个平台的具体细节看 Godot 官方文档 `docs.godotengine.org → Export`。

---

## 8. 常见问题

### Q1. 打开项目报「缺失资源」/ 红色叹号
**A**：通常是 .import 没生成完。关闭项目重新打开一次，或菜单 **项目 → 重新加载当前项目**。

### Q2. 导出时报「未找到导出模板」
**A**：先做第 5.1 步「下载并安装导出模板」。

### Q3. 中文字符显示成方块
**A**：默认字体支持中文。若发现方块，去 **项目设置 → GUI → Theme → Custom Font** 指定一个中文 ttf（如 `Noto Sans CJK`、`微软雅黑 msyh.ttc`）。本项目用的是引擎自带默认字体，覆盖了常用中文字符。

### Q4. 打包出来的 exe 被杀软误报
**A**：Godot 用 PCK 文件嵌入数据，一些杀软启发式扫描会误报。可选方案：
- 给 exe 签名（个人开发者也可申请代码签名证书）
- 或换成"非嵌入"模式（exe + pck 两个文件）

### Q5. 想缩小 exe 体积
**A**：编辑器里 **项目设置 → 高级 → Application → Boot Splash**、**Rendering → ProgressMonitor** 等开关；
更激进的方式是去 Godot 官网下载 **自定义构建版** 或自行编译"去掉 3D / 物理"的精简引擎，导出模板能从 ~50MB 减到 ~10MB。

### Q6. Space 不能取消暂停？
**A**：在主场景中 Space 按下 → 暂停，再按 Space 是被暂停的 Game 节点接收，所以无效。**点 HUD 右上角 [暂停] 按钮** 可以取消（HUD 设了 `PROCESS_MODE_ALWAYS`）。后续要修复：把 pause 输入处理挪到 HUD.gd 里。

---

## 9. 推荐的目录与版本管理

如果用 Git，把这些加进 `.gitignore`：

```
# Godot 4 specific
.godot/                # 编辑器缓存
*.import.bak
build/                 # 导出产物

# IDE
.vscode/
.idea/
```

`.import` 文件**要提交**（队友拉下来不需要重新导入）。

---

## 10. 验收清单

完成下面 6 步，证明你已经会用本项目：

- [ ] 双击 Godot.exe → 导入 project.godot 成功
- [ ] F5 看到主菜单
- [ ] 进入战斗能种向日葵、收阳光、种豌豆射手击杀僵尸
- [ ] 跑通第 5 波，看到胜利结算
- [ ] 改一个 `PlantDB.PLANTS["peashooter"].cost`、再跑确认 HUD 显示变化
- [ ] 导出一个 Windows EXE 双击能开 → 同样玩到通关

通过即出师。下一步可以读 `03-IMPLEMENTATION.md` 改源码、加植物。
