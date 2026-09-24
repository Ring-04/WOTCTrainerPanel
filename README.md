# WOTC Trainer Panel / 修改器

仅面向 Steam Windows 版 **XCOM 2: War of the Chosen** 的游戏内单机修改器。

**当前状态：Phase 1 环境准备；SDK 阻塞。此仓库还不是可安装 Mod，没有编译后的脚本包。**

已建立本地 Git 仓库、保存完整需求、定义 Phase 1 验收条件，并提供只读环境检查和源码取证工具。尚未编写 UnrealScript 游戏调用；未生成或假定 ModBuddy 工程模板；未编译、未启动游戏验证、未修改游戏或存档。

## 下一步

提供本机 WOTC SDK 目录。若未安装，在 Steam 库的工具中安装 **XCOM 2 War of the Chosen Development Tools**（App ID 602410；[Steam 官方页面](https://help.steampowered.com/en/wizard/HelpWithGame/?appid=602410)）。游戏本体与 SDK 是不同安装项。安装后先核查源码、编译工具和工程模板是否齐全，再确定构建方式。

在本仓库运行：

```powershell
.\tools\Test-Environment.ps1 -SdkRoot '实际的 WOTC SDK 目录'
.\tools\Export-SourceEvidence.ps1 -SdkRoot '实际的 WOTC SDK 目录'
```

检测结果写入本仓库的 `evidence/`，不会写入 Steam、SDK、游戏配置或存档目录。环境检查退出码：`0` 代表检测到游戏和基础 SDK 文件，`2` 代表仍缺前置条件；`0` 不代表编译或游戏测试通过。

源码取证只记录文件路径、SHA-256 和候选声明位置，**不等于 API 语义已审核**。必须阅读实现、调用方和状态提交路径之后，才能在 `docs/API-AUDIT.md` 中标为已确认并编码。

## Phase 1 范围

- 战略层“修改器”入口和简体中文界面。
- 六类资源的非负数值设置及 +10/+50/+100/+500/+1000。
- +1 工程师、+1 科学家。
- 治疗所有士兵，遵守真实治疗项目和单位状态流程。
- 所有操作显示原值 → 新值并记录 `[WOTCTrainer]` 日志。

按独立模块提交 Git；Phase 1 编译、实机操作、存档读写和日志检查全部通过后，再进入 Phase 2。详见 [验收清单](docs/PHASE-1.md) 和 [原始需求](docs/REQUEST.zh-CN.txt)。后续阶段暂未实现。

## 已观察到的本机状态

- Steam WOTC 游戏：`C:\SteamLibrary\steamapps\common\XCOM 2\XCom2-WarOfTheChosen`。
- 在已检查的本机 Steam 库及常见开发目录中未发现 WOTC SDK。
- 检查时游戏未运行。既有 `Launch.log` 包含 `-allowconsole`；用户配置的语言值为 `INT`。这只是旧环境记录，不能代替本 Mod 的 CHS / 无控制台验收。

最新机器检查见 [环境报告](evidence/environment.json)。
