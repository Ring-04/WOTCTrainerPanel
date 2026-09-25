# WOTC Trainer Panel / 修改器

仅支持 Steam Windows 版 XCOM 2: War of the Chosen。

**当前交付：Phase 1–4 已编码并通过编译，尚未进行游戏内验收。实机测试由用户集中执行。Phase 5–6 尚未实现。**

## 已编码并通过编译

- 战略层“修改器”按钮：复仇者号基地 / 战略地图界面打开。
- 资源：补给、情报、外星合金、超铀水晶、超铀核心、XCOM 共享 AP。
- 自定义非负整数总数与 +10 / +50 / +100 / +500 / +1000；溢出和非法输入拒绝提交。
- +1 工程师、+1 科学家，使用原版人员创建、身份外观和 HQ roster 流程。
- 治疗所有符合条件的士兵，使用原版治疗完成 order，同步治疗项目及正常关联状态。
- 士兵生成、军营编辑器、职业与军衔、属性、晋升与恢复（已晋升士兵的强制转职与降级因 AP / 持久能力同步风险保持禁用）。
- 战术面板：12 个默认关闭的开关（全队/指定士兵无敌、无限行动、无限移动、射击后保留行动、无限弹药、无需装填、无冷却、无限充能、命中、暴击、一击必杀），以及回血、行动点、装填、技能冷却重置。
- 任务控制：真实目标记录与本地化 HUD 目标并排浏览、手动完成选中或全部未完成记录、胜利/失败结算、跳过 AI 回合、AI 卡死修复与恢复、重启任务。
- 修改确认框显示原值 → 新值；确认时再次核对原值，防止使用陈旧状态。
- INT 英文、CHS 简中及游戏实际使用的 CHN 简中本地化，UTF-16 LE BOM。
- 操作日志带有 `[WOTCTrainer]`；没有控制台命令、游戏类覆盖或 Highlander 依赖。

界面保留八个标签页，资源、人员、士兵、战术页可用，任务与危险功能通过战术面板内的入口打开。同种子重启与强制撤离明确禁用并标注原因，传送与复活同样保持禁用。

## 安装与测试

安装步骤见 [安装与实机测试](docs/INSTALL-AND-TEST.zh-CN.md)；该文档的安装流程仍然适用，但其中“可用页面”的功能清单停留在 Phase 1，集中实机验证前会一并更新。

已打包的安装件仍是最早的 **outputs/Phase1/WOTCTrainerPanel** / **WOTCTrainerPanel-Phase1.zip**。Phase 1–4 的最新编译产物在工作区隔离 SDK 的 `XComGame/Mods/WOTCTrainerPanel` 暂存目录中，尚未重新打包；这个源码仓库根目录自身没有 Script 包，不要把源码目录误当成安装目录。

编译器最终结果：**0 错误，8 个 SDK 原版 DLC 内容警告，修改器自身 0 警告**。这些警告涉及最小 SDK 缺少的原版资源；打包不包含 Core.u / Engine.u / XComGame.u 等重编的游戏包。完整记录见 [构建哈希](evidence/latest-build.json)。

## 开发约束与当前验证边界

所有运行时修改均走游戏的 GameState 提交或 HeadquartersOrder 提交。没有改动 Steam 安装文件、游戏配置、启动参数或存档。

用户后续允许“有把握的功能先开发全部 Phase，再统一验证”。这放宽了原先逐阶段实机验证的开发门槛，但不代表未审核的 API 或危险实验功能可以直接实现。当前 Phase 1–4 达到可编译交付状态，Phase 5–6 保留为待开发；没有宣称全项目完成，也没有宣称任何功能已通过实机验证。

正常治疗完成流程可能把士兵意志提升到 Ready 下限并恢复暂停的灵能训练，这是已核对的原版行为，界面会说明。它不是单独的“恢复全部意志 / 去除所有疲劳”功能。无合法治疗项目的异常单位不在本版修复范围内。

尚未证明：实际按钮位置、中文字体显示、不同分辨率布局、运行时 API 兼容、各操作效果、保存/读取、与其他 Mod 的兼容性。需按 [Phase 1](docs/PHASE-1.md)、[Phase 2](docs/PHASE-2.md)、[Phase 3](docs/PHASE-3.md)、[Phase 4](docs/PHASE-4.md) 的清单收集游戏证据。

## 构建

原版 SDK 路径：`D:\steam\steamapps\common\XCOM 2 War of the Chosen SDK`。
本轮使用工作区 `work/sdk-clean` 中的隔离副本，从原版源码构建依赖包；没有修改 Steam SDK。

在仓库根目录执行：

```powershell
.\tools\Build-Localization.ps1
.\tools\Build.ps1 -SdkRuntime '本任务 work 目录下的隔离 SDK 副本'
```

SDK 副本首次准备时不复制 SDK 自带的 `.u` 文件，以避免首次构建删除预编译依赖包时失败。保留原版源码和运行库；编译器会在副本中生成依赖。构建脚本拒绝把 Steam SDK 本体作为写入目录。

来源与语义证据见 [API 审核](docs/API-AUDIT.md)、[Phase 1 源码哈希](evidence/phase1-source-hashes.json) 与 [Phase 4 SDK 源码哈希](evidence/phase4-source-hashes.json)。原始需求完整保留在 [REQUEST.zh-CN.txt](docs/REQUEST.zh-CN.txt)。Git 按基础工程、资源、人员治疗、UI、战术、任务控制分模块提交。
