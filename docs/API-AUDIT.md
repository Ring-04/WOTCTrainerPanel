# Phase 1 API 审核

**2026-09-24 更新：本机原版 WOTC SDK 已就绪，以下 Phase 1 接口已阅读声明、实现与调用方，可以编码；尚未实机验证。**

源码根目录：`D:\steam\steamapps\common\XCOM 2 War of the Chosen SDK\Development\SrcOrig`。SDK 编译器 FxsChangelist 372475，2018-08-29；零售游戏先前日志 FxsChangelist 469133，两者并非同一构建，运行兼容性仍需用户验证。文件哈希见 `evidence/phase1-source-hashes.json`。

## 已核对的 Phase 1 接口

以下路径均相对于 `XComGame/Classes`，除非另有标注。

| 接口 | 声明 / 实现与调用证据 | 决策 |
| --- | --- | --- |
| 策略环境宏 | `Core/Globals.uci:179,186,226,228`；`UIStrategyScreenListener.uc:14` | 仅 `HQGAME` / `HQPRES` / `STRATEGYRULES` 存在时操作 |
| `GetSingleGameStateObjectForClass(class, optional bool AllowNULL)` | `XComGameStateHistory.uc:384`；原版奖励/治疗实现 | 只读取得最新 HQ，AllowNULL=true，禁止直接写 history 对象 |
| `CreateChangeState(string, bool, float)` | `XComGameStateContext_ChangeContainer.uc:48` | 创建有描述的 pending state |
| `ModifyStateObject(class,int)` / cleanup / submit | `XComGameState.uc:144`；`XComGameStateHistory.uc:298`；`X2GameRuleset.uc:607-662`；`XComHeadquartersCheatManager.uc:3667-3745` | 在克隆对象中修改；未提交时清理；SubmitGameState 的拒绝路径自身清理 pending state，不能再次清理 |
| `GetItemByName(name)` / `GetResourceAmount(name)` / `AddResource(state,name,int)` | `XComGameState_HeadquartersXCom.uc:4270,4892,4949-4999` | 先确认库存项存在；AddResource 不会创建缺失条目。共享 AP 模板为 AbilityPoint；其余五个 ID 由 getter 确认。计算差值前检查非负和 int 溢出 |
| `CreatePersonnelUnit(state,name,name,bool)` | `X2StrategyElement_DefaultRewards.uc:565-626,780-814` | 复用原版人员奖励创建与技能等级逻辑；仅 Engineer / Scientist |
| 人员唯一对象、合法身份与外观 | `CharacterPoolManager.uc:314-466` | 每次由 CharacterTemplate.CreateInstanceFromTemplate 创建新对象，池子仅提供身份/外观；不复制对象 |
| `AddToCrew` / `HandlePowerOrStaffingChange` | `XComGameState_HeadquartersXCom.uc:693,2730,8018`；`X2StrategyElement_DefaultRewards.uc:634-670` | 同一 change state 中登记 roster 并更新岗位效率；提交后重新读取人数 |
| 工程师/科学家人数 | `XComGameState_HeadquartersXCom.uc:2378,2544` | 游戏 getter 会排除首席人员，不手算 UI 数字 |
| 合法治疗目标 | `XComGameState_Unit.uc:190,5031,6370-6372,7655-7662`；HQ Crew / Projects；`XComGameState_HeadquartersProjectHealSoldier.uc:17` | 限当前 Crew 中存活、未被俘、处于 Healing 状态且有合法治疗项目的士兵 |
| 正常治疗完成 | `XComGameStateContext_HeadquartersOrder.uc:135,800-885,1198`；`XComGameState_HeadquartersProjectHealSoldier.uc:163-196` | 使用 UnitHealingCompleted order，走 SubmitGameStateContext；清理项目、恢复 HP、更新状态及原版意志恢复/灵能训练流程，绝不单改 HP。原版可能将意志提升至 Ready 下限，UI 明示这一原版行为 |
| 监听器 | `UIScreenListener.uc:16-31`；原版 `UIStrategyScreenListener` | 不覆盖游戏类，用 OnInit 与明确的 ScreenClass |
| UI 组件 | `UIPanel.uc:96,343,361,427,432,440,536,546,850`；`UIButton.uc:53,72,110,132`；`UIText.uc:25,37`；`UIBGBox.uc:17` | 使用内置 Flash 组件；命名子控件防重复；布局以游戏虚拟 UI 坐标定位 |
| 屏幕栈 | `UIScreen.uc:59,80,277-301`；`UIScreenStack.uc:317-397,456,652,684` | Push 默认使用 2D movie；模态页面启用鼠标拦截；关闭使用 Pop |
| 数值输入 | `UIInputDialogue.uc:27-66,225-262`；`XComPresentationLayerBase.uc:1609` | 仅绑定 fnCallbackAccepted，取消不提交；不能用同时在取消时触发的 fnCallback |
| 确认框 | `UIDialogueBox.uc:17-70`；`XComPresentationLayerBase.uc:1443` | 通过 `TDialogueBoxData` 显示原值与新值，在回调中重新核对状态后提交 |
| 项目/构建 | SDK `EmptyMod.zip` 的 `ProjectTemplate.x2proj`；`DefaultMod.zip` 的 Config 三个 ini；`XCOM2.targets` 和 `XCOM2.Tasks.dll` 中构建参数/元数据 | 在工作区 SDK 副本调用官方 make commandlet；不使用 ModBuddy 默认部署以免写入 Steam 目录 |
| 本地化 | 零售游戏 Localization 目录与 SDK DefaultEngine.ini 的 UEFonts_CHN | INT 英文，CHS 按需求提供，CHN 提供相同简体中文供实际游戏加载 |

