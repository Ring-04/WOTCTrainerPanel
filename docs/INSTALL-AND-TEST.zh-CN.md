# 0.5.3-test 安装与实机测试（Phase 1–5 + UI 生命周期与输入修复）

本文件对应安装包 `WOTCTrainerPanel-0.5.3-test`。

**当前状态：**
- 0.5.0-test 首轮实机：**战略层**已测项目全部正常（中文 UI、战略层「修改器」入口、当时测到的各功能）；**战术层入口按钮没有出现**，战术 / 任务 / 危险功能因此都没能进入。
- 0.5.1-test 第二轮实机：战术层「修改器」按钮**已经可见**，但**点击无反应**；另外发现战略层「立即完成科技」跳转研究室后，修改器面板有概率**残留且无法关闭**。
- 0.5.2-test 把上面两件事当作**同一组 UI 生命周期 / 输入问题**处理：战术入口按钮按原版战术 HUD 按钮的方式重建（PC 按钮样式 + 点击委托），并给全部 Trainer 面板加了统一的生命周期规则（宿主 Screen 绑定、离开宿主即自动关闭、新开面板前清理旧实例、关闭必须真正出栈）。**GameState 功能逻辑（Phase 1–5）本轮没有改动。**
- **0.5.2-test 的修复尚未实机验证。** 本文中的“预期结果”仍然是设计意图，不是已经取得的实测结果。
- 0.5.3-test 相对 0.5.2-test **只改了界面文案的来源**：4 处硬编码英文标签（士兵血量、士兵编号、物品等级、任务里的 `XCOM:`）改为引用已本地化键，其中新增 2 个键（`LabelID`「编号」、`LabelTier`「等级」）。**功能逻辑、数值写入、安全检查、禁用项全部没有改动**，因此 0.5.2-test 的验收清单与本文档其余内容继续有效。

验收清单：
- 本轮（UI 生命周期与输入）：`docs/ACCEPTANCE-0.5.2.zh-CN.md`
- 功能逐项（Phase 1–5，仍然有效）：`docs/ACCEPTANCE-0.5.1.zh-CN.md`

## 一、包内容

解压 `WOTCTrainerPanel-0.5.3-test.zip` 后：

```text
WOTCTrainerPanel-0.5.3-test/          <- 把这个目录当作 Mod 目录加入启动器
├─ README.zh-CN.md                    <- 本文件
├─ PACKAGE.json                       <- 打包清单：文件、大小、SHA256、编译摘要
└─ WOTCTrainerPanel/
   ├─ WOTCTrainerPanel.XComMod
   ├─ Config/XComEditor.ini
   ├─ Config/XComEngine.ini
   ├─ Config/XComGame.ini
   ├─ Localization/WOTCTrainerPanel.INT
   ├─ Localization/WOTCTrainerPanel.CHS
   ├─ Localization/WOTCTrainerPanel.CHN
   └─ Script/WOTCTrainerPanel.u
```

`PACKAGE.json` 记录了每个文件的 SHA256 和脚本包哈希。想确认“装的就是这次编译产物”时，可对比 `Script/WOTCTrainerPanel.u` 的哈希。

## 二、安装

本项目不修改 Steam 文件、不改 `XCom2.exe`、不注入 DLL、不需要 `-allowconsole`，因此 Mod 目录可以留在游戏目录之外。

1. 把 `WOTCTrainerPanel-0.5.3-test` 整个目录解压到游戏目录以外的位置。
2. 若使用 AML（Alternative Mod Launcher）：Settings → **Mod Directories** 加入上面那个目录，再 **File → Search for new mods**。上述菜单依据 AML 官方说明；用其他启动器就使用它自己的本地 Mod 目录功能。
3. 只启用一份 **WOTC Trainer Panel**。启动 **XCOM 2: War of the Chosen**（需要 XPack，`WOTCTrainerPanel.XComMod` 中 `RequiresXPACK=true`）。
4. 游戏语言保持简体中文即可，本 Mod 不要求切英文。
5. **本次启动不要带 `-allowconsole`**，以符合“不依赖控制台”的验收前提。
6. 本包没有安装程序，也不会替你改游戏配置；卸载就是取消勾选并删掉该目录。

## 三、入口按钮

两个入口都叫 **修改器**，都是右上角按钮（170×42）。

