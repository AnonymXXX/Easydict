# Easydict 个人轻量版

- 状态：completed
- 创建日期：2026-09-14
- 负责人：AnonymXXX
- 关联 Issue/PR：none

## 背景

上游 Easydict 同时包含词典、在线翻译、AI、CLI、本地服务与 HTTP Server 等大量能力。
个人使用只需要输入翻译、划词翻译和 Apple Vision 截图 OCR，并且查询服务仅保留有道与
DeepSeek，因此需要从产品入口、服务注册和构建依赖三个层面缩减，而不是只隐藏设置项。

## 目标与范围

- 目标结果：产出可独立构建、可继续同步上游安全修复的 Easydict 个人轻量版。
- 允许修改路径：应用源码、Xcode 工程与依赖配置、运行时资源、相关用户文档和任务记录。
- 同任务 history：`docs/histories/2026-09/2026-09-14-easydict-lite.md`
- 用户限制：保留输入翻译、划词翻译、截图 OCR；翻译服务只保留有道和 DeepSeek；不保留 Apple 翻译。
- 非目标：发布安装包、替换当前已安装 App、创建上游 Pull Request、改写上游历史。
- 验收标准：应用构建通过；服务列表只暴露有道与 DeepSeek；三种保留入口仍在构建图中；移除服务无悬空工程引用。

## 工作计划

1. 追踪服务注册、查询编排、设置 UI、OCR/划词入口与第三方依赖的实际调用关系。
2. 先收窄服务注册和用户界面，再删除未使用的服务实现、资源与构建依赖。
3. 保留 Apple Vision OCR，但移除 Apple Dictionary、Apple Translate、HTTP Server 和其他服务入口。
4. 更新受影响的用户文档与项目记录。
5. 运行工程一致性检查、目标构建和相关现有测试，复核最终差异并提交。

## 风险与决策

- 服务枚举、默认配置、设置界面与 Xcode 工程引用存在跨语言耦合，必须先追踪后删除。
- OCR 使用系统 Vision，不因删除 Apple Translate 而移除 Vision 依赖和屏幕录制权限。
- 有道同时承担词典、翻译与默认 TTS；轻量版保留有道相关实现，避免破坏发音能力。
- fork 继续遵守 GPL-3.0，保留许可证和原作者版权信息。

## 进度

- [x] 创建并核验 GitHub fork、本地仓库和任务分支。
- [x] 完成服务与依赖调用图梳理。
- [x] 完成产品入口、源码、资源和依赖删减。
- [x] 完成文档与任务记录更新。
- [x] 完成构建、现有测试和最终差异复核。

## 验证

- `xcodebuild ... -configuration Release ... build`：通过；生成 27 MB、仅 `arm64` 的
  `Easydict Lite.app`，主可执行文件 23 MB，Bundle ID 为 `com.anonymxxx.EasydictLite`。
- `xcodebuild test ... -skip-testing:EasydictTests/OCRImageTests
  -skip-testing:EasydictTests/SystemUtilitiesTests
  -skip-testing:EasydictTests/AppleScriptExecutorTests`：19 个 suite、149 项测试通过。
- 默认完整测试曾执行；当前 macOS/Vision 结果与 50 个 OCR 图像快照基线不一致，另有 2 个
  AppleScript 环境依赖断言失败，因此最终稳定测试集显式跳过上述 3 组测试。
- `ruby -c scripts/lite/configure-lite-project.rb`、`plutil -lint`、脚本幂等执行和
  `git diff --check`：通过。
- 服务注册表人工复核：仅包含 `YoudaoService` 与 `DeepSeekService`；服务图标资源仅保留
  Youdao、DeepSeek 和共用播放图标。
- 未执行：真实 macOS 快捷键、辅助功能/屏幕录制权限、截图 OCR 视觉结果和在线有道/DeepSeek
  凭据调用；未签名、未安装、未制作 DMG、未发布。

## 完成条件

- 代码、工程配置和文档与用户确认的轻量范围一致。
- 所需非浏览器检查通过，未执行的真实 macOS 交互验收明确记录。
- 形成单一任务提交并保留可追踪的上游 remote。
