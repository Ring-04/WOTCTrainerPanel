# WOTCTrainerPanel 0.5.2-test 实机验收清单（UI 生命周期与输入）

适用安装包：`WOTCTrainerPanel-0.5.3-test`（安装见 `docs/INSTALL-AND-TEST.zh-CN.md`）。

> **0.5.3-test 说明：** 相对 0.5.2-test 只改了 4 处界面标签的文案来源（硬编码英文 → 本地化键），没有改任何功能逻辑、数值写入、安全检查或禁用状态。因此本清单**整份继续有效**，直接用 0.5.3-test 的包跑即可。本清单文件名保留 `0.5.2` 是为了不改动已经发出去的编号。

本清单只覆盖**本轮改动**：战术层入口按钮的点击链、面板的宿主绑定与自动关闭、跳转类操作先关面板。
功能本身的逐项验收（资源 / 士兵 / 物品 / 战略 / 任务 / 危险 / 生成士兵）请继续用 `docs/ACCEPTANCE-0.5.1.zh-CN.md`，那份清单没有过期。
**Phase 1–5 的 GameState 功能逻辑本轮一行没改**，所以功能项不需要重测，但本清单的 U 级全部是**第一次实机**。

> 0.5.1-test 实机结果（本轮要修的两个问题）：
> 1. 战术层「修改器」按钮**已经可见**，但点击无反应；日志里 `Button clicked` 出现了 37 次，说明点击其实已经到达脚本，卡住的是点击之后的“打开面板”。
> 2. 战略层「立即完成科技」自动跳研究室后，修改器面板有概率残留，并且无法关闭（Esc 也无效）。
>
> 这两个问题被当作**同一组 UI 生命周期 / 输入问题**处理，不是两个临时补丁。

## 本轮改了什么

| 位置 | 改动 |
| --- | --- |
| 战术入口按钮 | 改用原版战术 HUD 可点击按钮的建法：`eUIButtonStyle_BUTTON_WHEN_MOUSE` + 点击委托（与 `UITacticalHUD_CommanderHUD` 一致）；按钮输入路径没有另写一套 |
| 战术入口的打开逻辑 | 不再要求“战术 HUD 此刻必须是最上层界面”，改用**按钮自己所属的 Screen** 作为宿主；打开前清掉遗留实例；每一步都打日志，不再静默 return |
| 面板基类 | 记录宿主 Screen；宿主失效或被打断就自动关闭；关闭是从 ScreenStack 真正出栈 |
| 新增全屏监听器 | 监听所有界面的 `OnInit` / `OnRemoved`：有别的界面被推到 Trainer 之上、或宿主界面被移除时，立即关闭 Trainer |
| 兜底轮询 | 面板每 0.5 秒检查一次自己在栈里的位置和宿主状态，覆盖掉“不触发任何界面信号”的跳转 |
| 跳转类操作 | 先关面板再调用原版流程（研究 / 试验场 / 设施 / 隐秘行动 / 任务重开 / 任务结束 / 完成全部目标） |

## 本轮**没有**改

- GameState 功能逻辑（Phase 1–5）：数值、士兵、物品、战略、任务目标、AI、结束任务的写入代码全部原样。
- 任何安全检查、二次确认、禁用项的禁用状态。
- 面板布局与文案。

## 测试准备

1. 备份存档目录 `...\My Games\XCOM2 War of the Chosen\XComGame\SaveData`。
2. 用独立测试档。建议另存为 `TRAINER-TEST`。
3. 启动参数不要带 `-allowconsole`。
4. 清空或记下 `Launch.log` 起点：`...\My Games\XCOM2 War of the Chosen\XComGame\Logs\Launch.log`；每次操作后搜 `[WOTCTrainer]`。
5. 准备一个**正在进行中的研究**（U6 需要），以及一场**可以随便打的战术任务**（U1–U4、U9 需要）。

风险分级：U 级全部是界面层操作，写入风险取决于你点了哪个功能按钮；U1–U9 只打开 / 关闭面板，**不写入**。

## U 级 —— UI 生命周期与输入