| 层面 | 出现位置 | 打开条件 |
| --- | --- | --- |
| 战略层 | `UIAvengerHUD` 右上角，距右边缘 35、距上边缘 155 | 当前最上层界面必须是**基地设施总览**（`UIFacilityGrid`）或**战略地图/地球扫描**（`UIStrategyMap`）。其他弹窗页面上会拒绝打开，先返回基地总览 |
| 战术层 | `UITacticalHUD` 右上角，距右边缘 35、距上边缘 160 | 当前最上层界面是 `UITacticalHUD`，且战术 GameState 已就绪 |

打开战略面板会暂停地球扫描（`Pause()`）。面板内 `关闭` 按钮或 Esc / 手柄 B 返回上一层。

**战术层入口的说明（0.5.1-test 修复点）：** 战术 HUD 是在战术读取画面还没结束时就被创建的，在那一瞬间创建的 Flash 控件可能拿不到初始化回调，按钮就会“创建了但不显示”。现在战术入口改为：

- 用不播放淡入动画的 `WOTCTrainerButton`（原先用的普通按钮会从透明 0 淡入，也可能卡在透明状态）。
- 创建后每 1 秒自检一次 Flash 初始化状态，最多 6 次；期间持续把锚点 / 位置 / 尺寸 / 可见性 / 透明度和文字重新推一次到 Flash。
- 如果第 3 次自检时仍未初始化，会再向 Flash 请求一次该子控件；6 次后放弃并在日志中写明 `flash init FAILED`。

**战术层入口的点击（0.5.2-test 修复点）：** 0.5.1 的实机日志显示**点击其实已经到达 UnrealScript**（`Button clicked` 打了 37 次），失败的是点击之后的“打开面板”这一步。所以本轮不再改按钮的输入路径，而是：

- 按钮改用原版战术 HUD 可点击按钮的建法（`eUIButtonStyle_BUTTON_WHEN_MOUSE` + 点击委托），与原版 `UITacticalHUD_CommanderHUD` 一致，悬停即有点击反馈。
- 打开面板不再依赖“战术 HUD 此刻必须是最上层界面”，而是用**按钮自己所属的 Screen** 作为宿主；面板推入宿主所在的那个 movie / ScreenStack。
- 打开前先清掉遗留的 Trainer 实例，并打日志：`Tactical panel requested` / `Tactical panel opened on <ScreenClass>`；被拒绝时会写明原因（不再是静默 return）。

## 三点五、面板生命周期规则（0.5.2-test 新增）

所有 Trainer 面板（战略主面板、战略子页、战术面板、任务面板、危险面板、士兵编辑器）现在共用同一套规则：

| 规则 | 表现 |
| --- | --- |
| 同一时间最多一个 Trainer 面板族 | 打开新的之前先清理旧实例（日志：`Trainer panel removed: ... (reopening ...)`） |
| 面板记录宿主 Screen | 打开时记录，日志：`Panel opened on <ScreenClass>` |
| 宿主被其他界面盖住 / 被移除（= 发生了界面跳转） | 自动关闭该面板并清空宿主引用，日志：`Host screen lost focus: <Class>` / `Host screen removed: <Class>` |
| 会触发界面跳转的操作 | **先关闭面板，再走原版流程**，日志：`Auto-closing trainer before transition: <action>`，随后 `Completing ... after panel close: ok` |
| 关闭 | 真正从 ScreenStack 移除（不是隐藏），日志：`Trainer panel removed: <Class> (close)` |

会被“先关面板再执行”的操作：

- 战略面板：`立即完成研究`、`立即完成试验场`、`立即完成设施建造`、`立即完成隐秘行动`
- 任务面板：`重开当前任务`
- 任务危险面板：`完成全部未完成目标记录`、`按胜利结束任务`、`按失败结束任务`

因此这些操作之后**面板会消失**（这是刻意的：原版流程会自己跳界面），结果只写进日志。拒绝类结果（例如“按胜利结束任务”在胜利条件未满足时）在这一步之前就会给出中文提示，不会白白关掉面板。

**不会**关面板的操作（面板原地保留，方便连续操作）：资源 / 人员 / 物品 / 治疗 / 属性等写入类操作，以及 `完成选中目标记录`、`跳过当前 AI 回合`、`禁用 / 恢复 AI 行动规划`。

界面跳转的判定基准是**原版 ScreenStack 本身**（宿主被覆盖 / 被移除），不是硬编码的界面名，因此战略地图 → 研究室、工程室 → 试验场、战术过渡等切换都适用。

## 四、面板地图

战略层“修改器”面板顶部有 8 个标签：

