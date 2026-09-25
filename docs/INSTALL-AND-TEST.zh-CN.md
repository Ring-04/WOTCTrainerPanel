# 0.5.0-test 安装与实机测试（Phase 1–5）

本文件对应安装包 `WOTCTrainerPanel-0.5.0-test`。

**当前状态：已编译通过（0 error），但尚未在游戏内做过任何验证。**
本文中的“预期结果”全部是设计意图，不是已经取得的实测结果。逐项验收请用 `docs/ACCEPTANCE-0.5.0.zh-CN.md` 的清单。

## 一、包内容

解压 `WOTCTrainerPanel-0.5.0-test.zip` 后：

```text
WOTCTrainerPanel-0.5.0-test/          <- 把这个目录当作 Mod 目录加入启动器
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

1. 把 `WOTCTrainerPanel-0.5.0-test` 整个目录解压到游戏目录以外的位置。
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
[WOTCTrainer] Tactical entry initialized      # 战术层入口按钮创建
[WOTCTrainer] Panel initialized               # 战略层修改器面板打开
[WOTCTrainer] Campaign panel initialized      # 战略（战役）面板打开
[WOTCTrainer] Supplies: 125 -> 625            # 资源
[WOTCTrainer] Added <职业> <姓名> ObjectID=... Rank=...
[WOTCTrainer] Barracks: <原> -> <新>
[WOTCTrainer] Healed <姓名> ObjectID=... HP: <原> -> <新>
[WOTCTrainer] Operation rejected: <原因代码>   # 被拒绝的操作
```

`Supplies`、`Added`、`Barracks`、`Healed`、`Operation rejected` 这几行是**格式示例，不是已经取得的实测结果**。每条预期日志见验收清单中对应项。

## 六、反馈格式

请提供：验收项编号、操作前后数值 / 状态、是否成功、截图（界面或显示问题必附）、本次 `Launch.log`、本次启用的其他 Mod。出现提交后校验不一致时先记录结果，不要重复点击造成二次增加。

## 七、编译与验证状态

- 官方 WOTC SDK 编译：`Success - 0 error(s), 8 warning(s)`；其中 `WOTCTrainerPanel` 源码 **0 warning**，8 个警告来自原版 SDK 的 DLC 内容。
- 脚本包哈希：见 `PACKAGE.json`。
- **本次没有启动游戏、没有做任何实机操作。编译通过不等于功能正常。**
- 降级、已晋升士兵转职、复活、传送、同种子重开、强制撤离按设计保持禁用并在界面上说明原因。