### U1 战术按钮：悬停有反馈
- 步骤：进入战术战斗，拿到士兵控制权 → 鼠标移到右上角「修改器」上（不用点）
- 预期：按钮有可见的悬停反馈（高亮 / 变化），鼠标图标不是“不可点”状态
- 日志：`[WOTCTrainer] Tactical button mouse enter`；移开出现 `Tactical button mouse leave`
- 失败判定：连 `mouse enter` 都没有 → 命中测试 / 层级问题，请附日志

### U2 战术按钮：点击能打开
- 步骤：点「修改器」
- 预期：战术修改器面板打开，标题为「修改器 | 战术」
- 日志（按顺序）：
  ```text
  [WOTCTrainer] Tactical button pressed
  [WOTCTrainer] Tactical button clicked: inited=yes enabled=yes visible=yes delegate=set
  [WOTCTrainer] Tactical panel requested
  [WOTCTrainer] Panel opened on UITacticalHUD (UIWOTCTrainerTactical)
  [WOTCTrainer] Tactical panel opened on UITacticalHUD
  ```
- 关键点：**在战术读取还没结束时就点也应该能打开**（旧版就是在这里被静默拒绝的）。如果此时最上层不是战术 HUD，日志里会多一行 `Tactical HUD is not the top screen (...)`，但面板**仍然应该打开**
- 如果卡住：把 `Tactical panel rejected: <原因>` 那一行附上

### U3 战术面板：能关闭
- 步骤：点面板里的「关闭」；再打开一次，按 Esc；再打开一次，用手柄 B（如可用）
- 预期：三种方式都能关掉，回到战术 HUD，可以继续正常操作游戏（点士兵、移动、射击）
- 日志：每次出现 `[WOTCTrainer] Trainer panel removed: UIWOTCTrainerTactical (close)`

### U4 战术面板：重复开关 5 次
- 步骤：连续「打开 → 关闭」5 次
- 预期：每次都正常打开、正常关闭；**不会**出现两个面板叠在一起；第 5 次仍然和第一次一样
- 日志：每次打开都有一组 `Tactical panel requested` + `Panel opened on ...`；如果出现 `Trainer panel removed: ... (reopening tactical trainer)`，说明上一次的实例被清理了（这是预期行为，不是错误）
- 反例检查：如果某次打开后按钮点不动、或面板关不掉，**立即停止后续验收**并保留日志

### U5 战略层：打开 → 关闭 连续 5 次
- 步骤：回到基地总览 → 连续「打开修改器 → 关闭」5 次
- 预期：每次都正常打开、正常关闭；地球扫描在打开时暂停、关闭后恢复；右上角始终只有**一个**「修改器」按钮
- 日志：每次打开 `Strategy panel opened on <ScreenClass>` + `Panel opened on <ScreenClass> (UIWOTCTrainer)`；每次关闭 `Trainer panel removed: UIWOTCTrainer (close)`

### U6 完成科技 → 跳研究室时，面板必须自动消失（0.5.1 的问题）
- 步骤：
  1. 战略层打开修改器 →「战略」标签 →「立即完成研究」→ 确认
  2. 观察游戏是否自动跳到研究室
- 预期：
  - 面板在跳转**之前或同时**消失，**不会**出现“面板还在但点不动”的状态；
  - 跳转后看到的是研究室的正常界面（不是被修改器压住的界面）
- 日志（按顺序）：
  ```text
  [WOTCTrainer] Auto-closing trainer before transition: Research
  [WOTCTrainer] Trainer panel removed: UIWOTCTrainerCampaign (vanilla transition: Research)
  [WOTCTrainer] Trainer panel removed: UIWOTCTrainer (vanilla transition: Research)
  [WOTCTrainer] Completing research after panel close: ok
  ```
  （如果原版流程是之后再推研究室界面，还会多一行 `Host screen lost focus: ...` —— 那只是兜底路径，同样算通过）
- 反例检查：如果面板还在并且 Esc 关不掉，请立刻截图并保留日志（这就是本轮要修的问题，仍复现说明没修好）

