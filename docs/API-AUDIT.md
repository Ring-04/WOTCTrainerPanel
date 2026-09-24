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