未采用任何 Highlander 新增接口。以下旧待核对表保留为最初基线；以本节为最新 Phase 1 审核记录。

已找到 [Community Highlander 源码仓库](https://github.com/X2CommunityCore/X2WOTCCommunityHighlander) 作为辅助检索入口。该项目修改游戏脚本并增加扩展 API，不能把它的 master 分支直接等同于用户安装版本的原版 WOTC SDK。本项目当前不声明 Highlander 依赖。

## 待核对模块

| 模块 | 必须确认的内容 | 状态 |
| --- | --- | --- |
| UI 生命周期 | 战略层根屏幕、监听器注册/销毁、按钮、屏幕栈、模态输入、本地化 | 未审核 |
| 读取上下文 | 战略层/单机判断、当前 HQ、单位列表、切屏期间状态可用性 | 未审核 |
| GameState | 创建 change state、修改对象、提交规则、失败/空事务释放 | 未审核 |
| 资源 | 真实模板名、HQ 库存读取/修改、int 边界、AP 的独立存储方式 | 未审核 |
| 人员 | Engineer/Scientist 模板、身份/外观生成、唯一 ObjectID、HQ 登记及人数更新 | 未审核 |
| 治疗 | 存活/己方/可治疗筛选、HP 与伤势、治疗项目、状态转换/事件通知 | 未审核 |
| 日志 | 日志宏可用性、发布构建日志行为、中文和原值/新值格式 | 未审核 |
| 构建 | SDK 自带工程模板、构建命令及产物、本地化编码和打包位置 | 未审核 |

## 每项 API 的记录格式

- 调用方模块和用途：
- SDK 来源/版本、原版或 Highlander：
- 源文件相对路径与 SHA-256：
- 声明行号、完整签名、可见性、默认参数：
- 实现与游戏自身调用方的路径/行号：
- 前置状态和禁止调用场景：
- 需要纳入 change state 的对象、创建/修改/提交/失败处理方式：
- 提交后的 UI 更新、事件和保存/读取影响：
- 审核结论和验证证据：

`Export-SourceEvidence.ps1` 只帮助定位候选声明并固定文件哈希；人工/代理阅读源码后才能填写审核结论。

## Phase 2 — 2026-09-25 编码前审核

以下均为本机原版 SrcOrig，未使用 Highlander。哈希见 phase2-source-hashes.json。

| 模块 | 已阅读的声明、实现和调用方 | 决策 |
| --- | --- | --- |
| 全新士兵 | DefaultRewards.CreatePersonnelUnit 565–626；CharacterPoolManager.CreateCharacter 314–466；Unit.OnCreation 3002–3088；HQ.AddToCrew 693、OnCrewMemberAdded 8018 | 使用 bIsRookie=true 获得合法身份、外观及库存，每次工厂创建唯一 Unit；绝不复制已有对象 |
| 职业/逐级晋升 | Unit.RankUpSoldier 11549–11720、ApplySquaddieLoadout 10068、SetXPForRank 11483；HQCheat.LevelUpBarracks 3568–3628；SoldierClassTemplateManager 17–30、Template.GetMaxConfiguredRank 67；ExperienceConfig 91–149 | 从现有军衔逐级调用；同步 XP/StartingRank；高阶技能交给原版升级界面选择；检查模板支持的最大军衔 |
| 派系士兵 | DefaultCharacters.Reaper/Skirmisher/Templar 4138–4214；Unit.GetResistanceFaction 3462；XpackRewards.Generate/GiveFactionSoldierReward 591–655；Faction.MeetXCom 141–180、GetChampionCharacterName 298 | 专用角色模板最低列兵；本版仅允许已接触派系，避免生成顺带改写战役接触和秘密行动 |
| 士兵列表 | HQ.Crew；Unit.GetSoldierRank 701、GetSoldierClassTemplateName 706、GetFirst/Last/NickName 4536、GetCountryTemplate 5291、GetXPValue 11493；CountryTemplate.DisplayName；SoldierClassTemplate.DisplayName | 列出所有 HQ 兵营士兵；修改时再次检查 roster、存活、未被俘、未执行秘密行动，限 Active/Healing |
| 属性 | Unit.GetBase/Max/CurrentStat 和 SetBaseMax/CurrentStat 6369–6374；HQCheat.SetSoldierStat 1697；CharacterTemplate.GetCharacterBaseStat；Unit.UpdateMentalState 12842 | 基础值 0–1000（HP/Mobility/Will 最低1）；当前值按差额调整；受伤时禁改 HP，意志恢复中禁改 Will；默认值读取角色模板并明确不含晋升加成 |
| 意志与疲劳 | RecoverWill.SetProjectFocus 16、OnProjectCompleted 180–224；Unit.NeedsWillRecovery 5249 | 有项目调用原版完成方法，清除 HQ 项目/对象、恢复意志/精神状态、处理强化恢复退款；无项目只允许已经满意志的无操作，不伪造恢复 |
| 负面特质 | Unit.RecoverFromAllTraits 984–1002、GetNumTraits 714、UnitTraitsChanged 原版事件；EventListenerTemplateManager.FindEventListenerTemplate | 调用前检查每个负面特质模板存在，再复制单位、调用恢复并发送相同事件 |
| XP/AP | Unit.AddXp 11456–11481、AbilityPoints 111、AbilityPointsChange 11688 | AP 限 0–100000，XP 限原版当前晋升阈值封顶；不允许强写受保护 XP |
| 降级/转职 | Unit.ResetSoldierRank 3797、ResetSoldierAbilities 3814；HQCheat.MakeSoldierAClass 2605–2643 | 原版调试方法没有完整处理 WOTC 已花 AP 与持久能力联动；降级、已晋升士兵转职保持禁用；新兵可选择普通职业正常晋升 |
| UI | Phase 1 已审阅 UI primitives；Core.Object Repl/InStr/Caps 1292–1300 | 列表分页，固定大小按钮；玩家名字转义 HTML；共用确认与输入回调 |

全部显式修改使用 ChangeContainer + ModifyStateObject + SubmitGameState，提交前校验预览值，提交后重读。原版项目完成函数自行提交，不外套重复提交。

## Phase 3 — 战术实现前审核（2026-09-25）

- `XComGameState_BattleData` 87–103/206/870：MissionID、Battle ObjectID、bMultiplayer；设置仅匹配当前单机战斗。`X2TacticalGameRuleset.GetCachedUnitActionPlayerRef` 4801/5462；`X2GameRuleset.IsDoingLatentSubmission` 119；手工操作仅在己方 UnitActions 阶段。
- `XComTacticalController.GetActiveUnitStateRef` 832；`UITacticalHUD` 原版用例；入口使用现有 UIScreenListener，不调用 CheatManager。
- `X2EventListenerTemplate.AddEvent/RegisterForEvents` 25–59、DefaultTraits.CreateAcquireTraitsTemplate 108、DefaultTraits 对 InterruptionStatus 的守卫：原版自动注册的 ELD_OnStateSubmitted 监听器，忽略中断帧，仅处理 XCOM 活人士兵；非能力事件不会递归触发 AbilityActivated。
- `XComGameStateContext_Ability` 191/370/414：AbilityActivated 的 EventData=AbilityState，EventSource=UnitState；`XComGameState_Player` 165：PlayerTurnBegun 的 EventSource=Player。
- `X2Ability.PurePassive` 1575–1607；`XComGameState_Ability` 2075–2088 原版 EverVigilant 手工施加效果；`EffectAppliedData` 336；`X2Effect.ApplyEffect` 67；`X2Effect_Persistent.HandleApplyEffect` 443–547；`XComGameState_Effect.PostCreateInit` 245–330：创建自身模板中的无行为默认效果，按 SourceTemplateName/TargetEffects/index 定位，修改副本后正常 SubmitGameState；无需控制台或全局作弊开关。
- `X2Effect_Persistent` 651–691：命中、伤害、免疫、死亡前检查、环境伤害扩展；`X2Effect_DamageImmunity.ProvidesDamageImmunity`；`X2Effect_Sustain.PreDeathCheck` 14–56；`TracerRounds.GetToHitModifiers`；`Executioner.GetAttackingDamageModifier`。效果每次校验 XCOM 士兵及开关；一击必杀限有技能来源且源单位为 XCOM、目标是敌对 Unit，环境 Damageable 不进入。
- `Unit` ActionPoints 141、GiveStandardActionPoints 6380、GetTeam 9603、IsEnemyUnit 9605、IsAbleToAct 7700、GetAllInventoryItems 7490；`XComTacticalCheatManager.GiveActionPoints` 695–720 和 SetAmmo 3445–3477：仅复用经过审核的合法状态操作，不调用 cheat。
- `Item.GetClipSize` 854–890、Ammo 字段；`Ability.iCooldown/iCharges` 12/13、`X2AbilityCharges.GetInitialCharges`；填弹上限来自物品及升级件，技能充能上限来自模板，冷却逐一修改所属技能副本。
- 手工治疗只增加存活单位当前 HP，不清除战略 LowestHP、异常状态或假复活。战术回血不等于战后无伤。
- 命中/暴击保证仅覆盖原版 StandardAim 系列攻击；独立命中免疫、处决脚本和其他 Mod 的覆盖仍须实机测试。未审核完整合法流程的 FOW、AI、复活和传送暂不启用。

## Phase 4 — 任务控制编码前审核

- `XGGameData.MissionObjectiveDefinition` 302–323 只有 ObjectiveName 与三种用途/完成标志，没有本地化文本或激活标志。`ObjectiveDisplayInfo`（StrategyStructures 896）是另一组显示数据，不包含可靠的战术 ObjectiveName。故展示真实内部目标和中文 HUD 文案的独立列表，禁止按数组索引猜配对。
- `BattleData.CompleteObjective` 274–289 更新任务数据并触发 OnMissionObjectiveComplete；`SeqAct_CompleteMissionObjective.Activated` 完整正常提交用例。Complete All 指当前任务已配置但未完成的目标，不捏造 skipped 状态。
- `X2TacticalGameRuleset.EndBattle` 225–293 创建正常 eGameRule_TacticalGameEnd，正常 SubmitGameState 和 EndBattle 事件；`Context_TacticalGameRule.BuildTacticalGameEndGameState` 278–319；`BattleData.SetVictoriousPlayer` 833–867 仍按 MissionSource.WasMissionSuccessfulFn 决定战役成功，不能只强写胜利 UI。本版胜利结束先要求任务自身成功判定已满足。
- `HasTacticalGameEnded` 315；BattleData.VictoriousPlayer 162；`XGBattle_SP.GetHumanPlayer/GetAIPlayer` 327–367：结束前排除已结束/多人/教程，检查玩家对象。
- `UIPauseMenu.RestartMissionDialgoueCallback` 554–560；`XGNarrative.RestoreNarrativeCounters` 86；`XComPlayerController.RestartLevel` 1715：使用原版重开入口，不调用 CheatManager；同种子接口只见引擎作弊随机数改写，保持禁用。
- `XGPlayer.EndTurn` 421–446；`TacticalGameRule.ContextBuildGameState` 83–99：跳过当前敌方回合使用相同 SkipTurn context / PlayerRef / SetSendGameState / SubmitGameStateContext；已有潜在提交时拒绝，不能宣称修复所有 AI hang。
- `XComGameState_ObjectivesList.ObjectiveDisplayInfos` 19；`UIObjectiveList.RefreshObjectivesDisplay` 135；`UITacticalHUD.m_kObjectivesControl` 71；`UIScreenStack.GetScreen` 608：刷新只同步已有 HUD 数据，不把刷新当完成。
- `AIReinforcementSpawner.Countdown/SpawnedUnitIDs`；`Unit.TileLocation` 118；`XComWorldData.IsTileOutOfRange` 773：只读诊断己方、异形、Lost、待增援与越界 Tile；不将飞行单位的非地板 Tile 误报为损坏。

## Phase 4 — 编码后补充核对（2026-09-25，编译通过后）

- `XGAIPlayer.uc:20` `var bool m_bSkipAI`（注释即 "For debugging/testing"），消费于 `:269` 调用 `EndTurn(ePlayerEndTurnType_AI)` 与 `:864` 的分组守卫。写入者只有两处原版代码：`SeqAct_SkipAI.uc:7`（Kismet 节点）和 `XComTacticalCheatManager.uc:2480-2483`（`exec function SkipAI`，同时设置主 AI 与 Lost 玩家）。它是可视化器上的瞬态调试开关，不属于任何 GameState、不存档。AI 卡死修复直接写这一开关，不调用 cheat manager、不走控制台。
- `XComTacticalCheatManager.uc:3531-3536` `RestartLevelWithSameSeed` 先调 `XComCheatManager.uc:2769` 的 `native exec function SetSeedOverride`，再 `Engine.SetRandomSeeds(\`BATTLE.iLevelSeed)` 后 `RestartLevel()`。脚本侧可读的部分是 `SetRandomSeeds`，但 `SetSeedOverride` 是 native，没有可审核实现，缺它无法证明重启确实复用同一种子，因此同种子重启保持禁用，而不是近似实现。
- `X2StrategyGameRulesetDataStructures.uc:896` `struct native ObjectiveDisplayInfo` 提供 HUD 行的 `DisplayLabel/ShowCompleted/ShowFailed` 等；本版只读访问 `DisplayLabel/ShowCompleted/ShowFailed/HideInTactical/GPObjective`。它与 `MissionObjectiveDefinition` 之间没有索引或 ObjectiveName 的可靠对应，因此两个列表并排展示，不做第 N 项配对。
- 跨类引用类体内声明的 struct 需要在消费方加 `dependson`：`UIWOTCTrainerMission.uc(49) Unrecognized type 'MissionObjectiveEntry'` 是在 `UIWOTCTrainerMission` 声明中加入 `dependson(WOTCTrainerMission)` 后才消解的。原版同型先例是 `UIDialogueBox.uc:11` 的 `dependson(UICallbackData)`。
- `XComGameState_BattleData.SetVictoriousPlayer` 833–867 在任务点无法解析（`MissionState == none`，含 `GetMissionSource` 790 找不到模板而返回 none）或 `WasMissionSuccessfulFn == none` 时，会落到 `bLocalPlayerWon = true`。镜像实现必须保持同样的宽松处理，否则会挡住游戏本来会记为胜利的结算。
- `X2TacticalGameRuleset.uc:1984-2003`：只有 `AllTacticalObjectivesCompleted()` 成立才回收阵亡遗体并清扫战利品。这正是 Destroy Relay 被 Lost 摧毁后 Sweep 未结算会让玩家丢失遗体/战利品的真实原因，也是面板必须显示未完成战术目标并允许手动完成对应记录的动机。

## Phase 5 — 战略物品与行动编码前审核（2026-09-25）

- **物品枚举（禁止硬编码表）**：`X2DataTemplateManager.uc:44` `native iterator function IterateTemplates(out X2DataTemplate, delegate<TemplateIteratorCompareDelegate> = none)`，配合 `X2ItemTemplateManager.uc:30` `native static GetItemTemplateManager()`。原版同类用例：`UIDebugItems.uc:332`（游戏自带物品浏览器）、`X2BenchmarkAutoTestMgr.uc:536`、`UITacticalQuickLaunch_UnitSlot.uc:468`。列表全部来自该迭代器，只按模板自身字段与类筛选，不维护人工物品表。
- **发放物品**：`X2ItemTemplate.uc:111` `CreateInstanceFromTemplate(NewGameState)` 建实例；`XComGameState_Item.uc:1784` `OnItemBuilt` 调用模板 `OnBuiltFn`；`XComGameState_HeadquartersXCom.uc:4131` `PutItemInInventory` 负责堆叠未改动物品、把 `bInfiniteItem` 从状态中移除、并对 `HideInInventory` 物品改走 `OnAcquiredFn`；`:4208` `AddItemToHQInventory` 记录 `EverAcquiredInventoryTypes/Counts` 并写入 `Inventory`。原版用例：`X2StrategyElement_DefaultRewards.uc:1444-1472`（任务奖励入库）、`UIInventory_BuildItems.uc:393`（建造完成入库）。`XComGameState_HeadquartersXCom.uc:4807` 的静态 `GiveItem` 会先调用 `UpdateItemTemplateToHighestAvailableUpgrade` 静默换成已解锁的升级版，训练器不使用它，以免发放的模板与玩家选择不一致。
- **物品筛选字段**：`X2ItemTemplate.uc:24/28/31/32/62` `MaxQuantity/HideInInventory/bInfiniteItem/bAlwaysUnique/Tier`；`X2EquipmentTemplate.InventorySlot` 区分武器、护甲与其它装备。默认排除 `HideInInventory`（多为任务/剧情物品，获取即触发 `OnAcquiredFn`）与 `bInfiniteItem`（入库是空操作），并在界面说明。
- **Avatar 计划（Doom）**：`XComGameState_HeadquartersAlien.uc:42` `Doom` 为永久值；`:491` `GetCurrentDoom(bIgnorePending)` = `Doom` + 所有 `Available` 任务点的 `Doom` − `GetPendingDoom()`（`:2203`）；`:517` `GetMaxDoom` → `:2307` `GetMaxDoomAtDifficulty`（受 SecondWave `ExtendedAvatarProject` 标量影响）；`:523` `AtMaxDoom`；`:529` `ModifyDoom(Amount)` 把 `Doom` 夹在 `[0, MaxDoom]`。原版写入范例：`XComHeadquartersCheatManager.uc:3289-3291`（取单例、`ModifyStateObject`、`ModifyDoom`、提交）。因此界面必须同时显示总进度、永久值、设施值与上限，并说明设施 Doom 会让绝对值无法精确降低。
- **Proving Ground**：项目登记在 `XComGameState_HeadquartersXCom.uc:46` `Projects`，Proving Ground 项目类为 `XComGameState_HeadquartersProjectProvingGround`（继承 `XComGameState_HeadquartersProjectResearch`，`bProvingGroundProject`）；完成驱动在 `XComGameState_HeadquartersXCom.uc:8850-8866` `UpdateGameBoard`（`CompletionDateTime` 已过 → `OnProjectCompleted()`）。合法立即完成 = 提交 `XComGameStateContext_HeadquartersOrder` 的 `eHeadquartersOrderType_ResearchCompleted`（枚举 `:21`，处理函数 `:337` `CompleteResearch`，分派 `:104`）：它会从 `Projects` 移除并清除项目状态、对 Proving Ground 项目同时从设施 `BuildQueue` 移除、标记科技完成、触发模板 `ResearchCompletedFn`（即物品奖励，见 `X2StrategyElement_DefaultTechs.uc:1889-1890`）、记录抵抗组织活动。这正是 `XComGameState_HeadquartersProjectResearch.uc:135` `OnProjectCompleted` 内部所做的事。
- **Covert Action**：`XComGameState_CovertAction.uc:1325-1370` `Update` 在 `bStarted && EndDateTime < 当前时间` 时执行 `ApplyRisks` 与 `CompleteCovertAction` 并置 `bCompleted`。训练器只把 `EndDateTime` 提前到当前时间，由原版 `Update` 在下次时间推进时完成结算，绝不直接写 `bCompleted`，因此风险与奖励仍走原版流程。势力名读 `XComGameState_ResistanceFaction.uc:17/242`。
- 文本输入沿用工程既有方式：`UIInputDialogue.uc:26` `TInputDialogData` + `Movie.Pres.UIInputDialog`（资源页已在用），物品搜索不新增输入控件。