### U7 研究室里不得残留旧 Trainer 实例
- 步骤：在研究室里按 Esc / 关闭研究室，回到基地总览
- 预期：研究室内**看不到**任何修改器残留（标题、按钮、半透明残影都不应该出现）；回到基地总览后右上角只有一个「修改器」按钮
- 日志：不应出现新的 `Panel opened on`（说明没有意外重开）；不应出现 `ScriptWarning` / `Accessed None`

### U8 返回战略地图后重新打开正常
- 步骤：从研究室回到基地总览 → 到战略地图 → 打开修改器 → 关闭
- 预期：正常打开、正常关闭；面板读数（资源、队列）是最新的（研究已完成）
- 日志：`Strategy panel opened on UIStrategyMap`（或 `UIFacilityGrid`）

### U9 战术任务进入 / 退出后不得残留
- 步骤：
  1. 在战术战斗里打开修改器面板（**不关**）→ 直接结束任务（撤离或完成）
  2. 回到战略层 → 进入**下一场**战斗
  3. 看右上角按钮和面板
- 预期：
  - 上一场任务结束时，战术面板随战术界面一起消失；
  - 新任务里右上角只有一个「修改器」按钮（不会出现两个重叠的按钮，也不会出现上一场残留的面板）；
  - 新任务里点按钮能正常打开
- 日志：任务结束时如出现 `Host screen removed: UITacticalHUD`、`Trainer panel removed: ... (host screen removed: UITacticalHUD)` 属预期；新任务里应重新出现 `Trainer button created, waiting for flash init` → `Trainer button ready after N flash check(s)`
- 说明：如果任务结束的界面切换没有触发任何信号，兜底轮询（0.5 秒）会接手；两条路径都算通过，请在报告里注明实际看到的是哪一条

### U10 子页面与关闭：战略主面板 → 子页 → 返回
- 步骤：打开战略修改器 → 依次打开「战略」「装备」「危险功能」三个子页，每个都点「关闭」返回 → 再从子页里打开「兵营士兵编辑器」→ 关闭 → 最后关闭主面板
- 预期：每次最多只有一个 Trainer 面板；子页关闭后回到主面板并且可以继续点；主面板关闭后回到游戏；**不会**出现两个子页叠在一起或关不掉的中间态
- 日志：每次打开 `Panel opened on ...`，每次关闭 `Trainer panel removed: ... (close)`
- 反例检查：连续点两次「危险功能」（可能因为手抖双击）不应产生两个危险面板；如出现，请附日志

### U11 拒绝类操作不会误关面板（本轮改动的回归检查）
- 步骤：战术面板 →「任务」→「危险功能」→「按胜利结束任务…」→ 在**胜利条件未满足**时确认
- 预期：面板**不关闭**，面板内给出中文拒绝提示（需要先完成目标）
- 日志：`[WOTCTrainer] Operation rejected: CompleteFirst`，且**不应**出现 `Auto-closing trainer before transition`
- 说明：这是刻意设计——只在真正要交给原版流程时才关面板

### U12 全局：日志里没有脚本错误
- 步骤：把上面所有操作做完后，检查 `Launch.log`
- 预期：`[WOTCTrainer]` 行之外**没有**新增的 `Error`、`Accessed None`、`ScriptWarning`、`Assertion failed`
- 特别检查：不应出现 `Tactical panel rejected` 里除已知情况（不是单机 WOTC 战斗 / 拿不到宿主）以外的原因

## 通过标准

U 级算通过，必须同时满足：

1. U1–U12 的“预期”全部出现，尤其是 U6 与 U9 的残留检查；
2. 每一项都完成清单里要求的连续次数（U4 / U5 各 5 次）；
3. 出现“面板可见但点不动 / 关不掉”的任何一次，都算**不通过**；
4. `Launch.log` 里没有新增的脚本错误。

任何一条不满足，把该项记下来，**不要进入 Phase 6**，按下面格式反馈。

## 反馈模板

```text
编号：U6
操作：战略层 → 战略 → 立即完成研究 → 确认
预期：面板在跳转前或跳转时消失
实际：面板仍在，Esc 无效
日志：粘贴 [WOTCTrainer] 附近 30 行
截图：1 张（跳转后的画面）
其他 Mod：<列表>
```

有了这个格式可以直接定位到函数，不需要你在游戏里反复试。
