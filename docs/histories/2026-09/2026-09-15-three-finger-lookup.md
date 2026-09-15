## 2026-09-15 | 任务：增加三指点按自动取词翻译

**Links:** `docs/exec-plans/completed/2026-09/2026-09-15-three-finger-lookup.md`

### 用户请求

让 Easydict Lite 在鼠标停于未选中单词时，通过触摸板三指轻点自动取词并立即翻译，同时关闭 macOS 内置查词弹窗。

### 变更

- 动态加载系统 `MultitouchSupport` 接触帧，识别三触点、短时、低位移的轻点手势，并保留 AppKit 回退。
- 手势结束后在原鼠标位置合成双击，让源应用准确选中单词，再复用现有选区读取与查询窗口。
- 查询窗口填入单词后立即发起翻译，无需再次按回车。
- 更新 Xcode 工程文件并记录任务计划。

### 设计意图

macOS Quick Look 手势不进入普通 AppKit 事件队列，因此触摸板接触帧适配器采用动态加载与可失败回退，避免框架不可用时影响应用启动。取词使用源应用自身的双击命中规则，解决 Accessibility 点位接口在复杂文本视图中返回附近单词的问题。系统内置查词属于本机设置，通过触摸板后端 setter 与通知关闭，不把机器偏好写入应用代码。

### 验证

- `git diff --check`：通过。
- `xcodebuild build -workspace Easydict.xcworkspace -scheme Easydict -configuration Release -derivedDataPath /tmp/easydict-three-finger-derived.chQZgv CODE_SIGNING_ALLOWED=NO`：通过。
- 本机安装：稳定本地签名保留，`/Applications/Easydict Lite.app` 启动且原始触摸板监听成功。
- 真实触摸板：点击未选中的 `Lite` 后取词准确并自动翻译，系统词典未出现，用户确认完全正常。
- 全量测试：首版运行时仅无关的 `SystemUtilitiesTests` 桌面音量 AppleScript 失败，错误为 `Failed to get alert volume`；按项目规则未擅自新增测试。

### 受影响文件

- `Easydict/Swift/Utility/EventMonitor/Core/EventMonitor.swift`
- `Easydict/Swift/Utility/EventMonitor/Engine/RawTrackpadMonitor.swift`
- `Easydict/Swift/Utility/EventMonitor/Workflow/ThreeFingerTapRecognizer.swift`
- `Easydict.xcodeproj/project.pbxproj`
- `docs/exec-plans/completed/2026-09/2026-09-15-three-finger-lookup.md`
- `docs/histories/2026-09/2026-09-15-three-finger-lookup.md`

### 后续事项

- `MultitouchSupport` 是私有系统框架，未来 macOS 版本变更后需要重新验证；当前实现会在不可用时安全回退。
