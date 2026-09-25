# Phase 4 开发与验证记录

状态：任务控制与危险功能页已实现并编译；待用户实机验收。

## 入口与面板

- 战术面板内新增两个入口按钮（ActionID 806 / 807），分别打开任务控制面板和危险功能页；标签页 6、7 由禁用改为可用。
- 任务控制面板：左列为该任务真实的目标记录，右列为游戏左上角使用的本地化 HUD 目标行，下面是只读诊断。
- 危险功能页：一次完成全部未完成记录、胜利结束、失败结束，以及两个明确禁用的按钮（同种子重启、强制撤离）。

## 目标浏览

- 左列直接读 `BattleData.MapData.ActiveMission.MissionObjectives`，显示内部 `ObjectiveName`、序号、完成标记、`tactical/strategy/triad` 用途，以及成功战利品表数量。
- 右列读 `XComGameState_ObjectivesList.ObjectiveDisplayInfos` 的 `DisplayLabel` 与完成/失败标记。
- SDK 没有把这两组数据对应起来的可靠字段：`MissionObjectiveDefinition` 不含本地化文本，`ObjectiveDisplayInfo` 不含 ObjectiveName，HUD 文本由叙事模板按任务类型手工连线。因此面板并列显示两个列表，不假设 UI 第 N 行等于记录第 N 项，由玩家对照后选择要完成的记录。
- 目标记录超过 7 条时可用 `<` `>` 翻页；刷新按钮会重读两份数据，并请求战术 HUD 刷新它自己的目标列表。

## 操作语义

- **完成选中记录 / 完成全部未完成记录**：`XComGameStateContext_ChangeContainer` + `ModifyStateObject` + `BattleData.CompleteObjective` + `SubmitGameState`，提交后重新读取未完成集合来确认这些记录确实不再出现，再做一次 `Remaining.Find` 校验。已完成的记录不能重复完成，选中项在校验不通过时报陈旧值错误。
- **手动完成只改任务记录本身**，不会补跑 Kismet 里由「目标完成」事件驱动的剧情脚本，也不会替换 Destroy Relay 这类已经发生的事件结果。
- **胜利结束**：先镜像 `SetVictoriousPlayer` 判定该任务是否会记为成功；不满足时直接拒绝并列出未完成的战术/战略目标，不做「只把 UI 写成胜利」。满足后由原版 `X2TacticalGameRuleset.EndBattle` 结算。
- **失败结束**：同样走 `EndBattle`，由游戏自身结算失败流程。
- **跳过 AI 回合**：仅在当前回合确实属于 AI 队时，提交原版 `eGameRule_SkipTurn` context（带 `PlayerRef`）；有潜在状态提交或战术已结束时拒绝。
- **AI 卡死修复 / 恢复**：写 `XGAIPlayer.m_bSkipAI`，也就是原版 `SkipAI` 控制台命令和 `SeqAct_SkipAI` 节点使用的同一开关。诊断行常驻显示 Alien 与 Lost 当前的开关状态，便于发现忘记恢复的情况。
- **重启任务**：沿用原版入口，先 `RestoreNarrativeCounters` 再 `RestartLevel`；教程与铁人模式拒绝。

## 明确禁用与限制

- **同种子重启保持禁用**：原版 `RestartLevelWithSameSeed` 依赖 `native exec function SetSeedOverride`，没有可审核实现，缺它无法证明重启复用了同一种子。面板逐字说明原因，不提供近似实现。
- **强制撤离保持禁用**，标注为不安全。
- **清扫结算**：只有全部战术目标完成，游戏才会回收阵亡遗体并清扫战利品（`X2TacticalGameRuleset.uc:1984-2003`）。Destroy Relay 被 Lost 摧毁、Sweep 没有结算时，玩家会丢遗体与战利品，这正是本面板要暴露的情况；面板会提示当前是否有未完成的战术目标。
- **AI 跳过是瞬态状态**：不进 GameState、不存档，读档后回到关闭；它不是「修复所有 AI 卡住」，有潜在提交时直接拒绝。
- 战术回血、复活、传送不在本阶段范围内；不可用项保持禁用。

## 编译结果

官方 WOTC SDK 编译：0 错误；8 个原版 SDK DLC 内容警告；WOTCTrainerPanel 源码 0 警告。编译通过不等于游戏内验证通过。

## 统一实机验证清单（尚无实机证据）

1. 入口与显示：战术面板内两个新入口只出现一份；任务控制面板左右两列在中文下不乱码；目标多于 7 条时可翻页。
2. 对照真实状态：用此前 Destroy Relay 被 Lost 摧毁、Sweep 未结算的存档，核对左列哪条记录未完成、右列 HUD 显示什么，确认能从中选出真正需要完成的那条。
3. 完成单条：确认框显示原值 → 新值；完成后左列该条变为已完成，HUD 刷新，日志出现 `Objective <名字>: incomplete -> completed`；重复完成应被拒绝。
4. 完成全部：记录数量变化正确；完成后核实战利品与阵亡遗体是否在本任务结算时回收。
5. 胜负结束：成功条件未满足时点「胜利结束」应被拒绝并列出阻塞目标；完成后再执行，确认战役结算界面与实际记录一致；失败结束同样核对结算结果。
6. 跳过 AI：AI 回合点「跳过 AI 回合」，确认 AI 回合立即结束且不产生多余提交；在己方回合点击应被拒绝。
7. AI 卡死：记录当前 Alien/Lost 开关状态，遇到 AI 停顿时启用修复，确认 AI 回合被跳过；用恢复按钮回到关闭，并核对诊断行状态；读档后确认开关回到关闭。
8. 重启任务：非教程、非铁人任务中执行，确认叙事计数器被恢复且任务从头开始；教程/铁人下应被拒绝。
9. 存读档：完成目标、结束任务前分别另存测试档；读回后核对目标完成状态、任务状态与部队状态一致。
10. 日志：收集本次 Launch.log 全部 `[WOTCTrainer]` 行，以及新出现的 Accessed None、ScriptWarning、Error。
