# WOTC Trainer Panel 开发约束

- 以 `docs/REQUEST.zh-CN.txt` 的完整用户需求为准。当前只允许推进 Phase 1。
- 每个游戏 API 在调用前必须阅读实际 WOTC SDK/Game Source 的声明、实现及调用方，记录源码版本/哈希、位置和状态提交方式到 `docs/API-AUDIT.md`。不能凭记忆、网络片段或同名方法猜签名。
- 区分原版 WOTC API 和 Community Highlander 扩展。没有确认依赖前，不得使用后者新增 API。
- 仅修改本 Mod 文件和配置；运行时变更通过合法 GameState 提交。禁止修改 exe、Steam 文件、注入 DLL、内存补丁、AOB、存档二进制。
- 功能默认关闭。UI 使用 INT/CHS 本地化，显示原值 → 新值。危险操作二次确认。不得把未来阶段的空壳控件标为可用。
- 每个独立模块完成后提交 Git。基础工程提交不等于阶段验收通过。
- 未取得编译、实机操作、Launch.log 和保存/读取证据前，不得宣布 Phase 1 完成，不得进入 Phase 2。
- 如果工具缺失，记录明确阻塞，不得生成假编译日志、假截图、假运行结果或占位二进制。