| 标签 | 行为 |
| --- | --- |
| 资源 | 本页：六项资源 |
| 人员 | 本页：工程师 / 科学家 |
| 士兵 | 本页：全员治疗 + 士兵编辑器入口 |
| 战略 | 打开战略面板 |
| 装备 | 打开物品面板 |
| 战术 | **禁用**（提示“当前版本尚未实现”）。战术面板改从战术层入口进入 |
| 任务 | **禁用**。任务面板改从战术层入口进入 |
| 危险功能 | 打开危险功能面板 |

各页面按钮一览（引号内为界面上的实际中文）：

- **资源页**：补给 / 情报 / 外星合金 / 水晶 / 核心 / XCOM 能力点，每项有 `+10 +50 +100 +500 +1000` 与 `自定义数值`（输入新总数，0–2147483647）。
- **人员页**：`+1 工程师`、`+1 科学家`、`生成士兵…`（跳危险功能面板）。
- **士兵页**：`治疗所有士兵`（完成兵营中合法的治疗项目）、`兵营士兵编辑器`。
- **战略面板**：化身计划数值与 `-1 -2 -5 清空化身进度`；`复仇者能力` 一节有 `+10 +50 +100` 电力与 `+1 +2 +5` 抵抗组织联系人容量；`队列中的项目` 一节有 `立即完成研究`、`立即完成试验场`、`立即完成设施建造`、`退还建造花费`、`立即完成隐秘行动`；`小队恢复` 一节有 `治疗全部士兵`、`恢复意志 / 消除疲劳`。
- **物品面板**：`搜索`（物品名 / 内部名）、分类循环、`显示剧情物品`开关、每页 12 行、`+1 +5 +10 +50 +100 +500`、`自定义数量`、`加入仓库`。
- **士兵编辑器**：每页 8 名、9 个字段（生命 / 命中 / 移动 / 意志 / 侵入 / 闪避 / 防御 / 个人 AP / 经验 XP），每个字段 `+1 +5 +10 -1 -5 -10`；前 7 个字段另有 `模板默认值`，AP 与 XP 有 `自定义数值`；底部 `完全治疗 / 清除伤势`、`恢复意志 / 解除疲劳`、`移除负面特质`、`军衔 / 新兵职业…`。
- **危险功能面板**：职业 / 军衔 / 数量（1–20）循环选择，`生成士兵…`，新兵晋升职业、目标军衔、`逐级晋升…`；`降级（禁用）`、`复活阵亡士兵（禁用）`。
- **战术面板**：12 个开关（全队无敌、选中士兵无敌、无限行动、无限移动、射击不结束回合、无限弹药、无需装填、无技能冷却、无限技能 / 物品充能、100% 命中、100% 暴击、一击必杀），当前单位信息，5 个动作（恢复全部生命 / +1 行动点 / +1 移动行动点 / 装填主武器 / 重置技能冷却）；`传送（禁用）`、`复活（禁用）`；标签 `任务` 与 `危险功能` 打开对应面板。
- **任务面板**：左侧为任务内部记录（每页 7 条，`[X]` 已完成），右侧为 HUD 本地化目标列表与扫描 / 诊断信息；`<` `>` 翻页、`刷新任务目标显示`、`完成选中目标记录…`、`跳过当前 AI 回合…`、`重开当前任务…`、`危险功能`、`禁用 AI 行动规划…`、`恢复 AI 行动规划…`。
- **任务危险面板**：`完成全部未完成目标记录…`、`按胜利结束任务…`、`同种子重开（禁用）`、`按失败结束任务…`、`强制全队撤离（禁用）`。

## 五、日志

日志位置：

```text
%USERPROFILE%\Documents\My Games\XCOM2 War of the Chosen\XComGame\Logs\Launch.log
```

每次操作都会写 `[WOTCTrainer]` 行，格式为 `旧值 -> 新值`。常用关键字：

```text
[WOTCTrainer] Strategy entry initialized      # 战略层入口按钮创建
[WOTCTrainer] Panel initialized               # 战略层修改器面板打开
[WOTCTrainer] Campaign panel initialized      # 战略（战役）面板打开
[WOTCTrainer] Supplies: 125 -> 625            # 资源
[WOTCTrainer] Added <职业> <姓名> ObjectID=... Rank=...
[WOTCTrainer] Barracks: <原> -> <新>
[WOTCTrainer] Healed <姓名> ObjectID=... HP: <原> -> <新>
[WOTCTrainer] Operation rejected: <原因代码>   # 被拒绝的操作
```

战术层入口（一次进入战斗按顺序应当看到）：

```text
[WOTCTrainer] Tactical listener loaded: screen=...      # 监听器被调用，并写明收到的界面类名
[WOTCTrainer] Tactical HUD detected: ...                # 收到的确实是 UITacticalHUD
[WOTCTrainer] Trainer button created, waiting for flash init
[WOTCTrainer] Trainer button spawned: MCPath=... inited # Flash 回调到位
[WOTCTrainer] Trainer button ready after N flash check(s)
```

点击「修改器」时的**点击链**日志（0.5.2-test 新增，用来判断卡在哪一环）：

```text
[WOTCTrainer] Tactical button mouse enter               # 鼠标命中测试通过（悬停）
[WOTCTrainer] Tactical button pressed                   # 按下
[WOTCTrainer] Tactical button clicked: inited=yes enabled=yes visible=yes delegate=set
[WOTCTrainer] Tactical panel requested                  # 点击已到达打开逻辑
[WOTCTrainer] Tactical panel opened on <ScreenClass>     # 面板打开成功
```

如果只有 `mouse enter` 没有 `pressed`：命中测试 / 层级问题；有 `pressed` 没有 `clicked`：按钮状态或委托问题；有 `clicked` 没有 `opened`：打开逻辑被拒绝，紧跟的 `Tactical panel rejected: <原因>` 会写明原因。

面板生命周期日志（0.5.2-test 新增）：

```text
[WOTCTrainer] Panel opened on <ScreenClass> (<面板类名>)            # 每次打开面板
[WOTCTrainer] Host screen lost focus: <ScreenClass>                 # 宿主被其他界面盖住
[WOTCTrainer] Host screen removed: <ScreenClass>                    # 宿主界面被移除
[WOTCTrainer] Auto-closing trainer before transition: <action>      # 跳转类操作：先关面板
[WOTCTrainer] Completing <action> after panel close: ok / rejected <原因代码>
[WOTCTrainer] Trainer panel removed: <面板类名> (<原因>)              # 面板真正出栈
[WOTCTrainer] Strategy panel opened on <ScreenClass>                # 战略层入口打开
```

如果按钮仍然没出现，请把这几行一并附上，它们直接指出卡在哪一步：

```text
[WOTCTrainer] Tactical HUD not detected: listener screen is <类名>   # ScreenClass 不匹配
[WOTCTrainer] Tactical entry unavailable (not a single player WOTC battle)
[WOTCTrainer] Tactical entry already present: not-inited
[WOTCTrainer] Trainer button flash not inited yet (check N)
[WOTCTrainer] Trainer button re-requesting flash movie clip
[WOTCTrainer] Trainer button flash init FAILED
```

`Supplies`、`Added`、`Barracks`、`Healed`、`Operation rejected` 这几行是**格式示例，不是已经取得的实测结果**。每条预期日志见验收清单中对应项。

## 六、反馈格式

请提供：验收项编号、操作前后数值 / 状态、是否成功、截图（界面或显示问题必附）、本次 `Launch.log`、本次启用的其他 Mod。出现提交后校验不一致时先记录结果，不要重复点击造成二次增加。

## 七、编译与验证状态

- 官方 WOTC SDK 编译（0.5.3-test）：`Success - 0 error(s), 8 warning(s)`；其中 `WOTCTrainerPanel` 源码 **0 warning**，8 个警告来自原版 SDK 的 DLC 内容。
- 本地化检查（0.5.3-test）：`missing = 0 / extra = 0 / 硬编码界面标签 = 0`；INT / CHN / CHS 各 258 条，键与声明顺序一致，UTF-16LE + BOM，CRLF。
- 界面文案变化（仅这 4 处）：`HP` → `生命`（复用士兵字段键）、`ID` → `编号`、`Tier` → `等级`、`XCOM: ` → `XCOM` + 分隔符（复用原键，INT 表现不变）。
- 脚本包哈希：见 `PACKAGE.json`。
- **0.5.3-test 没有启动游戏、没有做任何实机操作。编译通过不等于功能正常。** 0.5.2-test 的修复是否生效，要看战术层入口的点击链日志（`clicked` → `requested` → `opened`）和面板生命周期日志。
- 降级、已晋升士兵转职、复活、传送、同种子重开、强制撤离按设计保持禁用并在界面上说明原因。

